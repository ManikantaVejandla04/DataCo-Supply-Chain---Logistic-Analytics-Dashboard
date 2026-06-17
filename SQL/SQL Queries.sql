use DataCoDB;

--  Delivery Performance Dashboard View
CREATE VIEW vw_delivery_performance AS
SELECT
    market,
    order_region,
    shipping_mode,
    delivery_status,
    COUNT(order_item_id) AS total_orders,
    SUM(sales) AS total_sales,
    SUM(order_profit) AS total_profit,
    ROUND(AVG(CAST(days_shipping_real AS FLOAT)), 2) AS avg_real_days,
    ROUND(AVG(CAST(days_shipping_scheduled AS FLOAT)),2) AS avg_sched_days,
    ROUND(AVG(CAST(delivery_delay_days AS FLOAT)), 2) AS avg_delay_days,
    ROUND(
        100.0 * SUM(is_on_time) / NULLIF(COUNT(*), 0), 1
    ) AS otd_rate_pct,
    ROUND(
        100.0 * SUM(late_delivery_risk)
              / NULLIF(COUNT(*), 0), 1
    ) AS late_risk_pct
FROM fact_orders
WHERE order_status != 'CANCELED'
GROUP BY market, order_region, shipping_mode, delivery_status;

-- Monthly Sales & Profit Trend (Window Function)
SELECT
    YEAR(order_date) AS yr,
    MONTH(order_date) AS mo,
    FORMAT(order_date, 'yyyy-MM') AS year_month,
    COUNT(DISTINCT order_id) AS order_count,
    ROUND(SUM(sales), 0) AS monthly_sales,
    ROUND(SUM(order_profit), 0) AS monthly_profit,
    ROUND(
        100.0 * SUM(order_profit) / NULLIF(SUM(sales), 0), 2
    ) AS profit_margin_pct,
    -- Running total
    SUM(SUM(sales)) OVER (
        PARTITION BY YEAR(order_date)
        ORDER BY MONTH(order_date)
        ROWS UNBOUNDED PRECEDING
    ) AS ytd_sales,
    -- MoM change
    LAG(SUM(sales)) OVER (ORDER BY YEAR(order_date), MONTH(order_date)) AS prev_month_sales
FROM fact_orders
WHERE order_status NOT IN ('CANCELED', 'SUSPECTED_FRAUD')
GROUP BY YEAR(order_date), MONTH(order_date), FORMAT(order_date,'yyyy-MM')
ORDER BY yr, mo;

-- Shipping Mode Profitability Comparison
SELECT
    shipping_mode,
    COUNT(order_item_id) AS total_orders,
    ROUND(SUM(sales), 0) AS total_sales,
    ROUND(SUM(order_profit), 0) AS total_profit,
    ROUND(AVG(CAST(days_shipping_real AS FLOAT)), 2) AS avg_days,
    ROUND(
        100.0 * SUM(is_on_time) / NULLIF(COUNT(*), 0), 1
    ) AS on_time_rate,
    ROUND(
        100.0 * COUNT(CASE WHEN delivery_status = 'Late delivery'
                            THEN 1 END)
              / NULLIF(COUNT(*), 0), 1
    ) AS late_rate_pct,
    RANK() OVER (ORDER BY SUM(order_profit) DESC) AS profit_rank
FROM fact_orders
GROUP BY shipping_mode
ORDER BY total_profit DESC;

-- Customer Segment Profitability (CTE Pattern)
WITH segment_stats AS (
    SELECT
        c.customer_segment,
        COUNT(DISTINCT f.customer_id) AS unique_customers,
        COUNT(DISTINCT f.order_id) AS total_orders,
        ROUND(SUM(f.sales), 0) AS total_sales,
        ROUND(SUM(f.order_profit), 0) AS total_profit,
        ROUND(AVG(f.sales), 2) AS avg_order_value,
        ROUND(AVG(f.item_discount_rate) * 100, 2) AS avg_discount_pct
    FROM fact_orders f
    JOIN dim_customer c ON f.customer_id = c.customer_id
    WHERE f.order_status = 'COMPLETE'
    GROUP BY c.customer_segment
),
totals AS (
    SELECT SUM(total_sales) AS grand_total FROM segment_stats
)
SELECT
    ss.*,
    ROUND(100.0 * ss.total_sales / t.grand_total, 1) AS revenue_share_pct,
    ROUND(
        100.0*ss.total_profit/NULLIF(ss.total_sales,0),2
    ) AS profit_margin_pct
FROM segment_stats ss
CROSS JOIN totals t
ORDER BY total_profit DESC;

-- Market & Region Performance
SELECT
    market,
    order_region,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(sales), 0) AS total_sales,
    ROUND(SUM(order_profit), 0) AS total_profit,
    ROUND(SUM(sales) * 100.0
        / SUM(SUM(sales)) OVER (), 2) AS market_share_pct,
    ROUND(
        100.0*SUM(CASE WHEN delivery_status='Late delivery'
                       THEN 1 ELSE 0 END)
             / NULLIF(COUNT(*),0), 1
    ) AS late_delivery_pct
