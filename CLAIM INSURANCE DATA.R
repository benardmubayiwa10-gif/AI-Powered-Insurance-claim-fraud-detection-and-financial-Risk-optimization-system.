############################################################
# AI Insurance Fraud Detection - COMPLETE WITH STATISTICAL ANALYSIS
############################################################

#############################
# 1. INSTALL & LOAD PACKAGES
#############################

packages <- c("tidyverse", "caret", "randomForest", "pROC", 
              "ggplot2", "gridExtra")

installed <- packages %in% rownames(installed.packages())
if(any(!installed)) install.packages(packages[!installed])

library(tidyverse)
library(caret)
library(randomForest)
library(pROC)
library(ggplot2)
library(gridExtra)

#############################
# 2. LOAD DATA
#############################

df <- read.csv(file.choose(), stringsAsFactors = FALSE)
df <- df %>% distinct()

# Clean column names
names(df) <- gsub("[^a-zA-Z0-9]", "_", names(df))
names(df) <- make.names(names(df), unique = TRUE)

cat("========== DATA OVERVIEW ==========\n")
cat("Dataset loaded with", nrow(df), "rows and", ncol(df), "columns\n")
cat("\nColumn names:\n")
print(head(names(df), 15))

#############################
# 3. IDENTIFY TARGET VARIABLE
#############################

# Find fraud column
fraud_col <- grep("fraud", names(df), ignore.case = TRUE, value = TRUE)[1]

if(length(fraud_col) == 0 || is.na(fraud_col)) {
  fraud_col <- grep("claim", names(df), ignore.case = TRUE, value = TRUE)[1]
}

if(length(fraud_col) == 0 || is.na(fraud_col)) {
  stop("Could not find target column. Please check your data.")
}

cat("\nTarget column:", fraud_col, "\n")

#############################
# 4. DATA CLEANING
#############################

# Remove columns with too many NAs (>40%)
na_count <- colSums(is.na(df))
cols_to_remove <- names(na_count[na_count > 0.4 * nrow(df)])
if(length(cols_to_remove) > 0) {
  df <- df[, !names(df) %in% cols_to_remove]
}

# Remove date columns
date_pattern <- "date|time|year|month|day|hour|minute|second"
date_cols <- grep(date_pattern, names(df), ignore.case = TRUE, value = TRUE)
if(length(date_cols) > 0) {
  df <- df[, !names(df) %in% date_cols]
}

# Convert target to factor
df[[fraud_col]] <- as.factor(df[[fraud_col]])

# Remove rows with NA in target
df <- df[!is.na(df[[fraud_col]]), ]

# Impute missing values
# Numeric columns - median imputation
num_cols <- names(df)[sapply(df, is.numeric)]
for(col in num_cols) {
  if(any(is.na(df[[col]]))) {
    df[[col]][is.na(df[[col]])] <- median(df[[col]], na.rm = TRUE)
  }
}

# Character columns - convert to factor and mode imputation
char_cols <- names(df)[sapply(df, is.character)]
for(col in char_cols) {
  df[[col]] <- as.factor(df[[col]])
  if(any(is.na(df[[col]]))) {
    df[[col]][is.na(df[[col]])] <- names(sort(table(df[[col]]), decreasing = TRUE))[1]
  }
}

# Remove any remaining NAs
df <- na.omit(df)

cat("\nAfter cleaning:", nrow(df), "rows and", ncol(df), "columns\n")
cat("\nTarget distribution:\n")
print(table(df[[fraud_col]]))
cat("\nTarget percentages:\n")
print(prop.table(table(df[[fraud_col]])) * 100)

#############################
# 5. EXPLORATORY DATA ANALYSIS
#############################

cat("\n========== EXPLORATORY DATA ANALYSIS ==========\n")

# 5.1 HISTOGRAMS for numeric variables
numeric_vars <- names(df)[sapply(df, is.numeric)]
numeric_vars <- head(numeric_vars, 6)  # Limit to first 6 for display

