IF NOT EXISTS (
    SELECT name FROM sys.databases WHERE name = 'DataCoDB'
)
CREATE DATABASE DataCoDB;
GO

USE DataCoDB;
GO


SELECT DB_NAME() AS current_db;

-- Drop in reverse order if re-running
IF OBJECT_ID('dbo.fact_orders',  'U') IS NOT NULL DROP TABLE dbo.fact_orders;
IF OBJECT_ID('dbo.dim_customer', 'U') IS NOT NULL DROP TABLE dbo.dim_customer;
IF OBJECT_ID('dbo.dim_product',  'U') IS NOT NULL DROP TABLE dbo.dim_product;
IF OBJECT_ID('dbo.dim_date',     'U') IS NOT NULL DROP TABLE dbo.dim_date;
GO

-- ── 1. dim_date ────────────────────────────────────────────
CREATE TABLE dbo.dim_date (
    date_key    INT           NOT NULL PRIMARY KEY,
    full_date   DATE          NOT NULL,
    year        INT           NOT NULL,
    quarter     INT           CHECK (quarter BETWEEN 1 AND 4),
    month       INT           CHECK (month BETWEEN 1 AND 12),
    month_name  VARCHAR(12),
    week_num    INT,
    day_of_week VARCHAR(12),
    is_weekend  INT       DEFAULT 0
);

-- ── 2. dim_product ─────────────────────────────────────────
CREATE TABLE dbo.dim_product (
    product_id          INT            NOT NULL PRIMARY KEY,
    product_name        VARCHAR(150)   NOT NULL,
    product_price       DECIMAL(10,4),
    product_category_id INT,
    category_id         INT,
    category_name       VARCHAR(80),
    department_id       INT,
    department_name     VARCHAR(60)
);

-- ── 3. dim_customer ────────────────────────────────────────
CREATE TABLE dbo.dim_customer (
    customer_id      INT          NOT NULL PRIMARY KEY,
    customer_fname   VARCHAR(60)  NOT NULL,
    customer_lname   VARCHAR(60),
    customer_segment VARCHAR(30),
    customer_city    VARCHAR(80),
    customer_state   VARCHAR(80),
    customer_country VARCHAR(80)
);

-- ── 4. fact_orders ─────────────────────────────────────────
CREATE TABLE dbo.fact_orders (
    order_item_id           INT             NOT NULL PRIMARY KEY,
    order_id                INT             NOT NULL,
    customer_id             INT             REFERENCES dbo.dim_customer(customer_id),
    product_id              INT             REFERENCES dbo.dim_product(product_id),
    order_date              DATETIME,
    shipping_date           DATETIME,
    payment_type            VARCHAR(20),
    order_status            VARCHAR(30),
    delivery_status         VARCHAR(30),
    shipping_mode           VARCHAR(30),
    market                  VARCHAR(30),
    order_region            VARCHAR(60),
    order_country           VARCHAR(80),
    order_city              VARCHAR(80),
    order_state             VARCHAR(80),
    latitude                DECIMAL(12,7),
    longitude               DECIMAL(12,7),
    days_shipping_real      INT,
    days_shipping_scheduled INT,
    late_delivery_risk      TINYINT,
    delivery_delay_days     INT,
    is_on_time              TINYINT,
    item_quantity           INT,
    sales                   DECIMAL(10,4),
    item_discount           DECIMAL(10,4),
    item_discount_rate      DECIMAL(8,6),
    order_item_total        DECIMAL(10,4),
    order_profit            DECIMAL(10,4),
    item_profit_ratio       DECIMAL(8,6),
    net_revenue             DECIMAL(10,4),
    is_profitable           TINYINT,
    is_discounted           TINYINT,
    processing_days         INT
);
GO

-- Verify tables were created
SELECT name, create_date
FROM sys.tables
WHERE type = 'U'
ORDER BY create_date;
-- Should show: dim_date, dim_product, dim_customer, fact_orders

-- ── IMPORT 1: dim_date (1,127 rows) ───────────────────────
BULK INSERT dbo.dim_date
FROM 'D:\SC & LA\Data\dim_date.csv'
WITH (
    FIELDTERMINATOR  = ',',
    ROWTERMINATOR    = '\n',
    FIRSTROW         = 2,        -- skip header row
    TABLOCK,
    CODEPAGE         = '65001'   -- UTF-8
);
PRINT 'dim_date loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
GO

-- ── IMPORT 2: dim_product (118 rows) ──────────────────────
BULK INSERT dbo.dim_product
FROM 'D:\SC & LA\Data\dim_product.csv'
WITH (
    FIELDTERMINATOR  = ',',
    ROWTERMINATOR    = '\n',
    FIRSTROW         = 2,
    TABLOCK,
    CODEPAGE         = '65001'
);
PRINT 'dim_product loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
GO

-- ── IMPORT 3: dim_customer (20,652 rows) ──────────────────
BULK INSERT dbo.dim_customer
FROM 'D:\SC & LA\Data\dim_customer.csv'
WITH (
    FIELDTERMINATOR  = ',',
    ROWTERMINATOR    = '\n',
    FIRSTROW         = 2,
    TABLOCK,
    CODEPAGE         = '65001'
);
PRINT 'dim_customer loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
GO

-- ── IMPORT 4: fact_orders (180,519 rows) ──────────────────
BULK INSERT dbo.fact_orders
FROM 'D:\SC & LA\Data\fact_orders.csv'
WITH (
    FIELDTERMINATOR  = ',',
    ROWTERMINATOR    = '\n',
    FIRSTROW         = 2,
    TABLOCK,
    CODEPAGE         = '65001',
    BATCHSIZE        = 10000   -- commit every 10K rows (safer for large file)
);
PRINT 'fact_orders loaded: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows';
GO

SELECT 'dim_date'     AS table_name, COUNT(*) AS row_count FROM dbo.dim_date
UNION ALL
SELECT 'dim_product'  AS table_name, COUNT(*) AS row_count FROM dbo.dim_product
UNION ALL
SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM dbo.dim_customer
UNION ALL
SELECT 'fact_orders'  AS table_name, COUNT(*) AS row_count FROM dbo.fact_orders;

CREATE NONCLUSTERED INDEX IX_fact_market
    ON fact_orders(market) INCLUDE (sales, order_profit);
CREATE NONCLUSTERED INDEX IX_fact_delivery
    ON fact_orders(delivery_status) INCLUDE (days_shipping_real, is_on_time);
CREATE NONCLUSTERED INDEX IX_fact_date
    ON fact_orders(order_date) INCLUDE (sales, order_profit, order_status);