FROM fact_orders
GROUP BY market, order_region
ORDER BY total_sales DESC;

-- Department sales & margin ranking
select
    p.department_name,
    sum(o.sales) as total_sales,
    sum(o.order_profit) as total_profit,
    round(
        sum(o.order_profit) * 100.0/nullif(sum(o.sales),0),2) as profit_margin_pct,
    rank() over(order by sum(o.order_profit) * 100.0/nullif(sum(o.sales),0) desc) as margin_rank
from dim_product p
join fact_orders o
on p.product_id=o.product_id
group by p.department_name
order by margin_rank;

-- Top 10 products by profit
select top 10
    p.product_name,
    sum(o.sales) as total_sales,
    sum(o.order_profit) as total_profit,
    avg(o.item_profit_ratio) as avg_proft_ratio
from dim_product p
join fact_orders o
on p.product_id=o.product_id
group by p.product_name
order by total_profit desc;

-- Discount rate vs profit analysis
select
    case
        when item_discount_rate = 0 then 'No Discount'
        when item_discount_rate <=0.10 then '0-10%'
        when item_discount_rate <=0.20 then '11-20%'
        when item_discount_rate <=0.30 then '21-30%'
        else '30%+'
    end as discount_bucket,
    avg(order_profit) as avg_profit,
    round(sum(case when order_profit>0 then 1 else 0 end) * 100.0/count(*) , 2) as profitable_order_pct
from fact_orders
group by 
    case
        when item_discount_rate = 0 then 'No Discount'
        when item_discount_rate <=0.10 then '0-10%'
        when item_discount_rate <=0.20 then '11-20%'
        when item_discount_rate <=0.30 then '21-30%'
        else '30%+'
    end
order by avg_profit desc;

-- Order status funnel
select
    order_status,
    count(*) as orders_count,
    sum(sales) as total_sales,
    sum(order_profit) as total_profit,
    round(count(*) * 100.0/sum(count(*)) over(),2) as percentage_of_orders
from fact_orders
group by order_status
having count(*)>0
order by orders_count desc;

-- Delivery delay by shipping mode
select 
    shipping_mode,
    avg(delivery_delay_days) as avg_delay_days,
    round(sum(case when is_on_time = 1 then 1 else 0 end) * 100.0/count(*) ,2) as on_time_pct,
    count(*) as total_orders
from fact_orders
group by shipping_mode
order by avg_delay_days desc;

-- Year-over-year sales growth
with yearly_sales as
(
    select
        d.year,
        sum(f.sales) as total_sales
    from fact_orders f
    join dim_date d
    on f.order_date=d.full_date
    group by d.year
)

select
    year,
    total_sales,
    lag(total_sales) over(order by year) as previous_year_sales,
    round((total_sales-lag(total_sales) over(order by year)) * 100.0/nullif(lag(total_sales) over(order by year), 0), 2) as growth_pct
from yearly_sales
order by year;

-- 3-month rolling average sales
with monthly_sales as
(
    select 
        year(order_date) as sales_year,
        month(order_date) as sales_month,
        sum(sales) as total_sales
    from fact_orders
    group by
        year(order_date),
        month(order_date)
)
select
    sales_year,
    sales_month,
    total_sales,
    round(avg(total_sales) over(order by sales_year, sales_month rows between 2 preceding and current row) ,2) as rolling_3_month_avg
from monthly_sales
order by sales_year, sales_month;

-- Payment Type vs Late Delivery Risk
select
    payment_type,
    count(*) as total_orders,
    sum(case when  late_delivery_risk = 1 then 1 else 0 end) as late_orders,
    round(sum(case when  late_delivery_risk = 1 then 1 else 0 end) * 100.0 / count(*), 2) as late_delivery_pct,
    SUM(sales) as total_sales
from fact_orders
group by payment_type
order by late_delivery_pct desc;

-- Late Risk Orders by Market & Shipping Mode
with risk_summary as
(
    select
        market,
        shipping_mode,
        count(*) as total_orders,
        sum(case when late_delivery_risk = 1 then 1 else 0 end) as late_orders
    from fact_orders
    group by
        market,
        shipping_mode
)
select
    market,
    shipping_mode,
    total_orders,
    late_orders,
    round(late_orders * 100.0 / nullif(total_orders,0),2) as late_risk_pct
from risk_summary
order by late_risk_pct desc;

-- Negative Profit Order Investigation
select
    p.category_name,
    o.order_status,
    count(*) as loss_orders,
    avg(o.item_discount_rate) as avg_discount_rate,
    sum(o.sales) as total_sales,
    sum(o.order_profit) as total_loss
from dim_product p
join fact_orders o
on p.product_id=o.product_id
where order_profit < 0
group by
    category_name,
    order_status
order by total_loss asc;

select @@SERVERNAME;

select * from dim_customer;

select * from dim_date;

select * from dim_product;

select * from fact_orders;