if(length(numeric_vars) > 0) {
  cat("\nGenerating histograms for numeric variables...\n")
  
  plot_list <- list()
  for(i in seq_along(numeric_vars)) {
    var_name <- numeric_vars[i]
    p <- ggplot(df, aes(x = .data[[var_name]])) +
      geom_histogram(fill = "steelblue", color = "black", bins = 30) +
      labs(title = paste("Histogram of", var_name),
           x = var_name, y = "Frequency") +
      theme_minimal()
    plot_list[[i]] <- p
  }
  
  # Display histograms in a grid
  if(length(plot_list) > 0) {
    grid.arrange(grobs = plot_list, ncol = 2, 
                 top = "Distribution of Numeric Variables")
  }
}

# 5.2 CUMULATIVE FREQUENCY for target variable
cat("\nGenerating cumulative frequency analysis...\n")

# Cumulative frequency for target
target_cumfreq <- cumsum(table(df[[fraud_col]]))
target_cumfreq_pct <- cumsum(prop.table(table(df[[fraud_col]])) * 100)

cat("\nCumulative Frequency - Target Variable:\n")
cat("Class\tFrequency\tCumulative\tCumulative %\n")
for(i in 1:length(target_cumfreq)) {
  cat(names(target_cumfreq)[i], "\t", 
      table(df[[fraud_col]])[i], "\t\t",
      target_cumfreq[i], "\t\t",
      round(target_cumfreq_pct[i], 2), "%\n")
}

# Plot cumulative frequency
cumfreq_df <- data.frame(
  Class = names(target_cumfreq),
  Frequency = as.vector(table(df[[fraud_col]])),
  Cumulative = as.vector(target_cumfreq),
  Cumulative_Pct = as.vector(target_cumfreq_pct)
)

p_cumfreq <- ggplot(cumfreq_df, aes(x = Class, y = Cumulative)) +
  geom_bar(stat = "identity", fill = "darkgreen", alpha = 0.7) +
  geom_text(aes(label = Cumulative), vjust = -0.5) +
  labs(title = "Cumulative Frequency - Fraud Classes",
       x = "Class", y = "Cumulative Frequency") +
  theme_minimal()
print(p_cumfreq)

# 5.3 Cumulative frequency for a numeric variable (if available)
if(length(numeric_vars) > 0) {
  num_var <- numeric_vars[1]
  df_sorted <- df[order(df[[num_var]]), ]
  cumfreq_num <- cumsum(table(cut(df_sorted[[num_var]], breaks = 20)))
  
  cumfreq_num_df <- data.frame(
    Bucket = 1:length(cumfreq_num),
    Cumulative = as.vector(cumfreq_num)
  )
  
  p_cumfreq_num <- ggplot(cumfreq_num_df, aes(x = Bucket, y = Cumulative)) +
    geom_line(color = "red", size = 1) +
    geom_point(color = "darkred", size = 2) +
    labs(title = paste("Cumulative Frequency -", num_var),
         x = "Value Buckets", y = "Cumulative Frequency") +
    theme_minimal()
  print(p_cumfreq_num)
}

#############################
# 6. CHI-SQUARED TESTS
#############################

cat("\n========== CHI-SQUARED TESTS ==========\n")

# Find categorical variables (factors)
cat_vars <- names(df)[sapply(df, is.factor)]
cat_vars <- setdiff(cat_vars, fraud_col)

if(length(cat_vars) > 0) {
  cat("\nPerforming Chi-squared tests with target variable...\n")
  
  chi_results <- data.frame(
    Variable = character(),
    Chi_Square = numeric(),
    Df = integer(),
    P_Value = numeric(),
    Significant = character(),
    stringsAsFactors = FALSE
  )
  
  for(var in cat_vars) {
    # Create contingency table
    cont_table <- table(df[[var]], df[[fraud_col]])
    
    # Perform chi-squared test
    if(nrow(cont_table) > 1 && ncol(cont_table) > 1) {
      test_result <- chisq.test(cont_table, simulate.p.value = TRUE)
      
      chi_results <- rbind(chi_results, data.frame(
        Variable = var,
        Chi_Square = round(test_result$statistic, 4),
        Df = test_result$parameter,
        P_Value = format.pval(test_result$p.value, digits = 4),
        Significant = ifelse(test_result$p.value < 0.05, "YES", "NO"),
        stringsAsFactors = FALSE
      ))
      
      # Print contingency table for significant results
      if(test_result$p.value < 0.05) {
        cat("\nSignificant association found for:", var, "\n")
        cat("P-value:", format.pval(test_result$p.value, digits = 4), "\n")
        print(cont_table)
        cat("\n")
      }
    }
  }
  
  if(nrow(chi_results) > 0) {
    cat("\nChi-squared Test Results Summary:\n")
    print(chi_results)
  }
} else {
  cat("No categorical variables found for Chi-squared tests.\n")
}

