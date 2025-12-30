# 📦 Demand Forecasting & Inventory Planning  
**BigQuery | BigQuery ML | SQL | GCP**

---

## 📌 Project Overview

Accurate demand forecasting is critical for inventory planning, cost optimization, and customer satisfaction.  
Overstocking increases holding costs, while understocking leads to lost sales.

This project delivers an **end-to-end demand forecasting solution** using **BigQuery SQL and BigQuery ML**, converting raw transaction data into **actionable inventory decisions**.

**Key focus:** Forecast → Inventory planning → Business action.

---

## 🎯 Business Problem

Retail teams need to answer:

- How many units should we stock next week?
- When will demand spike or drop?
- How much buffer inventory is required?
- How can forecasting reduce stockout and overstock risk?

**Business Goal:**  
Predict weekly demand and translate forecasts into **minimum and maximum stock levels**.

---

## 🧠 Business Questions Answered

- What will weekly demand look like?
- How volatile is demand?
- Is there seasonality in sales?
- How much inventory should be planned?
- How can forecasting reduce operational risk?

---

## 🗂 Dataset Overview

**Dataset:** Online Retail Transactions  
**Granularity:** Invoice-level data

### Key Columns

| Column | Description |
|------|------------|
| Invoice | Invoice number |
| StockCode | Product ID |
| Quantity | Units sold (negative = returns) |
| InvoiceDate | Transaction timestamp |
| Price | Unit price |
| CustomerID | Customer identifier |
| Country | Customer country |

---

## 🧹 Data Cleaning & Preparation

**Steps performed:**
- Removed rows with `Quantity <= 0` (returns/cancellations)
- Removed rows with `Price <= 0`
- Converted timestamps to weekly level
- Aggregated transactions into **weekly total demand**

**Why?**  
Forecasting must reflect **true customer demand**, not returns or accounting adjustments.

---

## 🛠️ Tech Stack

| Layer | Tools |
|-----|------|
| Cloud | Google Cloud Platform |
| Data Warehouse | BigQuery |
| ML | BigQuery ML |
| Language | SQL |
| Visualization | Power BI / Looker |
| Version Control | GitHub |

---

## 📐 Demand Analysis

- **Average weekly demand:** ~102K units  
- **Coefficient of Variation:** ~0.4  
  → Indicates moderate volatility and suitability for forecasting

Seasonal patterns observed during year-end and holiday periods.

---

## 📊 Baseline Forecast (Moving Average)

**Method:**

**Why this baseline?**
- Simple and interpretable
- Strong benchmark before ML

**Performance:**

| Metric | Value |
|------|------|
| MAE | ~19,900 |
| RMSE | ~28,800 |

---

## 🤖 Machine Learning Forecast (BigQuery ML)

**Model Used:** `ARIMA_PLUS`

**Capabilities:**
- Automatic seasonality detection
- Holiday effects
- Trend and volatility handling

**Findings:**
- Yearly seasonality detected
- Holiday demand spikes identified
- Improved forecast stability vs baseline

---

## 🔮 Forecast to Inventory Planning

Forecasts were converted into **inventory ranges**:

- **Expected Units:** Forecasted demand
- **Max Units to Stock:** Forecast + safety buffer
- **Min Units to Stock:** Forecast − safety buffer

This directly supports procurement and warehouse planning.

---

## 💼 Business Impact

### Value Delivered

- Reduced overstock risk
- Lower stockout probability
- Better cash flow planning
- Data-driven inventory decisions

### Real-World Usage

- Operations teams plan weekly stock
- Finance teams estimate inventory costs
- Supply chain teams prepare for demand spikes

---

## 📈 Dashboard Layer (Optional)

Forecast outputs can be visualized in:
- Power BI
- Looker Studio

Recommended visuals:
- Actual vs forecast demand
- Weekly trends
- Inventory buffer ranges

---

## 🏁 Project Outcome

- Built an end-to-end forecasting pipeline
- Compared baseline vs ML forecasts
- Converted predictions into inventory decisions
- Designed for real operational use

---

## 🚀 Key Learnings

- Forecasting matters only when tied to decisions
- Simple baselines are critical benchmarks
- ML enhances accuracy, business logic creates value
- BigQuery ML enables scalable, SQL-first forecasting

---

## 📌 Final Note

This project demonstrates:
- Advanced SQL
- Applied machine learning
- Strong business understanding
- Decision-focused analytics

A **production-style analytics project**, not a beginner exercise.

