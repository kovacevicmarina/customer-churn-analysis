-- PROJECT: Customer Churn Analysis
-- AUTHOR: Marina Kovacevic
-- DATE: 2026
-- DATA PERIOD: 2025
-- Structured analytical data model for churn analysis including:
-- data cleaning, validation, business logic, KPI layer and actionable customer segmentation
-- TOOLS: MySQL WorkBench, Excel, Power Bi 

		-- SECTION 1: DATABASE SETUP
CREATE DATABASE customer_churn;
USE customer_churn;

SELECT  COUNT(*) FROM customers;


		-- SECTION 2: DATA CLEANING & STANDARDIZATION
SELECT  * FROM customers;

SET SQL_SAFE_UPDATES = 0;

-- Convert dates
UPDATE customers SET last_login_date = STR_TO_DATE(last_login_date, '%d/%m/%Y'); 
ALTER TABLE customers MODIFY last_login_date DATE;

UPDATE customers SET churn_date = NULL WHERE churn_date = '';
UPDATE customers SET churn_date = STR_TO_DATE(churn_date,'%d/%m/%Y') WHERE churn_date <> '';
ALTER TABLE customers MODIFY churn_date DATE NULL;

ALTER TABLE customers MODIFY monthly_usage INT;
ALTER TABLE customers MODIFY monthly_fee DECIMAL(10,2);
ALTER TABLE customers MODIFY total_paid DECIMAL(10,2);
ALTER TABLE customers
MODIFY gender VARCHAR(20),
MODIFY city VARCHAR(100),
MODIFY account_type VARCHAR(30),
MODIFY payment_method VARCHAR(50),
MODIFY churn_status VARCHAR(5),
MODIFY customer_segment VARCHAR(30),
MODIFY tenure_group VARCHAR(30);

DESCRIBE customers;


		-- SECTION 3: DATA VALIDATION (QUALITY CHECKS)
        
-- Row count        
SELECT count(*) AS total_customers FROM customers;

-- Duplicate check
SELECT customer_id, count(*) AS total_customers FROM customers group by customer_id having total_customers >1;

-- NULL checks
SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN churn_status IS NULL THEN 1 ELSE 0 END) AS null_churn_status,
    SUM(CASE WHEN total_paid IS NULL THEN 1 ELSE 0 END) AS null_revenue
FROM customers;


		-- SECTION 4: CORE DATA MODEL (SINGLE SOURCE OF TRUTH)
CREATE OR REPLACE VIEW vw_customer_metrics AS 
SELECT
    customer_id,
    account_type,
    customer_segment,
    tenure_group,
    months_active,
    monthly_fee,
    support_calls,
    total_paid,
    churn_status,
    payment_method,
    last_login_date,
    
-- Customer Lifetime Value
    ROUND(monthly_fee * months_active, 2) AS lifetime_value,
    
-- Risk Segmentation (centralized logic)
    CASE
		WHEN support_calls >= 13 AND months_active < 12 THEN 'Critical Risk'
        WHEN support_calls >= 9 AND months_active < 12 THEN 'High Risk'
		WHEN support_calls >= 5 THEN 'Medium Risk'
        ELSE 'Low Risk'
        END AS risk_segment,
        
-- Lifecycle stage
    CASE
		WHEN months_active < 12 THEN 'New'
        WHEN months_active BETWEEN 12 AND 24 THEN 'Growing'
        ELSE 'Mature'
	END AS lifecycle_stage
    
FROM customers;
SELECT * FROM vw_customer_metrics;


		-- SECTION 5: CHURN & REVENUE MODEL
CREATE OR REPLACE VIEW vw_churn_analysis AS
SELECT
*,
CASE 
	WHEN churn_status = 'Yes' THEN total_paid 
        ELSE 0 
    END AS lost_revenue
    
FROM vw_customer_metrics;
SELECT * FROM vw_churn_analysis;


		-- SECTION 6: EXECUTIVE KPI LAYER
CREATE OR REPLACE VIEW vw_executive_summary AS
SELECT
    COUNT(*) AS total_customers,

    SUM(CASE WHEN churn_status = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,

    ROUND(SUM(CASE WHEN churn_status = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_percent,

    ROUND(SUM(total_paid), 2) AS total_revenue,

    ROUND(SUM(CASE WHEN churn_status = 'Yes' THEN total_paid ELSE 0 END), 2) AS lost_revenue,

    ROUND(AVG(lifetime_value), 2) AS avg_clv

FROM vw_customer_metrics;
SELECT * FROM vw_executive_summary;


		-- SECTION 7: STRATEGIC BUSINESS SEGMENTS
CREATE OR REPLACE VIEW vw_risk_summary AS
SELECT 
    risk_segment,
    COUNT(*) AS total_customers,
    ROUND(AVG(monthly_fee), 2) AS avg_monthly_fee,
    ROUND(SUM(lifetime_value), 2) AS total_clv_at_risk
FROM vw_customer_metrics
GROUP BY risk_segment;

SELECT * FROM vw_risk_summary;


		-- SECTION 8: HIGH-VALUE AT-RISK CUSTOMERS (ACTION LAYER)
CREATE OR REPLACE VIEW vw_high_risk_customers AS
SELECT 
    customer_id,
    account_type,
    customer_segment,
    lifetime_value,
    support_calls,
    months_active,
    risk_segment
FROM vw_customer_metrics
WHERE churn_status = 'No'
  AND risk_segment IN ('Critical Risk', 'High Risk')
ORDER BY lifetime_value DESC;
SELECT * FROM vw_high_risk_customers;


		-- SECTION 9: ADVANCED ANALYTICS (WINDOW FUNCTION - TARGETED)
-- Customer ranking by lifetime value
CREATE OR REPLACE VIEW vw_customer_ranking AS
SELECT 
    customer_id,
    lifetime_value,
    RANK() OVER (ORDER BY lifetime_value DESC) AS revenue_rank
FROM vw_customer_metrics;       
SELECT * FROM vw_customer_ranking;        
        
        
		-- SECTION 10: ANALYTICAL QUERIES & KEY FINDINGS
-- Churn by Account Type
-- FINDING: Basic plan has highest churn at 24.52%
SELECT account_type, COUNT(*) AS total_customers,
    ROUND(SUM(CASE WHEN churn_status='Yes' THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS churn_rate
FROM customers GROUP BY account_type ORDER BY churn_rate DESC;

-- Churn by Support Call Volume
-- FINDING: 13+ calls = 34.78% churn rate
SELECT
    CASE WHEN support_calls >= 13 THEN '13+ calls'
         WHEN support_calls >= 9  THEN '9-12 calls'
         WHEN support_calls >= 6  THEN '6-8 calls'
         WHEN support_calls >= 3  THEN '3-5 calls'
         ELSE '0-2 calls' END AS call_group,
    COUNT(*) AS total,
    ROUND(SUM(CASE WHEN churn_status='Yes' THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS churn_rate
FROM customers GROUP BY call_group ORDER BY churn_rate DESC;


		-- SECTION 11: FINAL CHECKS
SELECT * FROM vw_customer_metrics LIMIT 5;
SELECT * FROM vw_executive_summary;
SELECT * FROM vw_risk_summary;
SELECT * FROM vw_high_risk_customers LIMIT 10;
SELECT * FROM vw_customer_ranking LIMIT 10;      
        
     