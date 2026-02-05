/*
================================================================================
File Name   : 05_product_inventory_analysis.sql
Project     : E-Commerce Data Analysis Portfolio
Database    : [ecommerce]
================================================================================

DESCRIPTION:
------------
This comprehensive script analyzes the "Product & Supply Chain" side of the business.
It moves beyond simple sales counts to evaluate profitability, product affinity, 
quality control, and logistics efficiency.

KEY BUSINESS QUESTIONS ADDRESSED:
---------------------------------
1. Product Performance:
   - What are our top-performing products by revenue and volume?
   
2. Quality Control (Returns):
   - Which products suffer from high return rates? (Identifying quality issues).

3. Cross-Selling Strategies (Market Basket Analysis):
   - Which products are frequently bought together? (For bundles & recommendations).

4. Profitability Analysis:
   - Which categories generate the highest profit margins? (Revenue vs. Cost).

5. Inventory & Logistics:
   - How is the workload distributed across our distribution centers?
   - How fast and reliable is our shipping process (Time-to-Ship & Late Rates)?
================================================================================
*/


-- =============================================================================
-- SECTION 1: PRODUCT PERFORMANCE (Best Sellers)
-- =============================================================================

/* 1. Top 10 Products by Revenue
   -----------------------------------------------
   Which specific products generate the most money?
   (We should ensure these are always in stock).
*/

SELECT TOP 10
	EDP.[id] AS product_id ,
	EDP.[name] AS product_name,
	EDP.category ,
	COUNT(EFOI.order_id) AS total_units_sold ,
	ROUND(SUM(EFOI.sale_price) , 2) AS total_revenue
FROM [ecommerce].[fact_order_items] AS EFOI
JOIN [ecommerce].[dim_products]     AS EDP
ON EFOI.product_id = EDP.id
WHERE EFOI.[status] = 'complete'
GROUP BY EDP.[id] , EDP.[name] , EDP.category
ORDER BY total_revenue DESC


-- =============================================================================
-- SECTION 2: PRODUCT QUALITY (High Return Rates)
-- =============================================================================

/* 2. Products with Highest Return Rate (Min. 50 sales) 
   -----------------------------------------------
   Which products are frequently returned by customers?
   (High return rate indicates poor quality or misleading description).
   *Filter: Only look at products with at least 50 sales to avoid statistical noise.
*/

WITH return_data as
(
SELECT
	EDP.[id] AS product_id ,
	EDP.[name] AS product_name,
	EDP.category ,

	COUNT(
			CASE
				WHEN EFOI.[status] = 'Returned' THEN EFOI.product_id
			END  ) AS returned_count ,

	COUNT(
			CASE
				WHEN EFOI.[status] IN ('Returned' , 'Complete') THEN EFOI.product_id
			END)   AS total_sold ,

	ROUND(
		(CAST(COUNT(CASE WHEN EFOI.[status] = 'Returned' THEN EFOI.product_id END) AS FLOAT) /
		CAST(NULLIF(COUNT(CASE WHEN EFOI.[status] IN ('Returned' , 'Complete') THEN EFOI.product_id END) ,0) AS FLOAT)) * 100
	, 2) AS return_rate_pct
FROM [ecommerce].[fact_order_items] AS EFOI
JOIN [ecommerce].[dim_products]     AS EDP
ON EFOI.product_id = EDP.id 
GROUP BY EDP.[id]  ,
		 EDP.[name] ,
	     EDP.category
)

SELECT TOP 10
	product_id ,
	product_name ,
	category ,
	returned_count ,
	total_sold,
	CONCAT(return_rate_pct , '%') AS return_rate_pct
FROM return_data
ORDER BY return_rate_pct DESC


-- =============================================================================
-- SECTION 3: MARKET BASKET ANALYSIS (Cross-Selling Strategies)
-- =============================================================================

/* 3. Frequently Bought Together (Affinity Analysis)
   -----------------------------------------------
   Which products are frequently purchased in the same transaction?
    "Customers who bought X also bought Y").
*/

SELECT TOP 10
	EDP1.[name] ,
	EDP2.[name] ,
	COUNT(*) AS Times_Bought_Together
FROM [ecommerce].[fact_order_items] AS EFOI1
JOIN [ecommerce].[fact_order_items] AS EFOI2
	ON EFOI1.order_id = EFOI2.order_id
		AND EFOI1.product_id < EFOI2.product_id
JOIN [ecommerce].[dim_products]     AS EDP1
	ON EFOI1.product_id = EDP1.id
JOIN [ecommerce].[dim_products]     AS EDP2
	ON EFOI2.product_id = EDP2.id
GROUP BY EDP1.[name] ,
		 EDP2.[name]
ORDER BY Times_Bought_Together DESC


