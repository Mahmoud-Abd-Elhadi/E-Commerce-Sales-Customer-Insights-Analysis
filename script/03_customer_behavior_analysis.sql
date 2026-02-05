/*
================================================================================
File Name   : 06_customer_segmentation_analysis.sql
Project     : E-Commerce Data Analysis Portfolio
Database    : [ecommerce]
================================================================================

DESCRIPTION:
------------
This script focuses on the "Human" side of the business.
It segments customers based on their behavior, loyalty, and purchasing patterns 
to identify VIPs, Churn risks, and User Acquisition trends.

KEY BUSINESS QUESTIONS ADDRESSED:
---------------------------------
1. Demographics:
   - Who are our users? (Gender, Location).
   
2. Loyalty & Retention:
   - What percentage of our user base are repeat buyers vs. one-time shoppers?

3. VIP Analysis (Whales):
   - Who are our top spenders (Lifetime Value)?

4. Churn Analysis:
   - Who are the customers we are losing (Inactive > 6 months)?

5. Conversion Speed:
   - How long does it take for a new user to make their first purchase?

6. Growth Trends:
   - How is our user base growing Month-over-Month?

7.ADVANCED RFM SEGMENTATION
   - RFM Analysis (Recency, Frequency, Monetary)
================================================================================
*/
-- =============================================================================
-- SECTION 1: CUSTOMER DEMOGRAPHICS (Who are they?)
-- =============================================================================

/* 1. Total Users & Gender Distribution
   (Helpful for ad targeting: Should we use male or female models in ads?)
*/

SELECT
	gender ,
	COUNT(id) AS total_users ,
	CONCAT(
		ROUND(
			(CAST(COUNT(id) AS FLOAT) / (SELECT COUNT(*) FROM [ecommerce].[dim_users])) * 100 
		, 2)
	,'%') AS percentage_share
FROM [ecommerce].[dim_users] 
GROUP BY gender

/* 1. Top Countries by User Count
    -----------------------------------------------
    Where do our customers live?
*/

SELECT TOP 10
	country ,
	COUNT(id) AS total_users ,
	CONCAT(
		ROUND(
			(CAST(COUNT(id) AS FLOAT) / (SELECT COUNT(*) FROM [ecommerce].[dim_users])) * 100 
		, 2)
	 ,'%') AS percentage_share
FROM [ecommerce].[dim_users] 
GROUP BY country
ORDER BY total_users DESC 

-- =============================================================================
-- SECTION 2: LOYALTY & RETENTION (Do they come back?)
-- =============================================================================

/* 2. One-time vs. Repeat Buyers (Loyalty Rate)
   -----------------------------------------------
   What % of our customers are "Loyal" (bought more than once)?
*/ 

WITH User_Order_Counts AS
(
	SELECT
		[user_id] ,
		COUNT(DISTINCT order_id) AS order_count 
	FROM [ecommerce].[fact_order_items]
	WHERE [status] = 'complete'
	GROUP BY [user_id]
)

SELECT
	CASE
		WHEN order_count > 1 THEN 'Repeat Buyer (Loyal)'
		ELSE 'One-time Buyer'
	END customer_type ,
	COUNT([user_id]) AS total_users ,
	CONCAT(
		ROUND(
			(CAST(COUNT([user_id]) AS FLOAT) / (SELECT COUNT(*) FROM User_Order_Counts)) * 100 
		, 2),
	'%') AS percentage_share
FROM User_Order_Counts
GROUP BY CASE
			WHEN order_count > 1 THEN 'Repeat Buyer (Loyal)'
			ELSE 'One-time Buyer'
		 END 

-- =============================================================================
-- SECTION 3: VIP CUSTOMERS (Who are the "Whales"?)
-- =============================================================================

/* 3. Top 10 Spenders (Lifetime Value - LTV)
	-----------------------------------------------
    Who are our most valuable customers by total spend?
*/

SELECT TOP 10
	EDU.id ,
	CONCAT(EDU.first_name , ' ' , EDU.last_name) AS full_name ,
	EDU.country ,
	COUNT(DISTINCT EFOI.order_id) AS total_orders ,
	ROUND(SUM(EFOI.sale_price) , 2) AS lifetime_value
