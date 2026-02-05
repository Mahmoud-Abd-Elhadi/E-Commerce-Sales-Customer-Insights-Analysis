/*
================================================================================
Project Name : E-commerce Data Cleaning & Transformation
Description  : This script performs data validation, cleaning, and type casting 
               to prepare the raw data for analysis.
               
Key Operations:
  1. Date Standardization: Truncating timestamps and converting to DATETIME.
  2. Financial Normalization: Rounding prices/costs to 2 decimal places.
  3. Schema Optimization: Converting IDs to INT and re-establishing Primary Keys.
================================================================================
*/

-- =============================================================================
-- 1. Table: dim_users
-- Description: Handling timezone anomalies and converting creation dates.
-- =============================================================================

-- Step 1.1: Validation (Check for nulls or weird formats)
SELECT 
	 COUNT([created_at])
FROM [ecommerce].[dim_users]

SELECT 
	 [created_at]
FROM [ecommerce].[dim_users]
WHERE [created_at] LIKE '%+%'

-- Step 1.2: Cleaning (Remove timezone offset '+00:00') 
UPDATE [ecommerce].[dim_users]
SET [created_at] = REPLACE([created_at] , '+00:00' , '' )

-- Step 1.3: Standardization (Keep first 19 chars: YYYY-MM-DD HH:MM:SS)
UPDATE [ecommerce].[dim_users]
SET [created_at] = LEFT([created_at] , 19)

-- Step 1.4: Type Casting (Convert to DATETIME)
ALTER TABLE [ecommerce].[dim_users]
ALTER COLUMN [created_at] DATETIME


-- =============================================================================
-- 2. Table: dim_products
-- Description: Validating brands and standardizing prices.
-- =============================================================================

-- Step 2.1: Data Inspection
SELECT * FROM [ecommerce].[dim_products]
WHERE brand IS NULL

-- Step 2.2: Financial Rounding (Round retail price to 2 decimal places)
UPDATE [ecommerce].[dim_products]
SET [retail_price] = ROUND([retail_price] , 2)

-- Step 2.2: Financial Rounding (Cost to 2 decimal places)
UPDATE [ecommerce].[dim_products]
SET [cost] = ROUND([cost] , 2)


-- =============================================================================
-- 3. Table: fact_orders
-- Description: Cleaning and converting lifecycle timestamps (Created -> Delivered).
-- =============================================================================

-- Step 3.1: Created Date
UPDATE [ecommerce].[fact_orders]
SET [created_at] = LEFT([created_at] , 19)

ALTER TABLE [ecommerce].[fact_orders]
ALTER COLUMN [created_at] DATETIME

-- Step 3.2: Returned Date
UPDATE [ecommerce].[fact_orders]
SET [returned_at] = LEFT([returned_at] , 19)

ALTER TABLE [ecommerce].[fact_orders]
ALTER COLUMN [returned_at] DATETIME

-- Step 3.3: Shipped Date
UPDATE [ecommerce].[fact_orders]
SET [shipped_at] = LEFT([shipped_at] , 19)

ALTER TABLE [ecommerce].[fact_orders]
ALTER COLUMN [shipped_at] DATETIME

-- Step 3.4: Delivered Date
UPDATE [ecommerce].[fact_orders]
SET [delivered_at] = LEFT([delivered_at] , 19)

ALTER TABLE [ecommerce].[fact_orders]
ALTER COLUMN [delivered_at] DATETIME


-- =============================================================================
-- 4. Table: fact_inventory_items
-- Description: Cleaning dates and standardizing costs/prices.
-- =============================================================================

-- Step 4.1: Created Date
UPDATE [ecommerce].[fact_inventory_items]
SET [created_at] = LEFT([created_at] , 19)

ALTER TABLE [ecommerce].[fact_inventory_items]
ALTER COLUMN [created_at] DATETIME
 
-- Step 4.2: Sold Date
UPDATE [ecommerce].[fact_inventory_items]
SET [sold_at] = LEFT([sold_at] , 19)

ALTER TABLE [ecommerce].[fact_inventory_items]
ALTER COLUMN [sold_at] DATETIME

-- Step 4.3: Cost
UPDATE [ecommerce].[fact_inventory_items]
SET [cost] = ROUND([cost] , 2)
 
-- Step 4.4: Retail price
UPDATE [ecommerce].[fact_inventory_items]
SET [product_retail_price] = ROUND([product_retail_price] , 2)


-- =============================================================================
-- 5. Table: fact_events (Part 1)
-- Description: Cleaning timestamp column.
-- =============================================================================

SELECT * FROM [ecommerce].[fact_events]

UPDATE [ecommerce].[fact_events]
SET [created_at] = LEFT([created_at] , 19)

ALTER TABLE [ecommerce].[fact_events]
ALTER COLUMN [created_at] DATETIME


-- =============================================================================
-- 6. Table: fact_order_items
-- Description: Cleaning timestamps and sale prices.
-- =============================================================================

-- Step 6.1: Date Cleaning
UPDATE [ecommerce].[fact_order_items]
SET [created_at] = LEFT([created_at] , 19)

ALTER TABLE [ecommerce].[fact_order_items]
ALTER COLUMN [created_at] DATETIME


UPDATE [ecommerce].[fact_order_items] 
SET [shipped_at] = LEFT([shipped_at] , 19)

ALTER TABLE [ecommerce].[fact_order_items]
ALTER COLUMN [shipped_at] DATETIME
 

UPDATE [ecommerce].[fact_order_items] 
SET [delivered_at] = LEFT([delivered_at] , 19)

ALTER TABLE [ecommerce].[fact_order_items]
ALTER COLUMN [delivered_at] DATETIME
 

UPDATE [ecommerce].[fact_order_items] 
SET [returned_at] = LEFT([returned_at] , 19)

ALTER TABLE [ecommerce].[fact_order_items]
ALTER COLUMN [returned_at] DATETIME


-- Step 6.2: Financial Cleaning
UPDATE [ecommerce].[fact_order_items]
SET [sale_price] = ROUND([sale_price] , 2)


-- =============================================================================
-- 7. Table: fact_events (Part 2 - Schema Fix)
-- Description: Converting 'ID' from VARCHAR to INT.
-- Note: This requires dropping the temporary PK constraint first.
-- =============================================================================

-- 1. Drop old constraint (Name might vary in different environments)
ALTER TABLE [ecommerce].[fact_events]
DROP CONSTRAINT PK__fact_eve__3213E83FA25D8F7A

-- 2. Modify Column Type
ALTER TABLE [ecommerce].[fact_events]
ALTER COLUMN id INT NOT NULL

-- 3. Re-create Primary Key with a clean name
ALTER TABLE [ecommerce].[fact_events]
ADD CONSTRAINT PK_Events PRIMARY KEY (id) 