--==> Another Way
SELECT TOP 10
	EDP1.[name] ,
	EDP2.[name] ,
	COUNT(*) AS Times_Bought_Together
FROM [ecommerce].[fact_order_items] AS EFOI1
JOIN [ecommerce].[dim_products]     AS EDP1
	ON EFOI1.product_id = EDP1.id
JOIN [ecommerce].[fact_order_items] AS EFOI2
	ON EFOI1.order_id = EFOI2.order_id
JOIN [ecommerce].[dim_products]     AS EDP2
	ON EFOI2.product_id = EDP2.id
WHERE EFOI1.product_id < EFOI2.product_id
GROUP BY EDP1.[name] ,
	     EDP2.[name]
ORDER BY Times_Bought_Together DESC 

-- =============================================================================
-- SECTION 4: PROFITABILITY ANALYSIS (Margins by Category)
-- =============================================================================

/* 4. Profit Margin by Product Category
   ------------------------------------
   Which specific categories are driving our profitability?
   (Revenue is vanity, Profit is sanity. We need to know what actually makes money).
*/

SELECT 
	EDP.category ,
	ROUND(SUM(EFOI.sale_price) ,2) AS total_revenue ,
	ROUND(SUM(EDP.cost) ,2) AS total_cost ,
	ROUND(SUM(EFOI.sale_price - EDP.cost) ,2) AS total_profit,
	CONCAT(
		ROUND(
			(CAST(SUM(EFOI.sale_price - EDP.cost) AS FLOAT) / CAST(SUM(EFOI.sale_price) AS FLOAT)) * 100 
		, 2)  
	, '%') AS profit_margin_pct
FROM [ecommerce].[fact_order_items] AS EFOI 
JOIN [ecommerce].[dim_products]     AS EDP
ON EFOI.product_id = EDP.id
WHERE [status] = 'complete'
GROUP BY EDP.category
ORDER BY total_profit DESC

-- =============================================================================
-- SECTION 5: INVENTORY & LOGISTICS (Distribution Centers)
-- =============================================================================

/* 5. Performance by Distribution Center
   -------------------------------------
   Business Question: 
   Which distribution center handles the most volume?
   (Helps in resource allocation and inventory planning).
*/

SELECT * FROM [ecommerce].[dim_products]
SELECT * FROM [ecommerce].[fact_order_items]
SELECT * FROM [ecommerce].[dim_distribution_centers]
 
SELECT 
	EDDC.[name] AS distribution_center_name,
	COUNT(EFOI.product_id) AS total_items_sold ,
	ROUND(SUM(EFOI.sale_price) , 2) AS total_revenue_generated ,
	COUNT(DISTINCT EFOI.product_id) AS unique_products_stocked ,
	CONCAT(
        ROUND(
            (CAST(COUNT(DISTINCT EFOI.product_id) AS FLOAT) / 
             NULLIF(CAST(COUNT(EFOI.product_id) AS FLOAT), 0)) * 100
        , 2)
    , '%') AS variety_rate_pct
FROM [ecommerce].[fact_order_items] AS EFOI
JOIN [ecommerce].[dim_products]     AS EDP
ON EFOI.product_id = EDP.id 
JOIN [ecommerce].[dim_distribution_centers] AS EDDC
ON EDP.distribution_center_id = EDDC.id
WHERE EFOI.[status] = 'Complete'
GROUP BY EDDC.[name]
ORDER BY total_items_sold DESC

-- =============================================================================
-- SECTION 6: LOGISTICS PERFORMANCE (Shipping Efficiency)
-- =============================================================================

/* 6. Distribution Centers Speed & Reliability Analysis 
   - Which distribution centers are the most efficient? 
   -.. Late Shipping Rate (Reliability): Percentage of orders taking > 3 days to process.
*/
SELECT
	EDDC.name ,
	COUNT(DISTINCT EFOI.order_id) orders_shipped ,
	ROUND(AVG(CAST(DATEDIFF(DAY , EFOI.created_at , EFOI.shipped_at) AS FLOAT)) ,2) AS avg_days_to_ship ,
	CONCAT(
		ROUND(
 			(CAST(COUNT(CASE WHEN DATEDIFF(DAY , EFOI.created_at , EFOI.shipped_at) > 3 THEN EFOI.order_id END) AS FLOAT) /
			CAST(COUNT(EFOI.order_id) AS FLOAT)) * 100 
		, 2) 
	, '%') AS late_shipping_rate
FROM [ecommerce].[fact_order_items] AS EFOI
JOIN [ecommerce].[dim_products]     AS EDP
ON EFOI.product_id = EDP.id 
JOIN [ecommerce].[dim_distribution_centers] AS EDDC
ON EDP.distribution_center_id = EDDC.id
WHERE EFOI.shipped_at IS NOT NULL
GROUP BY EDDC.name
