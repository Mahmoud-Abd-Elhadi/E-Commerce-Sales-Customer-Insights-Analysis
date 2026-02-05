/*
================================================================================
File Name   : 02_sales_and_revenue_analysis.sql
Project     : E-Commerce Data Analysis Portfolio
Database    : [ecommerce]
================================================================================

DESCRIPTION:
------------
This script focuses on the financial health of the business. It analyzes revenue streams,
profit margins, order economics, and sales trends to provide actionable insights 
for financial and operational decision-making.

TABLE OF CONTENTS (KEY BUSINESS QUESTIONS):
-------------------------------------------
1. Executive Summary (Financial Health):
   - What is the total revenue, gross profit, and profit margin?
   - What is the overall volume of successful vs. returned orders?

2. Growth Trends & Seasonality:
   - How is revenue trending Year-over-Year (YoY)?
   - What are the peak months and best-performing days?

3. Order Economics:
   - What is the Average Order Value (AOV)?
   - How does revenue split between low, mid, and high-value orders?

4. Profitability & Channel Efficiency:
   - Which marketing channels generate the highest revenue and AOV?
   - Which product categories drive the most profit?
   - How much revenue is lost due to returns?

5. Bonus Insights (Geography & Quality Control):
   - Which countries generate the most revenue?
   - Which product categories have the highest return rates?

6. Advanced Analytics (Window Functions):
   - How is revenue accumulating over time (Running Total)?
================================================================================
*/

-- =============================================================================
-- PART 1: FINANCIAL METRICS (Revenue, Profit, Margin)
-- Includes: Total Revenue, Gross Profit, Gross Profit Margin
-- =============================================================================

SELECT
	
	ROUND(SUM(EFOI.sale_price) , 2) AS total_revenue ,

 	ROUND(SUM(EFOI.sale_price - EDP.cost) , 2) AS gross_profit ,

	CONCAT(ROUND(SUM(EFOI.sale_price - EDP.cost) / SUM(EFOI.sale_price) * 100 , 2) , '%') AS gross_profit_margin

FROM [ecommerce].[fact_order_items] AS EFOI
JOIN [ecommerce].[dim_products]     AS EDP
ON EFOI.product_id = EDP.id
WHERE [status] = 'complete'
 
-- =============================================================================
-- PART 2: ORDER STATUS METRICS (Successful, Returned, Cancelled)
-- Includes: Total Number of Orders by Status
-- =============================================================================
 SELECT

	COUNT( DISTINCT
			CASE
				WHEN status = 'Complete' Then order_id
			END 
	) AS successful_orders ,

	COUNT( DISTINCT
			CASE
				WHEN status = 'Returned' Then order_id
			END
	) AS returned_orders ,

	COUNT( DISTINCT
			CASE
				WHEN status = 'Cancelled' THEN order_id
			END
	) AS cancelled_orders
FROM [ecommerce].[fact_order_items]

-- =============================================================================
-- SECTION 2: GROWTH TRENDS & SEASONALITY (Time Analysis)
-- =============================================================================
-- 1. Year-over-Year (YoY) Growth
SELECT
	YEAR(created_at)		   AS sales_year ,
	COUNT(DISTINCT order_id)   AS total_orders ,
	ROUND(SUM(sale_price) , 2) AS total_revenue 
FROM [ecommerce].[fact_order_items]
WHERE [status] = 'complete'
GROUP BY YEAR(created_at)
ORDER BY SUM(sale_price) DESC

-- 2. Monthly Seasonality (The "Best Month" Analysis)
SELECT
	MONTH(created_at)			 AS month_number , 
	DATENAME(MONTH , created_at) AS sales_month ,
	COUNT(DISTINCT order_id)     AS total_orders ,
	ROUND(SUM(sale_price) , 2)   AS total_revenue 
FROM [ecommerce].[fact_order_items]
WHERE [status] = 'complete'
GROUP BY MONTH(created_at) , DATENAME(MONTH , created_at)
ORDER BY MONTH(created_at)

-- 3. Day of Week Analysis (Best Days)
SELECT 
	DATENAME(WEEKDAY , created_at) AS order_day ,
	COUNT(DISTINCT order_id)       AS total_orders ,
	ROUND(SUM(sale_price) , 2)     AS total_revenue
FROM [ecommerce].[fact_order_items]
WHERE [status] = 'complete'
GROUP BY DATENAME(WEEKDAY , created_at)
ORDER BY total_revenue DESC

-- 4. Monthly Trend (Timeline)
SELECT
	YEAR(created_at)			   AS sales_year ,
	DATENAME(MONTH , created_at)   AS sales_month ,
	COUNT(DISTINCT order_id)       AS total_orders ,
	ROUND(SUM(sale_price) , 2)     AS total_revenue
FROM [ecommerce].[fact_order_items]
WHERE [status] = 'complete'
GROUP BY YEAR(created_at) , DATENAME(MONTH , created_at) 
ORDER BY sales_year , sales_month

-- =============================================================================
-- SECTION 3: ORDER ECONOMICS (AOV & Basket Size)
-- =============================================================================

/* 1. Average Order Value (AOV)
   -----------------------------------------------
   (AOV = Total Revenue / Total Number of Orders)
*/
SELECT
	ROUND(SUM(sale_price) / COUNT(DISTINCT order_id) , 2) AS average_order_value
FROM [ecommerce].[fact_order_items]
WHERE [status] = 'complete'


/* 2. Average Basket Size (Items per Order)
   How many items does a customer buy per order? 
*/
SELECT
	 ROUND(CAST(COUNT(product_id) AS FLOAT) / CAST(COUNT(DISTINCT order_id) AS FLOAT) , 2)
FROM [ecommerce].[fact_order_items]
WHERE [status] = 'complete'

