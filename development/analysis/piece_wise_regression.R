# Load required libraries
library(readr)
library(dplyr)
library(ggplot2)
library(segmented)
library(grid)
library(gridExtra)
library(scales)

# Load your dataset
final_path <- "C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/merged_data/final_data_all_three.csv"
final_data <- read_csv(final_path)
final_data <- final_data %>% mutate(COH = COH*100) %>% 
                             mutate(CBC_MSIZ_share = CBC_MSIZ_share*100) %>%
              filter(perc4 < 20) %>% filter(Total_Abundance_all < 600)

category <- "generalist" # all # farmland # generalist # urban

# Define variables
x_vars <- c("COH", "CBC_MSIZ_share", "perc1", "perc2", "perc3")  # Extend this list as needed
x_names <- c("coherence (%)", "coherence with CBC  (%)", "urban percentage  (%)", "agri percentage  (%)", "woodland percentage  (%)")
y_vars <- paste0(c("Total_Abundance", "Species_Richness", 
            "Shannon_Diversity", "Simpson_Diversity"), "_", category)
y_names <- c("Total Abundance", "Species Richness", 
            "Shannon Diversity", "Simpson Diversity")
names(x_names) <- x_vars
names(y_names) <- y_vars



# Plotting function
make_segmented_plot <- function(data, x_var, y_var, x_names, y_names, bottom=TRUE, left=TRUE, color_number=1) {
  df <- data %>% dplyr::select(site, year, all_of(x_var), all_of(y_var)) %>% na.omit
  names(df)[3:4] <- c("x", "y")
  
  lin.mod <- lm(y ~ x, data = df)
  
  seg.mod <- tryCatch({
    segmented(lin.mod, seg.Z = ~x, psi = median(df$x, na.rm = TRUE))
  }, error = function(e) return(NULL))
  
  if (bottom) {
    label_x <- x_names[x_var]
  } else {
    label_x <- ""
  }
  if (left) {
    label_y <- y_names[y_var]
  } else {
    label_y <- ""
  }
  
  p <- ggplot(df, aes(x = x, y = y)) +
    geom_point(alpha = 0.6, size=0.5, color=brewer_pal(palette = "Set2")(4)[color_number]) +
    labs(title =  " ", x = label_x, y = label_y) + 
    theme_minimal() +
    theme(
      axis.title.y = element_text(color = brewer_pal(palette = "Set2")(4)[color_number], size = 11)
    )
  
  if (!is.null(seg.mod)) {
    x_seq <- seq(min(df$x), max(df$x), length.out = 200)
    pred_df <- data.frame(x = x_seq)
    pred_df$y <- predict(seg.mod, newdata = pred_df)
    bp <- seg.mod$psi[2]
    
    
    
    p <- p +
      geom_line(data = pred_df, aes(x = x, y = y), color = "red", size=0.8) +
      geom_vline(xintercept = bp, color = "black", linetype = "dashed", size=0.8)
    
    
    
  } else {
    p <- p + annotate("text", x = mean(df$x), y = max(df$y, na.rm = TRUE), 
                      label = "Fit failed", color = "red")
    bp <- NA_real_
  }
  
  return(list(plot = p, breakpoint = bp))
}

# Create plot list in correct order: rows = y_vars, columns = x_vars
plot_grid <- list()
# Initialize a list to store breakpoints info
breakpoints_list <- list()

row_number <- 0 # from the top
for (y in y_vars) {
  row_number <- row_number + 1
  if (row_number == length(y_vars)) {
    bottom <- TRUE
  } else {
    bottom <- FALSE
  }
  left <- TRUE
  for (x in x_vars) {
    result_cur <- make_segmented_plot(final_data, x, y, x_names, y_names, bottom, left, color_number=row_number)
    plot_grid[[length(plot_grid) + 1]] <- result_cur$plot
    breakpoints_list[[paste(y, x, sep = "_")]] <- result_cur$breakpoint
    left <- FALSE
  }
}

# Arrange grid: ncol = number of X-vars, rows = one for each Y-var
grid.arrange(
  arrangeGrob(grobs = plot_grid, ncol = length(x_vars)),
  top = textGrob(paste0("Piece-wise regression for ", category, " birds"), gp = gpar(fontsize = 16, fontface = "bold"))
)

breakpoints_df <- data.frame(
  y_var = rep(y_vars, each = length(x_vars)),
  x_var = rep(x_vars, times = length(y_vars)),
  breakpoint = unlist(breakpoints_list)
)

print(breakpoints_df)

write.csv(breakpoints_df, paste0("C:/Users/Serv3/Desktop/Cambridge/Course/3 Easter/Dissertation EP/data/results/threshold_", category, ".csv"), row.names = FALSE)