FROM [ecommerce].[fact_order_items] AS EFOI
JOIN [ecommerce].[dim_users]        AS EDU
ON EFOI.[user_id] = EDU.id 
WHERE [state] = 'complete'
GROUP BY EDU.id , CONCAT(EDU.first_name , ' ' , EDU.last_name) , EDU.country 
ORDER BY lifetime_value DESC

-- =============================================================================
-- SECTION 4: CHURN ANALYSIS (Who have we lost?)
-- =============================================================================

/* 4. At-Risk Customers (Churn Candidates)
   -----------------------------------------------
   Which customers haven't purchased anything in the last 6 months 
   relative to the latest data point available?
   *Logic: We compare "Last Purchase" vs "Max Date in Database".
*/

SELECT MAX(created_at) FROM [ecommerce].[fact_order_items] --=> This is end date

WITH Customer_Last_Activity AS
(
SELECT
	EDU.id ,
	CONCAT(EDU.first_name , ' ' , EDU.last_name) AS full_name ,
	EDU.email ,
	EDU.country ,
	MAX(EFOI.created_at) AS last_purchase_date,
	DATEDIFF(DAY , MAX(EFOI.created_at) , (SELECT MAX(created_at) FROM [ecommerce].[fact_order_items])) AS days_since_last_order 
FROM [ecommerce].[fact_order_items] AS EFOI
JOIN [ecommerce].[dim_users]        AS EDU
ON EFOI.[user_id] = EDU.id
WHERE [status] = 'complete'
GROUP BY EDU.id ,
		 CONCAT(EDU.first_name , ' ' , EDU.last_name)  ,
		 EDU.email ,
	     EDU.country
)

SELECT 
	*  
FROM Customer_Last_Activity
WHERE days_since_last_order > 180
ORDER BY days_since_last_order DESC

-- =============================================================================
-- SECTION 5: CONVERSION SPEED (Time to First Purchase)
-- =============================================================================

/* 5. How long does it take for a user to make their first purchase?
   -----------------------------------------------
   Are users buying immediately after signup, or do they wait weeks?
   (Helps optimize the "Onboarding" email flow).
*/

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
,  Purchase_Latency_Segments AS
(
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
)

SELECT 
	purchase_speed_segment ,
	COUNT(id) AS total_users ,
	CONCAT(
		ROUND(
			(CAST(COUNT(id) AS FLOAT) / (SELECT COUNT(*) FROM Calc_Purchase_Latency)) * 100 
		,  2),
	'%') AS percentage_share
FROM Purchase_Latency_Segments
GROUP BY purchase_speed_segment
ORDER BY total_users DESC

-- =============================================================================
-- SECTION 6: USER ACQUISITION TREND (Are we growing?)
-- =============================================================================

/* 6. New User Signups Over Time
   -----------------------------------------------
   How is our user base growing month-over-month? 
*/


SELECT
	YEAR(created_at)  AS signup_year ,
	MONTH(created_at) AS signup_month ,
	COUNT(id) AS new_users_count ,
	COUNT(id) - LAG(COUNT(id)) OVER(ORDER BY YEAR(created_at) , MONTH(created_at)) AS growth_from_prev_month 
FROM [ecommerce].[dim_users]
GROUP BY YEAR(created_at) , MONTH(created_at)
ORDER BY signup_year , signup_month

-- =============================================================================
-- SECTION 7: ADVANCED RFM SEGMENTATION (The Holy Grail)
-- =============================================================================

/* 7. RFM Analysis (Recency, Frequency, Monetary)
   -----------------------------------------------
   We score each customer from 1 to 4 on each metric.
   - Recency: 1 (Oldest) -> 4 (Newest)
   - Frequency: 1 (Rare) -> 4 (Frequent)
   - Monetary: 1 (Low Spender) -> 4 (High Spender)
*/

WITH RFM_Base AS (
    SELECT 
        [user_id],
        MAX(created_at) AS last_order_date,
        COUNT(order_id) AS frequency,
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

 , RFM_Final AS 
(
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
)

SELECT
	customer_segment ,
	COUNT([user_id]) AS total_users
FROM RFM_Final
GROUP BY customer_segment
ORDER BY total_users DESC