#############################
# 7. REGRESSION ANALYSIS
#############################

cat("\n========== REGRESSION ANALYSIS ==========\n")

# 7.1 LOGISTIC REGRESSION (for binary classification)
if(length(levels(df[[fraud_col]])) == 2) {
  cat("\nPerforming Logistic Regression...\n")
  
  # Prepare data for regression
  reg_data <- df
  
  # Convert target to numeric (0/1)
  reg_data$target_numeric <- ifelse(reg_data[[fraud_col]] == levels(reg_data[[fraud_col]])[2], 1, 0)
  
  # Select top numeric predictors (limit to avoid overfitting)
  top_numeric <- head(numeric_vars, min(10, length(numeric_vars)))
  
  if(length(top_numeric) > 0) {
    # Create formula
    formula_logit <- as.formula(paste("target_numeric ~", paste(top_numeric, collapse = " + ")))
    
    # Fit logistic regression
    logit_model <- glm(formula_logit, data = reg_data, family = binomial)
    
    cat("\nLogistic Regression Summary:\n")
    print(summary(logit_model))
    
    # Odds ratios
    cat("\nOdds Ratios:\n")
    odds_ratios <- exp(coef(logit_model))
    print(round(odds_ratios, 4))
    
    # Confidence intervals
    cat("\nConfidence Intervals:\n")
    conf_int <- confint(logit_model)
    print(round(conf_int, 4))
  }
}

# 7.2 LINEAR REGRESSION (if there's a continuous variable to predict)
claim_var <- grep("claim|amount|value|cost", names(df), ignore.case = TRUE, value = TRUE)[1]
if(!is.na(claim_var) && is.numeric(df[[claim_var]])) {
  cat("\n\nPerforming Linear Regression on", claim_var, "...\n")
  
  # Select predictors
  predictors <- head(numeric_vars[numeric_vars != claim_var], min(10, length(numeric_vars)))
  
  if(length(predictors) > 0) {
    # Create formula
    formula_lm <- as.formula(paste(claim_var, "~", paste(predictors, collapse = " + ")))
    
    # Fit linear regression
    lm_model <- lm(formula_lm, data = df)
    
    cat("\nLinear Regression Summary:\n")
    print(summary(lm_model))
    
    # ANOVA
    cat("\nANOVA Table:\n")
    print(anova(lm_model))
  }
}

#############################
# 8. TRAIN-TEST SPLIT
#############################

set.seed(123)
train_index <- createDataPartition(df[[fraud_col]], p = 0.8, list = FALSE)
train_data <- df[train_index, ]
test_data <- df[-train_index, ]

#############################
# 9. PREPARE DATA FOR RANDOM FOREST
#############################

# Separate features and target
train_x <- train_data[, !names(train_data) %in% fraud_col]
train_y <- train_data[[fraud_col]]
test_x <- test_data[, !names(test_data) %in% fraud_col]
test_y <- test_data[[fraud_col]]

# Convert all features to numeric
for(col in names(train_x)) {
  if(is.factor(train_x[[col]])) {
    train_x[[col]] <- as.numeric(train_x[[col]])
  }
  if(is.character(train_x[[col]])) {
    train_x[[col]] <- as.numeric(as.factor(train_x[[col]]))
  }
}

for(col in names(test_x)) {
  if(is.factor(test_x[[col]])) {
    test_x[[col]] <- as.numeric(test_x[[col]])
  }
  if(is.character(test_x[[col]])) {
    test_x[[col]] <- as.numeric(as.factor(test_x[[col]]))
  }
}

# Ensure test_x has same columns as train_x
test_x <- test_x[, names(train_x)]

# Remove columns with zero variance
zero_var <- sapply(train_x, function(x) length(unique(x)) == 1)
if(any(zero_var)) {
  train_x <- train_x[, !zero_var]
  test_x <- test_x[, !zero_var]
}

