## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## -----------------------------------------------------------------------------
knitr::include_graphics("aim-output.png")

## -----------------------------------------------------------------------------
knitr::include_graphics("nc-diagram-io.png", dpi = 144)

## ----metabolic-standardize----------------------------------------------------
library(NetCoupler)
std_metabolic_data <- simulated_data %>% 
    nc_standardize(starts_with("metabolite"))

## ----metabolic-standardize-residuals, eval=FALSE------------------------------
# std_metabolic_data <- simulated_data %>%
#     nc_standardize(starts_with("metabolite"),
#                    regressed_on = "age")

## ----create-network-----------------------------------------------------------
# Make partial independence network from metabolite data
metabolite_network <- std_metabolic_data %>% 
    nc_estimate_network(starts_with("metabolite"))

## ----standardize-data---------------------------------------------------------
standardized_data <- simulated_data %>% 
    nc_standardize(starts_with("metabolite"))

## ----example-use, cache=TRUE--------------------------------------------------
outcome_estimates <- standardized_data %>%
    nc_estimate_outcome_links(
        edge_tbl = as_edge_tbl(metabolite_network),
        outcome = "outcome_continuous",
        model_function = lm
    )
outcome_estimates

exposure_estimates <- standardized_data %>%
    nc_estimate_exposure_links(
        edge_tbl = as_edge_tbl(metabolite_network),
        exposure = "exposure",
        model_function = lm
    )
exposure_estimates

## ----estimation-adjustment, eval=FALSE----------------------------------------
# outcome_estimates <- standardized_data %>%
#     nc_estimate_outcome_links(
#         edge_tbl = as_edge_tbl(metabolite_network),
#         outcome = "outcome_continuous",
#         model_function = lm,
#         adjustment_vars = "age"
#     )

## ----future-parallel-processing, eval=FALSE-----------------------------------
# # You'll need to have furrr installed for this to work.
# library(future)
# plan(multisession)
# outcome_estimates <- standardized_data %>%
#     nc_estimate_outcome_links(
#         edge_tbl = as_edge_tbl(metabolite_network),
#         outcome = "outcome_continuous",
#         model_function = lm
#     )
# plan(sequential)

