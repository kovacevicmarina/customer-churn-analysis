-- PROJECT: Customer Churn Analysis
-- AUTHOR: Marina Kovacevic
-- DATE: 2026
-- DESCRIPTION: Analysis of customer churn patterns,
--              revenue impact and risk segmentation
-- TOOLS: MySQL WorkBench

		-- SECTION 1: DATABASE SETUP
CREATE DATABASE customer_churn;
USE customer_churn;

SELECT  COUNT(*) FROM customers;


		-- SECTION 2: DATA CLEANING
SELECT  * FROM customers;

SET SQL_SAFE_UPDATES = 0;

UPDATE customers SET last_login_date = STR_TO_DATE(last_login_date, '%d/%m/%Y'); 
ALTER TABLE customers MODIFY last_login_date DATE;

UPDATE customers SET churn_date = STR_TO_DATE(churn_date,'%d/%m/%Y') WHERE churn_date <> '';
UPDATE customers SET churn_date = NULL WHERE churn_date = '';
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


		-- SECTION 3: ANALYSIS

-- I Overall Churn Rate 
-- High churn rate suggests issues with product-market fit or onboarding.
SELECT  
COUNT(*) AS total_customers,
SUM(CASE WHEN churn_status='Yes' THEN 1 ELSE 0 END) AS churned_customers, 
ROUND(SUM(CASE WHEN churn_status='Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100,2) AS churn_rate_percent
FROM customers;

-- II Churn by Account Type
-- The report shows which plan has the highest churn
SELECT  
account_type,
COUNT(*) AS total_customers,
SUM(CASE WHEN churn_status='Yes' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(SUM(CASE WHEN churn_status='Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100,2) AS churn_rate
FROM customers
GROUP BY account_type
ORDER BY churn_rate DESC;


-- III Churn by Tenure
-- The longer they are, the less likely they are to leave, the report shows a problem in the early lifecycle
SELECT  
tenure_group,
COUNT(*) AS total_customers,
SUM(CASE WHEN churn_status='Yes' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(SUM(CASE WHEN churn_status='Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100,2) AS  churn_rate
FROM customers
GROUP BY tenure_group
ORDER BY churn_rate DESC;

-- IV Churn vs Support Calls
-- Customers who contact support frequently are significantly more likely to churn. This suggests unresolved issues with the service experience.
SELECT  
support_calls,
COUNT(*) AS total_customers,
SUM(CASE WHEN churn_status='Yes' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(SUM(CASE WHEN churn_status='Yes' THEN 1 ELSE 0 END)/COUNT(*)*100,2) AS churn_rate
FROM customers
GROUP BY support_calls
ORDER BY support_calls;


-- V Churn vs Payment Method
-- The report shows that Payment method does not significantly affect churn.
SELECT  
payment_method,
COUNT(*) AS total_customers,
SUM(CASE WHEN churn_status='Yes' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(SUM(CASE WHEN churn_status='Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100,2) AS churn_rate
FROM customers
GROUP BY payment_method
ORDER BY churn_rate DESC;


-- VI Total Revenue Lost from Churned Customers
-- Total revenue lost represents the financial impact of churn.
SELECT  
SUM(total_paid) AS total_revenue_lost
FROM customers
WHERE churn_status = 'Yes';


-- VII Revenue by churn status
-- The report shows that Churned customers generate significantly lower average revenue compared to active customers
SELECT  churn_status, COUNT(*) AS total_customers, sum(total_paid) AS total_revenue, ROUND(AVG(total_paid),2) AS avg_revenue_per_customer 
FROM customers group by churn_status;

-- VIII  Revenue by Plan
-- Identifies high-value segments and shows which plan generates the most revenue
SELECT  account_type, COUNT(*) AS total_customers, sum(total_paid) AS total_revenue, ROUND(AVG(total_paid),2) AS avg_customer_value FROM customers group by account_type order by total_revenue desc;

		-- SECTION 4: ADVANCED INSIGHTS & RECOMMENDATIONS

-- IX At-Risk Customers : Active customers showing churn warning signs.
-- These should be prioritized for retention campaigns.
SELECT customer_id, account_type, customer_segment, support_calls, monthly_fee, months_active, tenure_group
FROM customers
WHERE churn_status = 'No'
    AND support_calls >= 9
    AND months_active <= 12
ORDER BY support_calls DESC, monthly_fee DESC
LIMIT 100;

-- X  Average time to churn by account type
-- Shows how quickly each plan type loses customers
 SELECT account_type,
    ROUND(AVG(months_active), 1) AS avg_months_before_churn,
    COUNT(*) AS churned_customers,
    ROUND(AVG(monthly_fee), 2) AS avg_monthly_fee
FROM customers
WHERE churn_status = 'Yes'
GROUP BY account_type
ORDER BY avg_months_before_churn ASC;


-- XI High value churned customers
-- Top churned customers by revenue lost.
SELECT customer_id, account_type, customer_segment, total_paid, months_active, support_calls, payment_method
FROM customers
WHERE churn_status = 'Yes'
ORDER BY total_paid DESC
LIMIT 20;





