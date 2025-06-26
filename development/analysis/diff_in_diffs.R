library(dplyr)
library(broom)
library(ggplot2)
library(lfe)
library(rlang)

run_did_three_groups <- function(data, y, t, unit_id, time_id, controls = NULL, threshold = 0.1) {
  
  # Standardize y and t
  data <- data %>%
    mutate(
      y_std = scale(!!sym(y))[, 1],
      t_std = scale(!!sym(t))[, 1]
    )
  
  # Standardize controls
  if (!is.null(controls)) {
    for (ctrl in controls) {
      data[[paste0(ctrl, "_std")]] <- scale(data[[ctrl]])[, 1]
    }
    control_vars_std <- paste0(controls, "_std")
  } else {
    control_vars_std <- NULL
  }

  # Define treatment groups
  data <- data %>%
    mutate(
      treat_group = case_when(
        t_std > threshold  ~ "positive",
        t_std < -threshold ~ "negative",
        TRUE               ~ "control"
      ),
      post = ifelse(!!sym(time_id) > median(!!sym(time_id), na.rm = TRUE), 1, 0)
    )

  results <- list()

  for (group in c("positive", "negative")) {
    data_sub <- data %>%
      filter(treat_group %in% c(group, "control")) %>%
      mutate(
        treat_dummy = ifelse(treat_group == group, 1, 0),
        did = treat_dummy * post
      )

    rhs_vars <- c("treat_dummy", "post", "did", control_vars_std)
    formula <- as.formula(
      paste0("y_std ~ ", paste(rhs_vars, collapse = " + "), " | ", unit_id, " + ", time_id)
    )

    model <- felm(formula, data = data_sub)

    res <- tidy(model) %>%
      filter(term == "did") %>%
      mutate(treatment_group = group)

    results[[group]] <- res
  }

  results_df <- bind_rows(results)

  # Plot
  p <- ggplot(results_df, aes(x = treatment_group, y = estimate, fill = treatment_group)) +
    geom_bar(stat = "identity", width = 0.5) +
    geom_errorbar(aes(ymin = estimate - 1.96 * std.error,
                      ymax = estimate + 1.96 * std.error), width = 0.2) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    scale_fill_manual(values = c(positive = "blue", negative = "red")) +
    labs(
      title = "Difference-in-Differences: Positive vs Negative vs Control",
      x = "Treatment Group",
      y = "Estimated DiD Effect (Standardized)"
    ) +
    theme_minimal()

  return(list(results = results_df, p = p))
}


# Read the data
diff_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/merged_data/difference_data_all_three.csv"
final_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/merged_data/final_data_all_three.csv"
final_data <- read_csv(final_path)
diff_data <- read_csv(diff_path)

y <- "Total_Abundance_woodland"
controls <- c("perc3", "temperature_moyenne24h",
"precipitation_somme24h", "radiation_somme24h")

result_list <- run_did_three_groups(
  data = final_data,
  y = y,
  t = "CBC_MSIZ",
  unit_id = "site",
  time_id = "year",
  controls = controls,
  #pos_thresholds = seq(-2, 2, by = 0.25),
  #neg_thresholds = seq(-2, 2, by = 0.25)
)

print(result_list["p"])