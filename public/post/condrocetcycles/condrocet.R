library(dplyr)
library(purrr)
library(igraph)
library(pbapply)
library(ggplot2)
library(readr)
library(Rcpp)


setwd("C:/Users/jason/Documents/jasonyang5.github.io/content/post/CondrocetCycles/")

sourceCpp('cycles.cpp')


# General Idea ------------------------------------------------------------
# m = number of options, n = number of people
# 1. Compute the preference relation of the group on all pairs in 1:m
# 2. Encode this into a graph G
# - Each element of 1:m is a node
# - Directed edge from i -> j if i '>' j
# 3. Check if G is acyclic

# Functions ---------------------------------------------------------------
# generates group prefereces under uniform assumption
generate_prefs2 <- function(n_indivs, m_options)
{
  # generates matrix of individual preference
  generate_matrix <- function(prevmat, indivnum)
  {
    order = sample.int(m_options)
    mat = generate_prefmat(order, m_options)
    return(mat + prevmat)
  }
  # sum the individual preferences matrices to get group preferences matrix
  return(reduce(.x = 1:n_indivs,
                .f = generate_matrix,
                .init = matrix(data = 0, nrow = m_options, ncol = m_options)))
}

# encodes the group preferences into a graph, checks that the graph
# is not cyclic
check_consistent <- function(n_indivs, m_options, generate_prefs_fn)
{
  # Generate group preferences
  votemat = generate_prefs_fn(n_indivs, m_options)
  edges = which(votemat > n_indivs/2, arr.ind = TRUE)
  G = graph_from_edgelist(edges, TRUE) 
  
  # Check that the graph is acyclic
  return(is_dag(G))
}
# check the proportion of consistent group preferences
prop_consistent <- function(n_indivs, m_options, S, generate_prefs_fn)
{
  count_consistent <- function(num_consistent, Snum)
  {
    num_consistent + check_consistent(n_indivs, m_options, generate_prefs_fn)
  }
  total_consistent = reduce(.x = 1:S,
                            .f = count_consistent,
                            .init = 0)
  return(total_consistent/S)
}

# Do Simulations ----------------------------------------------------------
# Generate a log-spaced spaced vector
logseq <- function(lower, upper, npts)
{
  lowerlog = log(lower)
  upperlog = log(upper)
  normseq = seq(lowerlog, upperlog, length.out = npts)
  return(exp(normseq))
}
# Simulation parameters
S = 200
ns = logseq(3, 1000, npts = 50) %>%
  round() %>%
  unique()
ms = logseq(3, 100, npts = 30) %>%
  round() %>%
  unique()


# Run the simulation
nm_combos = cross2(ns, ms)
results = pblapply(X = nm_combos,
                   FUN = {function(nm_combo)
                     prop_consistent(nm_combo[[1]], nm_combo[[2]], S, generate_prefs2)})

# Specific Example --------------------------------------------------------
# idea for specific example: look at who is voting for what?
# generate preferences that have a cycle
find_cycle <- function(n, m)
{
  # generates matrix of individual preference
  generate_matrix <- function(order)
  {
    order = sample.int(m)
    mat = generate_prefmat(order, m)
    return(mat)
  }
  # check
  check_consistent2 <- function(grp)
  {
    edges = which(grp > n/2, arr.ind = TRUE)
    G = graph_from_edgelist(edges, TRUE)
    return(list(check = is_dag(G), graph = G))
  }
  # run until we find an inconsistent preference
  check = TRUE
  itermax = 100
  iter = 1
  while(check & iter < itermax)
  {
    orders = map(1:n, ~sample.int(m))
    indivs = map(orders, generate_matrix)
    grp = reduce(.x = indivs, 
                 .f = `+`, 
                 .init = matrix(0, nrow(indivs[[1]]), ncol(indivs[[1]])))
    out = check_consistent2(grp)
    check = out$check
    G = out$graph
    iter = iter + 1
  }
  return(list(indivs_vec = orders, 
              indivs_mat = indivs, 
              graph = G))
}

# find a cycle
cycle = find_cycle(3, 5)

# plot of the group preference
plot(cycle$graph, 
     mark.groups = list(c(5,2,1)),
     main = "Example of Group Preference Cycle")

# plot of the individual preference
indiv_graphs = map(cycle$indivs_mat,
                   {function(mat) graph_from_edgelist(which(mat == 1, arr.ind = TRUE))})
plot(indiv_graphs[[1]], main = "Preference A")
plot(indiv_graphs[[2]], main = "Preference B")
plot(indiv_graphs[[3]], main = "Preference C")

# generate a table 
cycle$indivs_mat[[1]][1,5]
cycle$indivs_mat[[2]][1,5]
cycle$indivs_mat[[3]][1,5]


# Plots -------------------------------------------------------------------
# Generate plotting data
plot_data = map2_dfr(nm_combos, results,
                     {function(combo, result) tibble(NumberPeople = combo[[1]],
                                                     NumberItems = combo[[2]],
                                                     ConsistentPercent = result)})
write_csv(plot_data, "outputdata_high.csv")

# Plot n vs m heatmap
plt = ggplot(plot_data, aes(x = NumberPeople, y = NumberItems)) +
  geom_tile(aes(fill = ConsistentPercent*100), interpolate = TRUE) +
  labs(x = "Number of People", y = "Number of Policies",
       title = "Heatmap") +
  scale_y_log10() +
  scale_x_log10() +
  scale_fill_viridis_c("Percent Consistent") +
  theme_bw()

ggsave("heatmap.png", plt)
# 
# # Plot n holding m constant (m = 3 (presid election), m = 10 (10 policies?))
