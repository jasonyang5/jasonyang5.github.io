library(dplyr)
library(purrr)
library(ggplot2)
library(rootSolve)
library(png)

setwd("C:/Users/jason/Documents/jasonyang5.github.io/content/post/RiemannMapping/")

# Goals for project:
# 1. implement old laser cutting functionality
# 2. implement inverse function (better?)
# 3. addon: general case for schwartz christoffel mapping
# 3. addon: or add some stuff about mobius transforms/linear fractional mappings

# Utility -----------------------------------------------------------------
# Integrates f on the straight path from the origin to z
# f: C -> C
# z: Complex Number
# output: 
straightpath_integral <- function(f, z, bounderr = 1e-5)
{
  # complex integrand 
  f2 <- function(t)
  {
    return(f(z*t)*z)
  }
  # real and imaginary integrands
  integrand_re <- function(x)
  {
    return(Re(f2(x)))
  }
  integrand_im <- function(x)
  {
    return(Im(f2(x)))
  }
  # TODO: could make this more efficient by doing 
  # both integrals at the same time?
  realpart = integrate(integrand_re, bounderr, 1-bounderr)
  impart = integrate(integrand_im, bounderr, 1-bounderr)
  return(complex(real = realpart$value, imaginary = impart$value))
}

# Reg Poly to Reg Poly ----------------------------------------------------
# might be worth implementing these map functions in C++
# b/c they get called a bunch (?)
# Maps circle onto polygon
oldmap <- function(z, k, bounderr = 1e-8)
{
  integrand <- function(w)
  {
    return(1/((1-w^k)^(2/k)))
  }
  return(straightpath_integral(integrand, z, bounderr))
}

# Maps polygon onto circle
# find zeta such that oldmap(z) = zeta
# newton raphson will work b/c the function is holomorphic and smooth
oldmap_inv <- function(zeta, k, bounderr = 1e-8)
{
  rootfn <- function(x)
  {
    return(oldmap(complex(real = x[1], imaginary = x[2]), k, bounderr) - zeta)
  }
  out = multiroot(rootfn, start = c(Re(zeta), Im(zeta)))
  return(out)
}


# Processing --------------------------------------------------------------
# Runs the code on pngs
pic = readPNG("twicelogo.png")



# Tests -------------------------------------------------------------------
# generate circle pts
thetalen = 100
thetas = seq(1e-3, 2*pi, length.out = thetalen)
datas = tibble(thetas = rep(thetas, 4),
               rs = c(rep(1, thetalen),
                      rep(0.5, thetalen),
                      rep(0.25, thetalen),
                      rep(0.75, thetalen))) %>%
  mutate(xs = rs*cos(thetas),
         ys = rs*sin(thetas))

complexs = complex(real = datas$xs, imaginary = datas$ys) %>%
  map({function(z) oldmap(z, 1)})

datas = datas %>%
  mutate(x_out = map_dbl(complexs, Re),
         y_out = map_dbl(complexs, Im))


ggplot(datas, aes(x = x_out, y = y_out)) +
  geom_point(aes(col = rs)) +
  scale_color_viridis_c()




# Plotting Infrastructure -------------------------------------------------
# Basic infrastructures for visualizing the transforms
# Make grids and make circles

# Makes a rectangular gruid of points within the boundaries
make_grid <- function(xmin, xmax, ymin, ymax, nx = 100, ny = 100)
{
  xs = seq(xmin, xmax, length.out = nx)
  ys = seq(xmin, xmax, length.out = ny)
  cross_df(list(reals = xs, imags = ys)) %>%
    mutate(z = complex(real = reals, imaginary = imags)) %>%
    select(z)
}

# Makes a bunch of circles up to radius rmax
make_circles <- function(rmin, rmax, ncirc, npt)
{
  rs = seq(rmin, rmax, length.out = ncirc)
  thetas = seq(0, 2*pi, length.out = npt)
  cross_df(list(args = thetas, mods = rs)) %>%
    mutate(z = complex(modulus = mods, argument = args)) %>%
    select(z)
}



# Mobius Transforms -------------------------------------------------------
# mobius transforms are of the form az+b / (cz + d)
# work like matrices
# blah blahblah

# Mobius function takes parameters of a mobius transform
# Outputs a function that does the transform
mobius <- function(a, b, c, d)
{
  fn <- function(z)
  {
    return((a*z + b)/(c*z + d))
  }
  return(fn)
}

# Mobius transform primitives
trans <- function(beta)
{
  fn <- function(z)
  {
    return(beta + z)
  }
  return(fn)
}
inv <- function(z)
{
  return(1/z)
}
hom_rotate <- function(alpha)
{
  fn <- function(z)
  {
    return(alpha*z)
  }
  return(fn)
}

# makes an in plot and out plot from table of pts
# z = in points, z2 = out points after transformation
make_plots <- function(pts_table)
{
  outplot = ggplot(pts_table, aes(x = Re(z2), y = Im(z2))) +
    geom_point(aes(col = Mod(z))) +
    scale_color_viridis_c()
  inplot = ggplot(pts_table, aes(x = Re(z), y = Im(z))) +
    geom_point(aes(col = Mod(z))) +
    scale_color_viridis_c()
  return(list(inplot = inplot, outplot = outplot))
}

# Mobius Examples ---------------------------------------------------------
startpts = make_circles(0, 5, 100, 100)

# translation
transfn = trans(complex(real = 1, imaginary = 1))
transpts = mutate(startpts, z2 = transfn(z))
transplots = make_plots(transpts)

# inversion
invpts = mutate(startpts, z2 = inv(z))
invplots = make_plots(invpts)

# homothety / rotation
alpha1 = complex(real = 2, imaginary = 0)
alpha2 = complex(modulus = 1, argument = pi/2)
homo = hom_rotate(alpha1)
rotate = hom_rotate(alpha2)

hrpts1 = mutate(startpts, z2 = homo(z))
hrpts2 = mutate(startpts, z2 = rotate(z))

hrplots1 = make_plots(hrpts1)
hrplots2 = make_plots(hrpts2)

# decomposition


# TODO: figure out how to use gganimate to animate the points?


# General Case ------------------------------------------------------------
# Definition of Schwarz Christoffel Mapping
# z is a complex number
# corners = real vector of corners showing how far apart the polygon corners are
# angles = real vector of angles 

# GOAL: want to come up with general case where you map
# polygon to polygon





