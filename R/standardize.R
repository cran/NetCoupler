
#' @title
#' Standardize the metabolic variables.
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' Can standardize by either 1) [log()]-transforming and then applying [scale()]
#' (mean-center and scaled by standard deviation), or 2) if `regressed_on`
#' variables are given, then log-transforming, running a linear regression to obtain
#' the [stats::residuals()], and finally scaled. Use `regressed_on` to try to
#' remove influence of potential confounding.
#'
#' @param data Data frame.
#' @param cols Metabolic variables that will make up the network.
#' @param regressed_on Optional. A character vector of variables to regress the
#'   metabolic variables on. Use if you want to standardize the metabolic variables
#'   on variables that are known to influence them, e.g. sex or age. Calculates
#'   the residuals from a linear regression model.
#'
#' @return Outputs a [tibble][tibble::tibble-package] object, with the original metabolic
#'   variables now standardized.
#' @export
#' @seealso [nc_estimate_links] for more detailed examples or the `vignette("NetCoupler")`.
#'
#' @examples
#'
#' # Don't regress on any variable
#' simulated_data %>%
#'   nc_standardize(starts_with("metabolite_"))
#'
#' # Extract residuals by regressing on a variable
#' simulated_data %>%
#'   nc_standardize(starts_with("metabolite_"), "age")
#'
#' # Works with factors too
#' simulated_data %>%
#'   dplyr::mutate(Sex = as.factor(sample(rep(c("F", "M"), times = nrow(.) / 2)))) %>%
#'   nc_standardize(starts_with("metabolite_"), c("age", "Sex"))
#'
nc_standardize <- function(data, cols = everything(), regressed_on = NULL) {
    if (!is.null(regressed_on)) {
        assert_character(regressed_on)
        standardized_data <- replace_with_residuals(
            data = data,
            cols = {{ cols }},
            regressed_on = regressed_on
        )
    } else {
        standardized_data <- data %>%
            mutate(dplyr::across(.cols = {{ cols }}, .fns = log_standardize))
    }
    return(standardized_data)
}

# Helpers -----------------------------------------------------------------

log_standardize <- function(x) {
    as.numeric(scale(log(x)))
}

log_regress_standardize <- function(data, x, regressed_on) {
    # TODO: Decide which method to regress by. lm only?
    data[x] <- log(data[x])
    formula <- stats::reformulate(regressed_on, response = x)
    residual_x <- stats::glm(formula = formula, data = data) %>%
        stats::residuals()
    as.numeric(scale(residual_x))
}

replace_with_residuals <- function(data, cols, regressed_on) {
    metabolic_names <- data %>%
        select({{ cols }}) %>%
        names()

    data_with_id_var <- data %>%
        # TODO: Check that no id variable exists
        mutate(.id_variable = dplyr::row_number())

    data_without_metabolic_vars <- data_with_id_var %>%
        select(-all_of(metabolic_names))

    data_with_residuals <- metabolic_names %>%
        purrr::map(~ extract_residuals(.x, data_with_id_var, regressed_on)) %>%
        purrr::reduce(dplyr::full_join, by = ".id_variable")

    standardized_data <- data_with_residuals %>%
        dplyr::full_join(data_without_metabolic_vars, by = ".id_variable") %>%
        dplyr::arrange(".id_variable") %>%
        # To put in original ordering
        dplyr::relocate(all_of(names(data_with_id_var))) %>%
        select(-".id_variable")

    return(standardized_data)
}

extract_residuals <- function(cols, data, regressed_on, id_var = ".id_variable") {
    no_missing <- data %>%
        select(all_of(c(cols, regressed_on, id_var))) %>%
        stats::na.omit()

    metabolic_residuals <-
        log_regress_standardize(no_missing,
                                cols,
                                regressed_on)

    no_missing[cols] <- metabolic_residuals

    data_with_residuals <- no_missing %>%
        select(all_of(c(cols, id_var)))

    return(data_with_residuals)
}
