# DataCo Supply Chain & Logistics Analytics

End-to-end analytics pipeline on a 180,519-row global supply chain dataset (2015–2018), covering data cleaning and feature engineering in Python, dimensional modeling and analytical SQL on SQL Server, and a 6-page executive Power BI dashboard. Built to mirror how a Big 4 data & analytics team would scope, model, and report on supply chain performance for a retail client.

**[Live Portfolio](https://manikantavejandla.netlify.app)** · **[LinkedIn](https://linkedin.com/in/manikanta1015)**

---

## Business Problem

A global retailer operating across five markets (Europe, LATAM, Pacific Asia, USCA, Africa) needed visibility into two linked questions: where is the business losing money, and where is it failing to deliver on time. This project answers both by building a governed data model and a dashboard that lets stakeholders move from headline KPIs down to the specific market, department, or shipping mode driving the result.

## Key Findings

- **Late delivery is systemic, not isolated.** 54.8% of all shipments arrive late, and every region exceeds a 45% late-risk threshold — this is a network-wide fulfillment issue, not a regional one.
- **Standard Class is the single biggest delivery bottleneck.** It carries the highest shipment volume and the highest share of late deliveries, while Same Day shipping has the lowest late rate.
- **Revenue and margin are concentrated.** Europe and LATAM generate the largest share of sales and profit, while Fan Shop and Apparel are the leading departments by revenue; Fitness, Outdoors, and Apparel deliver the strongest margins (>11%).
- **Discounting is eroding profit.** Orders with 0–10% discount generate the most total profit; profitability declines as discount depth increases.
- **33,784 orders (about 1 in 5) post a negative profit**, totaling a **$3.88M loss**, concentrated in the Fan Shop and Apparel departments and most pronounced in Europe and LATAM — the same markets driving the most revenue.
- **Order funnel leakage is measurable**: 4,062 orders are flagged as suspected fraud and 3,692 are canceled, both representing direct revenue leakage worth monitoring.

## Tech Stack

| Layer | Tools |
|---|---|
| Data Cleaning & EDA | Python, pandas, NumPy, Matplotlib, Seaborn |
| Database & Modeling | SQL Server (T-SQL), SQLAlchemy, star schema design |
| Analytics | Window functions, CTEs, BULK INSERT, indexing |
| Visualization | Power BI (DAX, bookmarks, drill-through, tooltip pages) |
| Export Pipeline | pandas → SQLAlchemy → SQL Server |

## Architecture

```
DataCoSupplyChainDataset.csv (180,519 rows, 53 columns)
        │
        ▼
01_load_clean.ipynb        →  drop PII/redundant columns, rename to snake_case,
                               fix datatypes, engineer delivery/profit/discount flags
        │
        ▼
02_eda.ipynb                →  8-section exploratory analysis with documented
                               business insights (delivery, sales, profit, segment,
                               funnel, loss investigation)
        │
        ▼
03_sql_export.ipynb         →  split cleaned data into star schema (3 dims + 1 fact),
                               push to SQL Server via SQLAlchemy
        │
        ▼
SQL Server (DataCoDB)       →  BULK INSERT load, PK/FK constraints, indexing,
                               20+ analytical queries, 1 reporting view
        │
        ▼
Power BI Dashboard          →  6 report pages + drill-through tooltip cards,
                               DAX measures, executive-ready visuals
```

## Data Model

A star schema with one fact table and three dimensions:

- **`fact_orders`** (180,519 rows) — order-item grain transactional table: sales, profit, discount, shipping dates, delivery flags, geography
- **`dim_customer`** (20,652 rows) — customer demographics and segment
- **`dim_product`** (118 rows) — product, category, and department hierarchy
- **`dim_date`** (1,127 rows) — calendar dimension for time intelligence

`fact_orders` references both `dim_customer` and `dim_product` via foreign keys. Indexes are applied on `market`, `delivery_status`, and `order_date` (each with relevant `INCLUDE` columns) to support the dashboard's most common filter and aggregation patterns.

## Project Structure

```
├── notebooks/
│   ├── 01_load_clean.ipynb       # Data cleaning, type fixes, feature engineering
│   ├── 02_eda.ipynb              # 8-part exploratory analysis with insights
│   └── 03_sql_export.ipynb       # Star schema construction + SQL Server export
├── sql/
│   ├── SQL_Data_load.sql         # DB/table DDL, BULK INSERT, indexing
│   └── SQL_Queries.sql           # 20+ analytical queries, 1 reporting view
├── dashboard/
│   └── DataCo_Supply_Chain_Dashboard.pbix
└── README.md
```

## Pipeline Walkthrough

### 1. Data Cleaning & Feature Engineering (`01_load_clean.ipynb`)
Loaded the raw 53-column Kaggle DataCo dataset and dropped PII and redundant fields (customer email/password/street, product description/image, duplicate ID columns). Standardized all column names to snake_case for SQL compatibility, converted order and shipping dates to proper datetime types, and engineered seven analytical fields directly used downstream in SQL and Power BI:

- `delivery_delay_days` — actual vs. scheduled shipping days (positive = late)
- `is_on_time` — binary on-time delivery flag
- `is_discounted` / `is_profitable` — binary flags for discounting and profitability
- `net_revenue` — sales net of item discount
- `processing_days` — order-to-ship duration
- Date parts (year, month, quarter, month name) for the calendar dimension

### 2. Exploratory Data Analysis (`02_eda.ipynb`)
Eight structured analyses, each closing with a written business insight rather than just a chart: delivery performance overview, shipping mode vs. late-delivery risk, monthly sales trend (2015–2018), sales by market, department profitability, discount impact on profit, customer segment analysis, and an order-status funnel that surfaces fraud and negative-profit orders for investigation.

### 3. Star Schema & SQL Server Export (`03_sql_export.ipynb`)
Split the cleaned flat file into one fact table and three dimension tables, generated a full calendar dimension via `pd.date_range`, and pushed all four tables to a local SQL Server instance using SQLAlchemy with the `mssql+pyodbc` driver.

### 4. SQL Server: Schema, Load & Analysis (`SQL_Data_load.sql`, `SQL_Queries.sql`)
Built the database and star schema with primary/foreign keys and check constraints, bulk-loaded all four CSVs, and added targeted nonclustered indexes. On top of that, wrote 20+ production-style queries covering monthly sales trend with running totals (window functions), shipping-mode profitability ranking, customer segment profitability with CTEs, YoY growth and 3-month rolling averages, late-delivery risk by market and payment type, and root-cause investigation of negative-profit orders by category and status. Also created a reusable `vw_delivery_performance` view for the delivery KPIs powering the dashboard.

### 5. Power BI Dashboard
A 6-page report — Executive Summary, Delivery Performance, Sales & Profit, Product & Department, Global Market Map, and Time Intelligence — backed by DAX measures for YTD/PYTD comparisons, MoM growth, and rolling averages, with drill-through tooltip cards for market and department-level detail.

| Page | Focus |
|---|---|
| Executive Summary | Total sales, profit, OTD rate, late-risk rate; monthly trend; sales/profit by market |
| Delivery Performance | Delivery status by shipping mode, scheduled vs. actual days, late-risk gauge, late % by region |
| Sales & Profit | Profit margin by department, discount band vs. profit, sales-vs-profit by category |
| Product & Department | Top 10 products by profit, department treemap, price-band distribution, category profitability table |
| Global Market Map | 3D market map, regional late-risk ranking, top customer countries by sales |
| Time Intelligence | YTD vs. PYTD with MoM growth, 3-month rolling average, YoY comparison, seasonal heatmap |

## How to Reproduce

1. Download the [DataCo Smart Supply Chain dataset](https://www.kaggle.com/datasets/shashwatwork/dataco-smart-supply-chain-for-big-data-analysis) and place `DataCoSupplyChainDataset.csv` in the project root.
2. Run `01_load_clean.ipynb` to produce `dataco_clean.csv`.
3. Run `02_eda.ipynb` to reproduce the exploratory analysis and charts.
4. Run `03_sql_export.ipynb` to generate the four star-schema CSVs and push them to SQL Server (update the SQLAlchemy connection string for your instance).
5. Run `SQL_Data_load.sql` to create the database, tables, and indexes, then bulk-load the CSVs (update file paths to match your environment).
6. Run the queries in `SQL_Queries.sql` to validate the model and reproduce the dashboard's underlying metrics.
7. Open `DataCo_Supply_Chain_Dashboard.pbix` in Power BI Desktop and point it at your SQL Server instance.

## Author

**Manikanta Vejandla** — Data Analyst
[LinkedIn](https://linkedin.com/in/manikanta1015) · [GitHub](https://github.com/ManikantaVejandla04) · [Portfolio](https://manikantavejandla.netlify.app) · vmanikanta1015@gmail.com
