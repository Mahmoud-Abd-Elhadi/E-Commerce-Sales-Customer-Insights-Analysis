/*
================================================================================
Project Name : The Look Ecommerce Data Warehouse
Description  : End-to-End ETL Script (Create -> Load -> Clean -> Model)
               1. Sets up the database and schema.
               2. Creates tables (using staging types for raw data).
               3. Bulk loads data from CSV files.
               4. Cleans and transforms specific columns (e.g., user_id formatting).
               5. Establishes relationships (Foreign Keys).
================================================================================
*/

USE master
GO

-- =============================================================================
-- SECTION 1: DATABASE INITIALIZATION
-- Description: Ensures a clean start by dropping the DB if it exists.
-- =============================================================================

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'The_Look_Ecommerce')
BEGIN
	ALTER DATABASE The_Look_Ecommerce SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE The_Look_Ecommerce
END

GO 

CREATE DATABASE The_Look_Ecommerce
GO

USE The_Look_Ecommerce
GO

 
CREATE SCHEMA ecommerce
GO

-- =============================================================================
-- SECTION 2: DDL - TABLE CREATION
-- Description: Defines the schema. Note that 'fact_events' uses VARCHAR for IDs
--              initially to handle potential dirty data during import.
-- =============================================================================

CREATE TABLE ecommerce.dim_users (
    id             INT PRIMARY KEY,
    first_name     VARCHAR(100),
    last_name      VARCHAR(100),
    email          VARCHAR(255),
    age            INT,
    gender         VARCHAR(10),
    [state]        VARCHAR(100),
    street_address VARCHAR(255),
    postal_code    VARCHAR(50),
    city           VARCHAR(100),
    country        VARCHAR(100),
    latitude       FLOAT,
    longitude      FLOAT,
    traffic_source VARCHAR(50),
    created_at     VARCHAR(50) 
);
GO

CREATE TABLE ecommerce.dim_distribution_centers
(
	id        INT PRIMARY KEY ,
	[name]    VARCHAR(MAX) ,
	latitude  FLOAT,
    longitude FLOAT
)

CREATE TABLE ecommerce.dim_products 
(   
	id                     INT PRIMARY KEY ,
	cost                   FLOAT ,
	category               VARCHAR(100),
	[name]                 VARCHAR(500) ,
	brand                  VARCHAR(255),
    retail_price           FLOAT,
    department             VARCHAR(50),
    sku                    VARCHAR(100),
	distribution_center_id INT ,

    FOREIGN KEY (distribution_center_id) REFERENCES ecommerce.dim_distribution_centers (id)
)

CREATE TABLE ecommerce.fact_orders
(
	order_id     INT PRIMARY KEY,
    [user_id]    INT,
    [status]     VARCHAR(50),
    gender       VARCHAR(10),
	created_at   VARCHAR(100),
    returned_at  VARCHAR(100),
    shipped_at   VARCHAR(100),
    delivered_at VARCHAR(100),
    num_of_item  INT ,

    FOREIGN KEY ([user_id]) REFERENCES ecommerce.dim_users (id)
)

CREATE TABLE ecommerce.fact_events
(
	id              VARCHAR(100) PRIMARY KEY,
    [user_id]       VARCHAR(100),         -- Staging column (will be converted to INT later)
    sequence_number VARCHAR(100),
    [session_id]    VARCHAR(100),
    created_at      VARCHAR(100),
    ip_address      VARCHAR(50),
    city            VARCHAR(100),
    [state]         VARCHAR(100),
    postal_code     VARCHAR(50),
    browser         VARCHAR(50),
    traffic_source  VARCHAR(50),
    uri             VARCHAR(500),
    event_type      VARCHAR(50) ,
)

CREATE TABLE ecommerce.fact_inventory_items (
    id                             INT PRIMARY KEY,
    product_id                     INT,
    created_at                     VARCHAR(100),
    sold_at                        VARCHAR(100),
    cost                           FLOAT,
    product_category               VARCHAR(100),
    product_name                   VARCHAR(255),
    product_brand                  VARCHAR(255),
    product_retail_price           FLOAT,
    product_department             VARCHAR(50),
    product_sku                    VARCHAR(100),
    product_distribution_center_id INT ,

    FOREIGN KEY (product_id) REFERENCES ecommerce.dim_products (id) ,
    FOREIGN KEY (product_distribution_center_id) REFERENCES ecommerce.dim_distribution_centers (id)
)