# Final check for NAs
train_x[is.na(train_x)] <- 0
test_x[is.na(test_x)] <- 0

# Combine back for random forest
train_rf <- cbind(train_x, temp_target = train_y)
names(train_rf)[ncol(train_rf)] <- fraud_col

test_rf <- cbind(test_x, temp_target = test_y)
names(test_rf)[ncol(test_rf)] <- fraud_col

cat("\nFinal training data:", nrow(train_rf), "rows,", ncol(train_rf)-1, "predictors\n")

#############################
# 10. TRAIN RANDOM FOREST
#############################

cat("\n========== RANDOM FOREST MODEL ==========\n")

# Try with different parameters if needed
rf_model <- tryCatch({
  randomForest(as.formula(paste(fraud_col, "~ .")),
               data = train_rf,
               ntree = 100,
               importance = TRUE)
}, error = function(e) {
  cat("First attempt failed, trying simpler model...\n")
  
  randomForest(as.formula(paste(fraud_col, "~ .")),
               data = train_rf,
               ntree = 50,
               maxnodes = 10,
               importance = TRUE)
})

print(rf_model)

#############################
# 11. EVALUATE MODEL
#############################

# Make predictions
predictions <- predict(rf_model, test_rf)

# Confusion matrix
cm <- confusionMatrix(predictions, test_rf[[fraud_col]])
print(cm)

# ROC curve
if(length(levels(test_rf[[fraud_col]])) == 2) {
  probs <- predict(rf_model, test_rf, type = "prob")
  positive_class <- levels(test_rf[[fraud_col]])[2]
  
  roc_obj <- roc(test_rf[[fraud_col]], probs[, positive_class])
  cat("\nAUC:", round(auc(roc_obj), 4), "\n")
  
  plot(roc_obj, main = "ROC Curve", col = "blue", lwd = 2)
}

# Feature importance
varImpPlot(rf_model, main = "Feature Importance", n.var = min(15, ncol(train_x)))

#############################
# 12. ROI CALCULATION
#############################

conf_matrix <- cm$table
TP <- conf_matrix[2,2]
FP <- conf_matrix[2,1]
FN <- conf_matrix[1,2]
TN <- conf_matrix[1,1]

avg_claim <- 5000
invest_cost <- 200

fraud_prevented <- TP * avg_claim
investigation_cost <- (TP + FP) * invest_cost
fraud_missed_cost <- FN * avg_claim
net_savings <- fraud_prevented - investigation_cost - fraud_missed_cost

cat("\n========== ROI ANALYSIS ==========\n")
cat("Confusion Matrix:\n")
print(conf_matrix)
cat("\nTrue Positives (Fraud Caught):", TP, "\n")
cat("False Positives (Wrong Alerts):", FP, "\n")
cat("False Negatives (Missed Fraud):", FN, "\n")
cat("True Negatives (Correct Non-Fraud):", TN, "\n")
cat("\nFinancial Impact:\n")
cat("Fraud Prevented: $", format(fraud_prevented, big.mark = ","), "\n")
cat("Investigation Cost: $", format(investigation_cost, big.mark = ","), "\n")
cat("Fraud Missed Cost: $", format(fraud_missed_cost, big.mark = ","), "\n")
cat("Net Savings: $", format(net_savings, big.mark = ","), "\n")
cat("===================================\n")

#############################
# 13. SUMMARY STATISTICS
#############################

cat("\n========== FINAL SUMMARY ==========\n")
cat("Dataset Shape:", nrow(df), "rows,", ncol(df), "columns\n")
cat("Fraud Rate:", round(mean(df[[fraud_col]] == levels(df[[fraud_col]])[2]) * 100, 2), "%\n")
cat("Model Accuracy:", round(cm$overall['Accuracy'] * 100, 2), "%\n")
cat("Model Sensitivity:", round(cm$byClass['Sensitivity'] * 100, 2), "%\n")
cat("Model Specificity:", round(cm$byClass['Specificity'] * 100, 2), "%\n")
cat("AUC:", round(auc(roc_obj), 4), "\n")
cat("Net Savings: $", format(net_savings, big.mark = ","), "\n")
cat("===================================\n")

############################################################
# END - COMPLETE VERSION
############################################################