/* 3. Order Value Segmentation (Low vs Mid vs High)
   How does revenue split between small, medium, and large orders?
*/

SELECT
	order_segment ,
	COUNT(order_segment) AS total_orders ,
	ROUND(SUM(order_total) , 2) AS total_revenue
FROM (
		SELECT
			order_id ,
			SUM(sale_price) AS order_total ,
			CASE
				WHEN SUM(sale_price) > 870 THEN 'High value'
				WHEN SUM(sale_price) > 440 THEN 'Mid value'
				ELSE 'Low value'
			END order_segment
		FROM [ecommerce].[fact_order_items]
		WHERE [status] = 'complete'
		GROUP BY order_id
) AS T
GROUP BY order_segment


-- =============================================================================
-- SECTION 4: PROFITABILITY & CHANNEL EFFICIENCY
-- =============================================================================

/* 1. Traffic Source Performance (Revenue & AOV)
   -----------------------------------------------
   Which marketing channel brings the most money? (Total Revenue)
   Which channel brings the "richest" customers? (Highest AOV)
*/
SELECT 
	EDU.traffic_source ,
	COUNT(EDU.id) AS total_user,
	COUNT(DISTINCT EFOI.order_id) AS total_orders ,
	ROUND(SUM(EFOI.sale_price) , 2) AS total_revenue,
	ROUND(SUM(EFOI.sale_price) / COUNT(DISTINCT EFOI.order_id) , 2) AS avg_order_value
FROM [ecommerce].[fact_order_items] AS EFOI
JOIN [ecommerce].[dim_users]        AS EDU
ON EFOI.user_id = EDU.id
WHERE [status] = 'complete'
GROUP BY EDU.traffic_source
ORDER BY total_revenue DESC

/* 2. Revenue & Profit by Product Category
   (Revenue vs Profitability per Category)
*/

SELECT
	EDP.category ,
	ROUND(SUM(sale_price) , 2) AS total_revenue ,
	ROUND(SUM(EFOI.sale_price - EDP.cost) , 2) AS gross_profit ,
	CONCAT(ROUND((SUM(EFOI.sale_price - EDP.cost) / SUM(EFOI.sale_price)) * 100 , 1) , '' , '%') AS gross_profit_margin
FROM [ecommerce].[fact_order_items] AS EFOI
JOIN [ecommerce].[dim_products]     AS EDP
ON EFOI.product_id = EDP.id
WHERE [status] = 'complete'
GROUP BY EDP.category
ORDER BY total_revenue DESC;

/* 3. Lost Revenue Due to Returns
   How much potential revenue evaporated due to returns? 
*/

SELECT 
	YEAR(created_at) AS return_year ,
	COUNT(DISTINCT order_id) AS returned_orders ,
	ROUND(SUM(sale_price) , 2) AS lost_revenue
FROM [ecommerce].[fact_order_items]
WHERE [status] = 'Returned'
GROUP BY YEAR(created_at)
ORDER BY return_year


-- =============================================================================
-- SECTION 5: Geographic Performance , 
-- =============================================================================

/* 1. Geographic Performance (Where is the money coming from?)
   -----------------------------------------------
   Which countries generate the most revenue? 
*/

SELECT * FROM [ecommerce].[fact_order_items]
SELECT * FROM [ecommerce].[dim_users]

SELECT TOP 10
	EDU.country ,
	COUNT(DISTINCT EFOI.order_id) AS total_orders ,
	ROUND(SUM(EFOI.sale_price) , 2) AS total_revenue
FROM [ecommerce].[fact_order_items] AS EFOI
JOIN [ecommerce].[dim_users]        AS EDU
ON EFOI.[user_id] = EDU.id
WHERE EFOI.[status] = 'complete'
GROUP BY country
ORDER BY total_revenue DESC

/* 2. Return Rate by Category (Quality Control) 
   -----------------------------------------------
   Which product category has the highest return rate? 
*/

SELECT * FROM [ecommerce].[fact_order_items]

SELECT
	EDP.category ,
	COUNT( DISTINCT 
	CASE
		WHEN EFOI.[status] = 'Complete' THEN EFOI.order_id
	END ) AS complete_orders,

	COUNT( DISTINCT
	CASE
		WHEN EFOI.[status] = 'Returned' THEN EFOI.order_id
	END ) AS returned_orders ,

	CONCAT(
	ROUND(
	(CAST(COUNT(DISTINCT CASE WHEN EFOI.[status] = 'Returned' THEN EFOI.order_id END) AS FLOAT) /
	CAST(COUNT(DISTINCT EFOI.order_id)AS FLOAT)) * 100
	, 2) 
	,'','%')AS return_rate

FROM [ecommerce].[fact_order_items] AS EFOI
JOIN [ecommerce].[dim_products]     AS EDP
ON EFOI.product_id = EDP.id
GROUP BY EDP.category
ORDER BY return_rate

-- =============================================================================
-- SECTION 6: Cumulative Revenue (Window Functions)
-- =============================================================================

/* Cumulative Revenue (Running Total)
   How is our revenue accumulating over time?  
*/

WITH Monthly_Revenue AS
(
	SELECT 
		YEAR(created_at) AS sales_year ,
		MONTH(created_at) AS sales_month ,
		ROUND(SUM(sale_price) , 2) AS monthly_revenue
	FROM [ecommerce].[fact_order_items]
	WHERE [status] = 'complete'
	GROUP BY YEAR(created_at) , MONTH(created_at)
)

SELECT
	sales_year ,
	sales_month ,
	monthly_revenue ,
	SUM(monthly_revenue) OVER(PARTITION BY sales_year ORDER BY sales_month) AS running_total_revenue
FROM Monthly_Revenue
