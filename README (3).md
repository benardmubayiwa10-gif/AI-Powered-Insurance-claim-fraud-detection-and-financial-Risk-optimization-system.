# AI Insurance Fraud Detection

A complete R pipeline for detecting fraudulent insurance claims using statistical analysis and machine learning. The script is fully adaptive — it auto-detects the target column, handles missing data, and adjusts to any insurance claim CSV dataset.

---

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Pipeline Steps](#pipeline-steps)
- [Input Data Format](#input-data-format)
- [Outputs](#outputs)
- [ROI Assumptions](#roi-assumptions)
- [Notes & Limitations](#notes--limitations)

---

## Overview

`CLAIM_INSURANCE_DATA.R` runs a 13-step end-to-end fraud detection workflow:

1. Installs and loads required packages
2. Loads a CSV file interactively via file picker
3. Auto-detects the fraud/claim target column
4. Cleans and imputes the data
5. Performs Exploratory Data Analysis (EDA) with visualisations
6. Runs Chi-squared tests on all categorical variables
7. Fits Logistic Regression and Linear Regression models
8. Splits data into train/test sets (80/20)
9. Prepares features for Random Forest
10. Trains a Random Forest classifier (100 trees)
11. Evaluates the model (confusion matrix, ROC curve, AUC)
12. Calculates financial ROI from model predictions
13. Prints a final summary of all key metrics

---

## Requirements

- **R** version 4.0 or higher
- Internet access for first-time package installation

### R Packages

| Package | Purpose |
|---|---|
| `tidyverse` | Data manipulation and piping |
| `caret` | Train/test splitting and confusion matrix |
| `randomForest` | Random Forest classifier |
| `pROC` | ROC curve and AUC calculation |
| `ggplot2` | Visualisations |
| `gridExtra` | Multi-panel plot layout |

All packages are installed automatically on first run if not already present.

---

## Installation

Clone or download the script, then open it in RStudio or run it from the R console:

```r
source("CLAIM_INSURANCE_DATA.R")
```

No manual package installation is needed — the script handles this at startup.

---

## Usage

1. Open R or RStudio
2. Run the script with `source("CLAIM_INSURANCE_DATA.R")`
3. A **file picker dialog** will open — select your insurance claims CSV file
4. The script runs automatically from start to finish, printing results to the console and displaying plots

### Target Column Detection

The script searches for the fraud target column in this order:

1. Any column name containing **"fraud"** (case-insensitive)
2. Any column name containing **"claim"** (case-insensitive)
3. If neither is found, the script **stops with an error** — check your column names

---

## Pipeline Steps

### Step 1 — Packages
Checks for missing packages and installs them, then loads all libraries.

### Step 2 — Load Data
Reads the CSV via `file.choose()`, removes duplicate rows, and sanitises column names (special characters replaced with `_`).

### Step 3 — Identify Target Variable
Auto-detects the binary fraud/claim column to use as the classification target.

### Step 4 — Data Cleaning
- Drops columns with more than **40% missing values**
- Drops date/time-related columns (`date`, `time`, `year`, `month`, `day`, `hour`, `minute`, `second`)
- Converts target to a **factor**
- Removes rows where the target is `NA`
- Imputes missing **numeric** values with the **column median**
- Imputes missing **categorical** values with the **column mode**
- Removes any remaining rows with `NA`

### Step 5 — Exploratory Data Analysis
- **Histograms** for the first 6 numeric variables (2-column grid layout)
- **Cumulative frequency table** for the target variable (printed to console)
- **Cumulative frequency bar chart** for fraud classes
- **Cumulative frequency line chart** for the first numeric variable (20 buckets)

### Step 6 — Chi-Squared Tests
- Tests every categorical variable against the fraud target using `chisq.test()` with Monte Carlo simulation (`simulate.p.value = TRUE`)
- Prints **contingency tables** for all significant variables (p < 0.05)
- Outputs a full summary table: Variable, Chi-Square statistic, Degrees of Freedom, P-Value, Significant (YES/NO)

### Step 7 — Regression Analysis

**7.1 Logistic Regression** (binary target only):
- Fits `glm(..., family = binomial)` using up to 10 numeric predictors
- Prints model summary, odds ratios (`exp(coef())`), and 95% confidence intervals

**7.2 Linear Regression** (if a continuous claim/amount/value/cost column exists):
- Fits `lm()` on that column using up to 10 numeric predictors
- Prints model summary and ANOVA table

### Step 8 — Train/Test Split
- Uses `set.seed(123)` for reproducibility
- Stratified 80/20 split via `caret::createDataPartition()`

### Step 9 — Feature Preparation
- Encodes all factor and character columns as numeric
- Aligns test set columns to match training set
- Removes zero-variance columns
- Replaces any remaining `NA` values with `0`

### Step 10 — Train Random Forest
- Primary: `ntree = 100`, `importance = TRUE`
- Fallback (if primary fails): `ntree = 50`, `maxnodes = 10`

### Step 11 — Model Evaluation
- Generates predictions on the test set
- Prints **confusion matrix** with accuracy, sensitivity, and specificity
- Plots **ROC curve** and prints **AUC** score (binary classification only)
- Plots **variable importance** for up to 15 top features

### Step 12 — ROI Calculation

Translates model predictions into financial impact:

| Metric | Formula |
|---|---|
| Fraud Prevented | `TP × avg_claim` |
| Investigation Cost | `(TP + FP) × invest_cost` |
| Fraud Missed Cost | `FN × avg_claim` |
| **Net Savings** | `Fraud Prevented − Investigation Cost − Fraud Missed Cost` |

Default assumptions: `avg_claim = $5,000` · `invest_cost = $200`

### Step 13 — Final Summary
Prints a consolidated summary to the console:

```
========== FINAL SUMMARY ==========
Dataset Shape:       X rows, Y columns
Fraud Rate:          X.XX %
Model Accuracy:      X.XX %
Model Sensitivity:   X.XX %
Model Specificity:   X.XX %
AUC:                 X.XXXX
Net Savings:         $ X,XXX,XXX
===================================
```

---

## Input Data Format

The script accepts any CSV file with:

- At least one column named with **"fraud"** or **"claim"** (used as the binary target)
- A mix of numeric and categorical feature columns
- No required column ordering or naming convention beyond the target

### Example columns that work as the target

```
fraud_reported    → detected as "fraud"
FraudIndicator    → detected as "fraud"
claim_status      → detected as "claim"
CLAIM_TYPE        → detected as "claim"
```

### Columns automatically removed

- Any column with **> 40% missing values**
- Columns matching: `date`, `time`, `year`, `month`, `day`, `hour`, `minute`, `second`

---

## Outputs

All outputs are printed to the R console or displayed as plots:

| Output | Type | Step |
|---|---|---|
| Data overview (rows, columns, column names) | Console | 2 |
| Target column name and class distribution | Console | 3–4 |
| Histograms of numeric variables | Plot | 5 |
| Cumulative frequency charts | Plot | 5 |
| Chi-squared test results table | Console | 6 |
| Contingency tables (significant vars only) | Console | 6 |
| Logistic regression summary + odds ratios | Console | 7 |
| Linear regression summary + ANOVA | Console | 7 |
| Random Forest model summary | Console | 10 |
| Confusion matrix | Console | 11 |
| ROC curve | Plot | 11 |
| Variable importance plot | Plot | 11 |
| ROI financial breakdown | Console | 12 |
| Final summary statistics | Console | 13 |

---

## ROI Assumptions

The financial calculations use these hardcoded defaults — edit them directly in the script to match your business context:

```r
avg_claim    <- 5000   # Average cost of a fraudulent claim ($)
invest_cost  <- 200    # Cost to investigate one flagged claim ($)
```

---

## Notes & Limitations

- **File picker dialog** — the script uses `file.choose()`, which opens an interactive dialog. This requires a GUI environment (RStudio or R with a desktop). It will not work in headless/server-only environments. Replace with `read.csv("path/to/file.csv")` if needed.
- **Binary classification assumed** — ROC/AUC and logistic regression are only run when the target has exactly 2 levels. Multi-class targets will skip these steps.
- **Date columns are dropped** — temporal features are removed during cleaning. If time-of-day or seasonality is important to your use case, extract those features before running the script.
- **Reproducibility** — `set.seed(123)` ensures consistent train/test splits and Random Forest results across runs.
- **Single dataset** — the script is designed for a single merged CSV. If your data spans multiple files, join them before running.
