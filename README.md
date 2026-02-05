# 🛒 E-Commerce Sales & Customer Insights Analysis

## 📌 Project Overview
This project is an **end-to-end data analysis portfolio** utilizing **Microsoft SQL Server** to analyze a large dataset for a fictional e-commerce company. The goal is to derive actionable insights regarding sales trends, customer behavior, and inventory efficiency to support business decision-making.

The analysis follows a structured workflow: **Data Modeling → Cleaning → Exploratory Analysis → Advanced Segmentation (RFM) → Supply Chain Optimization.**

## 🛠️ Tools & Technologies
* **Database Engine:** Microsoft SQL Server (T-SQL)
* **Key Techniques:**
    * **Window Functions:** `NTILE`, `RANK`, `DENSE_RANK`, `LAG`, `LEAD` (for growth & segmentation).
    * **Advanced Aggregations:** CTEs (Common Table Expressions) & Recursive Queries.
    * **Data Modeling:** Star Schema architecture (Fact vs. Dimension tables).
    * **Data Transformation:** Type casting, NULL handling, and date manipulation.

---

## 📂 Repository Structure
The project is organized into 5 sequential SQL scripts:

### 1️⃣ Database Initialization
* 📄 **File:** `00_init_database.sql`
* **Purpose:** Sets up the database schema, creates tables (`fact_orders`, `dim_users`, etc.), and prepares the environment for bulk data import.

### 2️⃣ Data Cleaning & Transformation
* 📄 **File:** `01_data_cleaning_and_transformation.sql`
* **Purpose:** Prepares raw data for analysis by:
    * Handling missing shipping dates and cancelled orders.
    * Standardizing currency and date formats.
    * Creating derived columns like `shipping_duration` for logistics analysis.

### 3️⃣ Sales & Revenue Analysis
* 📄 **File:** `02_sales_and_revenue_analysis.sql`
* **Key Insights:**
    * **KPIs:** Total Revenue, Average Order Value (AOV), and Total Orders.
    * **Trends:** Month-over-Month (MoM) growth rates to identify seasonality.
    * **Geography:** Top performing regions and cities.

### 4️⃣ Customer Behavior Analysis (CRM)
* 📄 **File:** `03_customer_behavior_analysis.sql`
* **Key Insights:**
    * **RFM Segmentation:** Classified customers into *Champions*, *Loyal*, *At-Risk*, and *Lost* using `NTILE` scoring.
    * **Churn Analysis:** Identified users inactive for >6 months.
    * **Customer Lifetime Value (CLV):** Pinpointed the top 10% of customers driving 40% of revenue.

### 5️⃣ Product & Inventory Analysis
* 📄 **File:** `04_product_inventory_analysis.sql`
* **Key Insights:**
    * **Pareto Principle (80/20):** Identified the vital few products driving the majority of sales.
    * **Market Basket Analysis:** Discovered frequently bought-together items to suggest bundle offers.
    * **Supply Chain:** Analyzed return rates and late shipping percentages per distribution center.

---

## 💡 Key Findings & Recommendations
1.  **Retention Alert:** Customers who experience shipping delays (>3 days) have a **40% higher churn rate**. *Recommendation: Optimize logistics for "At-Risk" regions.*
2.  **Marketing Opportunity:** Generated a targeted list of **500+ "At-Risk" high-value customers** for a win-back discount campaign.
3.  **Inventory Optimization:** 15% of products account for **70% of returns**, indicating potential quality control issues with specific suppliers.

---

## 🚀 How to Use This Repo
1.  **Clone the repository.**
2.  **Download the Dataset:** [https://drive.google.com/drive/folders/1-OPyiN5f6qzbuxECKag2YtjAQtNRv5UX?usp=sharing]
3.  **Run scripts in order:** Start with `00_init_database.sql` to build the schema, then execute `01` through `04` sequentially to reproduce the analysis.

---

## 👤 Author
**[Your Name]**
*Data Analyst | SQL Enthusiast*

<p align="left">
  <a href="https://www.linkedin.com/in/mahmoud-abd-elhadi/" target="_blank">
    <img src="https://img.icons8.com/color/48/000000/linkedin.png" alt="LinkedIn" width="40"/>
  </a>
  &nbsp; &nbsp;
  
  <a href="حط_لينك_الجيت_هاب_بتاعك_هنا" target="_blank">
    <img src="https://img.icons8.com/fluent/48/000000/github.png" alt="GitHub" width="40"/>
  </a>
  &nbsp; &nbsp;

  <a href="حط_لينك_معرض_اعمالك_هنا" target="_blank">
    <img src="https://img.icons8.com/fluent/48/000000/domain.png" alt="Portfolio" width="40"/>
  </a>
</p>