CREATE TABLE ecommerce.fact_order_items (
    id                INT PRIMARY KEY,
    order_id          INT,
    [user_id]         INT,
    product_id        INT,
    inventory_item_id INT,
    [status]          VARCHAR(50),
    created_at        VARCHAR(100),
    shipped_at        VARCHAR(100),
    delivered_at      VARCHAR(100),
    returned_at       VARCHAR(100),
    sale_price        FLOAT ,

    FOREIGN KEY (order_id) REFERENCES ecommerce.fact_orders (order_id) ,
    FOREIGN KEY ([user_id]) REFERENCES ecommerce.dim_users (id) ,
    FOREIGN KEY (product_id) REFERENCES ecommerce.dim_products (id) ,
    FOREIGN KEY (inventory_item_id) REFERENCES ecommerce.fact_inventory_items (id)

);

-- =============================================================================
-- SECTION 3: DATA LOADING (BULK INSERT)
-- Description: Loading data from CSVs. 
-- Note: ROWTERMINATOR '0x0a' is used for Linux-style line endings (common in Kaggle).
-- =============================================================================

-- 3.1 Load Users
TRUNCATE TABLE ecommerce.dim_users;
GO

BULK INSERT ecommerce.dim_users
FROM 'C:\Temp\users.csv' 
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a', 
    TABLOCK
);
GO

-- 3.2 Load Distribution Centers
TRUNCATE TABLE ecommerce.dim_distribution_centers;
GO

BULK INSERT ecommerce.dim_distribution_centers
FROM 'C:\Temp\distribution_centers.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a', 
    TABLOCK
)
GO

-- 3.3 Load Products
TRUNCATE TABLE ecommerce.dim_products
GO

BULK INSERT ecommerce.dim_products
FROM 'C:\Temp\products.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a', 
    TABLOCK
)
GO

-- 3.4 Load Orders
TRUNCATE TABLE ecommerce.fact_orders
GO

BULK INSERT ecommerce.fact_orders
FROM 'C:\Temp\orders.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a', 
    TABLOCK
)
GO

-- 3.5 Load Events (Raw Import)
TRUNCATE TABLE ecommerce.fact_events
GO

BULK INSERT ecommerce.fact_events
FROM 'C:\Temp\events.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a', 
    TABLOCK
)
GO

-- 3.6 Load Inventory
TRUNCATE TABLE ecommerce.fact_inventory_items
GO

BULK INSERT ecommerce.fact_inventory_items
FROM 'C:\Temp\inventory_items.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a', 
    TABLOCK
)
GO

-- 3.7 Load Order Items
TRUNCATE TABLE ecommerce.fact_order_items
GO

BULK INSERT ecommerce.fact_order_items
FROM 'C:\Temp\order_items.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a', 
    TABLOCK
)
GO

-- =============================================================================
-- SECTION 4: DATA TRANSFORMATION & MODELING
-- Description: Cleaning staging columns and enforcing referential integrity.
-- =============================================================================

-- Step 4.1: Data Cleaning
-- Removing the decimal suffix (.0) from user_id strings caused by source formatting
UPDATE ecommerce.fact_events
SET user_id = REPLACE(user_id , '.0' , '')
WHERE user_id LIKE '%.0'

-- Step 4.2: Type Conversion
-- Converting user_id from Staging type (VARCHAR) to Target type (INT)
ALTER TABLE ecommerce.fact_events
ALTER COLUMN user_id INT

-- Step 4.3: Referential Integrity
-- Adding the Foreign Key constraint linking Events to Users
ALTER TABLE ecommerce.fact_events
ADD CONSTRAINT  FK_Events_Users
FOREIGN KEY (user_id) REFERENCES ecommerce.dim_users (id)

------------------------------------------------------------------

