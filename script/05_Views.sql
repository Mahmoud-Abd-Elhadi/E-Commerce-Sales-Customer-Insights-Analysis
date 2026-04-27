/*
================================================================================
Project      : The Look Ecommerce - Data Modeling & Advanced Analytics
File Name    : powerbi_optimized_views.sql
Description  : This script creates optimized SQL Views for Power BI.
               These views are designed to maintain relationships (Star Schema)
               while offloading complex logic to the SQL Server for better performance.
================================================================================
*/

USE The_Look_Ecommerce;
GO

-- =============================================================================
-- SECTION 1: ORDER VALUE SEGMENTATION
-- Business Question: How is revenue distributed between high, mid, and low-value orders?
-- =============================================================================

IF OBJECT_ID('vw_Order_Segments', 'V') IS NOT NULL 
    DROP VIEW vw_Order_Segments;
GO

	CREATE VIEW vw_Order_Segments
	AS
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

GO
-- =============================================================================
-- SECTION 2: USER CONVERSION SPEED (TIME TO FIRST PURCHASE)
-- Business Question: How long does it take for a new user to make their first purchase?
-- =============================================================================

IF OBJECT_ID('vw_User_Conversion_Speed', 'V') IS NOT NULL 
	DROP VIEW vw_User_Conversion_Speed;
GO

	CREATE VIEW vw_User_Conversion_Speed
    AS
	WITH Calc_Purchase_Latency AS
	(
			SELECT
				EDU.id ,
				CONCAT(EDU.first_name , ' ' , EDU.last_name) AS full_name ,
				EDU.country ,
				DATEDIFF(DAY , MIN(EDU.created_at) , MIN(EFOI.created_at)) AS days_until_first_purchase
			FROM [ecommerce].[fact_order_items] AS EFOI
			JOIN [ecommerce].[dim_users]		AS EDU
			ON EFOI.[user_id] = EDU.id
			WHERE [status] = 'complete'
			GROUP BY EDU.id ,
					 CONCAT(EDU.first_name , ' ' , EDU.last_name)  ,
					 EDU.country
	)

		SELECT
			* ,
			CASE
				WHEN days_until_first_purchase = 0 THEN 'Same Day'
				WHEN days_until_first_purchase BETWEEN 0 AND 365 THEN '1st Year'
				WHEN days_until_first_purchase BETWEEN 366 AND 730 THEN '2nd Year'
				WHEN days_until_first_purchase BETWEEN 731 AND 1095 THEN '3nd Year'
				WHEN days_until_first_purchase BETWEEN 1096 AND 1460 THEN '4nd Year'
				ELSE '5nd Year'
			END purchase_speed_segment
		FROM Calc_Purchase_Latency 

GO
-- =============================================================================
-- SECTION 3: ADVANCED CUSTOMER SEGMENTATION (RFM)
-- Business Question: Identifying VIPs, Loyalists, and At-Risk customers.
-- =============================================================================

IF OBJECT_ID('vw_Customer_RFM_Segments', 'V') IS NOT NULL 
	DROP VIEW vw_Customer_RFM_Segments;
GO

	CREATE VIEW vw_Customer_RFM_Segments 
	AS 
	WITH RFM_Base AS (
		SELECT 
			[user_id],
			MAX(created_at) AS last_order_date,
			COUNT(DISTINCT order_id) AS frequency,
			SUM(sale_price) AS monetary,
			DATEDIFF(DAY, MAX(created_at), (SELECT MAX(created_at) FROM ecommerce.fact_order_items)) AS recency_days
		FROM ecommerce.fact_order_items
		WHERE status = 'Complete'
		GROUP BY user_id
	) 

	, RFM_Scores AS
	(
		SELECT
			[user_id] ,
			last_order_date ,
			frequency ,
			monetary ,
			recency_days ,
			NTILE(4) OVER(ORDER BY recency_days DESC) AS r_score ,
			NTILE(4) OVER(ORDER BY frequency ASC)	  AS f_score, 
			NTILE(4) OVER(ORDER BY monetary ASC)	  AS m_score
		FROM RFM_Base
	)


	SELECT
		[user_id],
		CONCAT(r_score, f_score, m_score) AS rfm_cell ,
		CAST(r_score AS VARCHAR) + CAST(f_score AS VARCHAR) + CAST(m_score AS VARCHAR) AS rfm_string ,
		CASE
			WHEN (r_score = 4 AND f_score = 4 AND m_score = 4) THEN 'Champions (VIP)' 
			WHEN (r_score >= 3 AND f_score >= 3 AND m_score >= 3) THEN 'Loyal Customers'
			WHEN (r_score >= 3 AND f_score = 1) THEN 'Potential Loyalists'
			WHEN (r_score <= 2 AND f_score >= 3) THEN 'At Risk (Need Activation)'
			WHEN (r_score = 1 AND f_score = 1) THEN 'Lost Customers'
			ELSE 'Average User'
		END customer_segment
	FROM RFM_Scores

GO
-- =============================================================================
-- SECTION 4: MARKET BASKET ANALYSIS (CROSS-SELLING)
-- Business Question: Which products are frequently bought together?
-- =============================================================================

IF OBJECT_ID('vw_Market_Basket_Affinity', 'V') IS NOT NULL 
	DROP VIEW vw_Market_Basket_Affinity;
GO

	CREATE VIEW vw_Market_Basket_Affinity 
	AS
	SELECT TOP 50
		EDP1.[id] AS product_1_id,
		EDP1.[name] AS Product_A_Name,    
		EDP2.[id] AS product_2_id,
		EDP2.[name] AS Product_B_Name,
		COUNT(*) AS Times_Bought_Together
	FROM [ecommerce].[fact_order_items] AS EFOI1
	JOIN [ecommerce].[fact_order_items] AS EFOI2
		ON EFOI1.order_id = EFOI2.order_id
			AND EFOI1.product_id < EFOI2.product_id
	JOIN [ecommerce].[dim_products]     AS EDP1
		ON EFOI1.product_id = EDP1.id
	JOIN [ecommerce].[dim_products]     AS EDP2
		ON EFOI2.product_id = EDP2.id
	GROUP BY EDP1.[id] ,
			 EDP1.[name] ,  
             EDP2.[id] ,
             EDP2.[name]   
	ORDER BY Times_Bought_Together DESC

GO
-- =============================================================================
-- SECTION 5: PRODUCT QUALITY CONTROL (RETURN RATES)
-- Business Question: Which products suffer from high return rates?
-- =============================================================================

IF OBJECT_ID('vw_Product_Return_Rates', 'V') IS NOT NULL 
	DROP VIEW vw_Product_Return_Rates;
GO

	CREATE VIEW vw_Product_Return_Rates 
	AS
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

-- =============================================================================
-- SECTION 6: USER EVENT & TRAFFIC ANALYSIS (PERFORMANCE OPTIMIZED)
-- Business Question: How can we track daily user interactions and traffic sources efficiently?
-- =============================================================================

CREATE VIEW vw_Events_Summary AS
SELECT 
    CAST(created_at AS DATE) AS event_date,
    event_type,
    traffic_source,
    browser,
    COUNT(id) AS total_events,
    COUNT(DISTINCT user_id) AS unique_users

FROM [ecommerce].[fact_events]
GROUP BY 
    CAST(created_at AS DATE), 
    event_type, 
    traffic_source, 
    browser;
