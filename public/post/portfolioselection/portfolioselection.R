library(dplyr)
library(ggplot2)
library(nloptr)
library(purrr)
library(tidyr)


# MeanVariance ------------------------------------------------------------
# Tools for computing mean variance

cor2cov <- function(cor, v1, v2)
{
  return(cor*(sqrt(v1)*sqrt(v2)))
}

# Computes portfolio variance 
portvar <- function(w1, m1, m2, v1, v2, covar)
{
  w2 = 1-w1
  return(w1^2*v1 + w2^2*v2 + 2*w1*w2*covar) 
}
# # TODO: check if this derivative is right
# portvar_deriv <- function(w1, m1, m2, v1, v2, covar)
# {
#   retrun(100*(2*w1*v1 - 2*(1-w1) - 4*w1*covar))
# }
# Conducts the mean variance optimization 
m_v_opt <- function(mu0, m1, m2, v1, v2, covar)
{
  optout = nloptr(x0 = 0.5,
                  eval_f = {function(w) portvar(w, m1, m2, v1, v2, covar)},
                  eval_g_ineq = {function(w) mu0 - w*m1 - (1-w)*m2},
                  opts = list(algorithm = "NLOPT_LN_COBYLA",
                              ftol_abs = 1e-6),
                  ub = 1)
  return(list(portvol = sqrt(optout$objective),
              w1 = optout$solution))
}


# Plots -------------------------------------------------------------------
# TODO: figure out how to animate this with gg animate?
m1 = 0.05
m2 = 0.05
covar = 0
v1 = 0.09
v2 = 0.09

genplot <- function(m1, m2, v1, v2, covar)
{
  # All possible values
  plotdata = tibble(w1 = seq(0, 1, length.out = 100)) %>%
    mutate(w2 = 1 - w1,
           portret = w1*m1 + w2*m2,
           portsd = sqrt(portvar(w1, m1, m2, v1, v2, covar)))
  # Efficient frontier
  eff_portdata = tibble(portret = seq(min(m1, m2), max(m1, m2), length.out = 100)) %>%
    mutate(opts = map(.x = portret,
                      .f = {function(mu0) m_v_opt(mu0,
                                                  m1, m2, v1, v2, covar)})) %>%
    mutate(portsd = map_dbl(opts, {function(x) pluck(x, "portvol")}),
           w1 = map_dbl(opts, {function(x) pluck(x, "w1")}))
  
  # Plot all possible values in color line, efficient frontier in dots
  plt = ggplot(plotdata, aes(x = portret*100, y = portsd*100)) +
    geom_line(aes(col = w1), size = 1) +
    geom_point(aes(col = w1), data = eff_portdata, size = 1.25) +
    scale_color_viridis_c("a1 Weight") +
    labs(x = "Portfolio Return", y = "Portfolio Volatility",
         title = "Accessible Assets with Portfolios: No Leverage") +
    theme_bw()
  return(list(data = plotdata, eff_data = eff_portdata,plot = plt))
}

# Generates plots with leverage
genplot_leverage <- function(m1, m2, v1, v2, covar)
{
  # Lone portfolios with leverage 0 to 2x
  sd1 = sqrt(v1)
  sd2 = sqrt(v2)
  sharpe_1 = m1/sd1
  sharpe_2 = m2/sd2
  volmax = max(sd1*2, sd2*2)
  plotdata = tibble(portvol = seq(0, volmax, length.out = 100),
                    portret1 = sharpe_1 * portvol,
                    portret2 = sharpe_2 * portvol)
                    
  covmat = matrix(c(v1, covar, covar, v2), nrow = 2, ncol = 2, byrow = TRUE)
  # range of the return - for purposes of plotting
  volrange = c(0, volmax) 
  
  # Max sharpe ratio portfolio with leverage
  wstar = solve(covmat) %*% c(m1, m2)
  wstar = wstar/sum(wstar)
  ret_wstar = as.vector(t(wstar) %*% c(m1, m2))
  var_wstar = portvar(wstar[1,], m1, m2, v1, v2, covar)
  sd_wstar = sqrt(var_wstar)
  sharpe_wstar = ret_wstar/sd_wstar
  
  # Add Combined portfolios with leverage
  plot_all = mutate(plotdata, portretstar = sharpe_wstar*portvol) %>%
    pivot_longer(cols = -portvol, values_to = "portret")
  ggplot(plot_all, aes(x = portvol*100, y = portret*100, col = name)) +
    geom_line(size = 1) +
    labs(x = "Portfolio Volatility", y = "Portfolio Return",
         title = "Accessible Assets with Portfolios: With Leverage") +
    coord_flip() +
    theme_bw()
}

# Baseline generated plots
# TODO: Stich these together with cowplot??
# TODO: highligt that the optimal weight
setwd("C:/Users/jason/Documents/jasonyang5.github.io/content/post/PortfolioSelection/")
plot2 = genplot(0.05, 0.03, 0.3^2, 0.15^2, 0)


ggsave("plot2.png")
plot3 = genplot(0.05, 0.03, 0.3^2, 0.15^2, cor2cov(0.9, 0.3^2, 0.15^2))
ggsave("plot3.png")
plot4 = genplot(0.05, 0.03, 0.3^2, 0.15^2, cor2cov(-0.9, 0.3^2, 0.15^2))
ggsave("plot4.png")
plot5 = genplot(0.05, -0.005, 0.3^2, 0.15^2, cor2cov(-0.5, 0.3^2, 0.15^2))
ggsave("plot5.png")

# Leverage plots
plot_lev2 = genplot_leverage(0.05, 0.03, 0.3^2, 0.15^2, 0)
ggsave("plot_lev2.png")

plot_lev3 = genplot_leverage(0.05, 0.03, 0.3^2, 0.15^2, cor2cov(0.9, 0.3^2, 0.15^2))
ggsave("plot_lev3.png")

plot_lev4 = genplot_leverage(0.05, 0.03, 0.3^2, 0.15^2, cor2cov(-0.9, 0.3^2, 0.15^2))
ggsave("plot_lev4.png")

plot_lev5 = genplot_leverage(0.05, -0.005, 0.3^2, 0.15^2, cor2cov(-0.5, 0.3^2, 0.15^2))
ggsave("plot_lev5.png")
