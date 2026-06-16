# Global Supply Chain & Logistics Analytics Engineering

An end-to-end data analytics and business intelligence project engineering a scalable data pipeline, relational database star schema, optimization views, and interactive multi-page Power BI dashboards to diagnose delivery risk performance and financial leakages for a global retail operation.

---

## 📊 Executive Dashboard Analytics
The presentation layer consists of an interactive corporate dashboard designed for regional directors and operational teams to evaluate baseline performance across logistics networks.

### 1. Delivery Performance & Logistics Dashboard
* **Purpose:** Provides a high-level tracking system for regional managers to audit delivery schedules and mitigate operational friction.
* **Key Features:** High-impact KPI blocks tracking total sales, total profit, total orders, and average delay timelines. Includes a regional map overlay visualizing order concentrations alongside a matrix showing real versus scheduled fulfillment timelines.

### 2. Financial Analytics & Trend Tracking
* **Purpose:** Offers finance leads visibility into net profitability patterns and rolling revenue adjustments over time.
* **Key Features:** Combined volume and margin trend lines mapping monthly historical timelines alongside specialized payment type breakdowns to trace the financial velocity of standard corporate billing loops.

### 3. Diagnostic Risk & Loss Deep-Dive
* **Purpose:** Empowers supply chain analysts to identify and address core financial leaks and fulfillment exceptions.
* **Key Features:** Uses an interactive Decomposition Tree to trace negative-margin products directly down to specific operational departments (e.g., Fan Shop, Apparel, Golf). Features a late-delivery risk heat matrix built to isolate problematic shipping classifications.

---

## 🏗️ Data Architecture & Star Schema Design
To transform raw flat-file transactional dumps into an efficient enterprise-grade warehouse environment, the transactional record was structurally decoupled into a clean **Star Schema** optimization structure (`DataCoDB`).

* **Fact Table:** `fact_orders` – Tracks quantitative pipeline measurements including transaction values, specific items, unit sales, margins, and operational risk metrics.
* **Dimension Tables:** * `dim_customer`: Unique identifier attributes, geographic regions, demographics, and buyer segmentation.
  * `dim_product`: Product catalog indexing, categories, base pricing, and departments.
  * `dim_date`: Time-intelligence metrics containing quarters, relative financial calendar months, weekly breakdowns, and weekend flag maps.

---

## 🛠️ Data Pipeline & Repository Workflow

### Step 1: Programmatic Profiling, ETL, & Transformation (`01_load_clean.ipynb`, `03_sql_export.ipynb`)
* Automated programmatic intake utilizing Python's ecosystem (**Pandas**, **NumPy**) to safely digest complex multi-encoded transactional histories.
* Evaluated null distributions and established deterministic clean records for column names, string structures, and spatial mappings.
* Programmatically structured relational tables out of high-order structures, outputting dimension files mapped precisely to downstream schema definitions.

### Step 2: Diagnostic Exploratory Analysis (`02_eda (1).ipynb`)
* Derived foundational performance baselines across internal supply channels using **Seaborn** and **Matplotlib**.
* Diagnosed macro failure trends—exposing that over half of operational orders breached initial delivery schedules, pointing toward a significant logistical gap.
* Conducted diagnostic grouping routines to classify negative-margin products across enterprise departments.

### Step 3: Relational Schema DDL & Bulk Ingestion Pipeline (`SQL Data load.sql`)
* Implemented the target schema directly into Microsoft SQL Server with strict DDL configurations, establishing explicitly typed primary key restrictions and check parameters (`CHECK BETWEEN 1 AND 12` bounds for relational calendar months).
* Utilized raw engine query architectures (**BULK INSERT**) to stream pre-processed dimension files cleanly from local drives.
* Optimized pipeline ingestion safety by setting up transaction segment bounds (`BATCHSIZE = 10000`), reducing transactional log footprint and avoiding runtime engine freezes.

### Step 4: Enterprise Analytical Engineering (`SQL Queries.sql`)
* Developed enterprise views (`vw_delivery_performance`) to calculate on-time rates (OTD%), absolute delay durations, and ongoing fulfillment failure probabilities.
* Wrote financial window frameworks (`SUM(SUM(sales)) OVER(...)`) to calculate rolling annual performance trajectories and track shifting regional profit margins.
* Implemented conditional grouping scripts to systematically audit negative returns, isolating problematic inventory lines and pricing structures.

### Step 5: Executive Power BI Dashboard Development
* Connected the optimized SQL database to **Power BI Desktop** via import models to assemble a responsive analytics environment.
* Authored custom **DAX** measures to populate metrics for total transactions, shipping variations, and conditional formatting parameters.
* Deployed **Decomposition Trees** and custom data-bars inside matrices to give business stakeholders immediate root-cause clarity regarding supply chain friction.

---

## 📈 Strategic Business Insights Drafted From Database Assets
1. **Logistics Bottlenecks:** Standard and First-Class transportation systems display high overall baseline delay frequencies. In particular, First-Class delivery mechanisms maintain severe baseline delay liabilities, highlighting a need for contractual service-level validation or re-routing strategies.
2. **Margin Protection:** Diagnostic auditing via the Power BI decomposition trees reveals deep baseline net losses centered around specific product segments like **Fan Shop, Apparel, and Golf**, calling for automated promotional modifications, dynamic cost structures, or baseline asset adjustments.
3. **Fulfillment Failures:** Clear variations exist in on-time delivery rates (OTD%) across global distribution networks, indicating opportunities to adopt localized inventory positioning strategies to shield critical consumer blocks.

---

## 💻 Tech Stack Implemented
* **Languages:** Python (v3.9+), SQL (T-SQL/MS SQL Server)
* **Libraries:** Pandas, NumPy, SQLAlchemy, Matplotlib, Seaborn
* **Data Architecture:** Relational Warehousing, Dimensional Star Schema Design, View Optimization
* **BI Presentation Layer:** Microsoft Power BI (DAX, Interactive Decomposition Tree, Data Bars, Matrix Views)

---

## 🚀 Execution & Verification
To spin up this architecture on your local environment:
1. Clone this repository to your processing directory.
2. Run notebooks `01_load_clean.ipynb` through `03_sql_export.ipynb` within your local data space to clean, refine, and generate your schema dimensions.
3. Execute `SQL Data load.sql` inside your MS SQL Server instance to build out your core infrastructure and populate the database assets.
4. Run `SQL Queries.sql` to instantiate analytical optimization frameworks and export reporting insight metrics.
5. Open the provided `.pbix` template file inside Power BI to view, filter, and interact with the executive supply chain analysis layers.
