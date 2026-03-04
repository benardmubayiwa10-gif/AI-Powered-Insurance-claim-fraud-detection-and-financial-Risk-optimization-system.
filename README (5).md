# Insurance Fraud Detection — R Pipeline

An end-to-end machine learning pipeline for detecting insurance claim fraud using Random Forest classification, with full statistical analysis, regression modeling, and ROI calculation.

---

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Pipeline Steps](#pipeline-steps)
- [Output & Results](#output--results)
- [Configuration](#configuration)
- [Notes](#notes)

---

## Overview

This script automates the full lifecycle of an insurance fraud detection model:

1. Loads and cleans a CSV dataset
2. Performs exploratory data analysis (EDA) with visualizations
3. Runs chi-squared tests on categorical variables
4. Fits logistic and linear regression models
5. Trains and evaluates a Random Forest classifier
6. Generates an ROI analysis based on model predictions

---

## Requirements

| Package | Purpose |
|---|---|
| `tidyverse` | Data manipulation and cleaning |
| `caret` | Train/test splitting and model evaluation |
| `randomForest` | Random Forest classification |
| `pROC` | ROC curve and AUC calculation |
| `ggplot2` | Data visualization |
| `gridExtra` | Multi-panel plot layouts |

**R version:** 4.0 or higher recommended.

---

## Installation

Packages are installed automatically on first run. To install manually:

```r
install.packages(c("tidyverse", "caret", "randomForest", "pROC", "ggplot2", "gridExtra"))
```

---

## Usage

1. Open the script in RStudio or an R console.
2. Run the script — a file chooser dialog will open.
3. Select your CSV file containing insurance claim data.
4. Results and plots are printed to the console and R graphics device.

```r
source("CLAIM_INSURANCE_DATA.R")
```

**Expected input:** A CSV file with at least one column containing "fraud" in its name (used as the target variable). If no "fraud" column is found, the script falls back to a column containing "claim".

---

## Pipeline Steps

### 1. Data Loading & Cleaning

- Removes duplicate rows
- Drops columns with more than 40% missing values
- Removes date/time columns
- Imputes missing values (median for numeric, mode for categorical)
- Converts the target variable to a binary factor

### 2. Exploratory Data Analysis

- **Histograms** — distributions of the first 6 numeric variables
- **Cumulative frequency plots** — for the target class and the first numeric variable

### 3. Chi-Squared Tests

Runs chi-squared tests between each categorical variable and the fraud target. Prints contingency tables for any variable with a significant association (p < 0.05).

### 4. Regression Analysis

- **Logistic Regression** — fits a binary logistic model using the top numeric predictors; outputs coefficients, odds ratios, and confidence intervals
- **Linear Regression** — if a claim amount/value column is detected, fits a linear model and prints an ANOVA table

### 5. Model Training

- Splits data 80/20 (train/test) using a fixed seed (`set.seed(123)`)
- Trains a Random Forest with 100 trees (`ntree = 100`)
- Falls back to a simpler model (50 trees, max 10 nodes) if the primary model fails

### 6. Model Evaluation

- Confusion matrix with accuracy, sensitivity, and specificity
- ROC curve with AUC score
- Feature importance plot (top 15 variables)

### 7. ROI Calculation

Estimates financial impact using:

| Parameter | Value |
|---|---|
| Average claim value | $5,000 |
| Investigation cost per flagged claim | $200 |

Calculates fraud prevented, investigation costs, missed fraud costs, and **net savings**.

---

## Output & Results

All results are printed to the console. Plots are rendered to the active R graphics device and include:

- Histograms of numeric variables
- Cumulative frequency charts
- ROC curve
- Feature importance plot

**Console summary example:**

```
Dataset Shape: 15420 rows, 18 columns
Fraud Rate: 6.8%
Model Accuracy: 94.2%
Model Sensitivity: 87.3%
Model Specificity: 96.1%
AUC: 0.9714
Net Savings: $716,800
```

---

## Configuration

To adjust the financial assumptions in the ROI section, edit these variables near the end of the script:

```r
avg_claim    <- 5000   # Average value of a fraudulent claim ($)
invest_cost  <- 200    # Cost to investigate one flagged claim ($)
```

To change the train/test split ratio or the random seed:

```r
set.seed(123)
train_index <- createDataPartition(df[[fraud_col]], p = 0.8, list = FALSE)
```

---

## Notes

- The script auto-detects the fraud target column by searching for "fraud" or "claim" in column names.
- Column names are sanitised on load (special characters replaced with underscores).
- All factor and character columns are label-encoded before being passed to Random Forest.
- Zero-variance columns are automatically removed from the feature set before training.
