    -- A 
-- 
SELECT *
FROM foodie_fi.plans;

SELECT * 
FROM foodie_fi.subscriptions
LIMIT 10;

  -- B
-- 1. How many customers has Foodie-Fi ever had?
SELECT 
  COUNT(DISTINCT customer_id) AS total_customers
FROM foodie_fi.subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT 
  DATE_PART('month', start_date::TIMESTAMP) AS month_start,
  COUNT(*) AS trial_customers
FROM foodie_fi.subscriptions
WHERE plan_id = 0
GROUP BY month_start
ORDER BY month_start;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT 
  plans.plan_id,
  plans.plan_name,
  COUNT(*) AS events
FROM foodie_fi.subscriptions
INNER JOIN foodie_fi.plans
  ON subscriptions.plan_id = plans.plan_id
WHERE subscriptions.start_date > '2020-12-31'
GROUP BY plans.plan_id, plans.plan_name
ORDER BY plans.plan_id;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT
  SUM(CASE WHEN plan_id = 3 THEN 1 ELSE 0 END) AS churn_customers,
  ROUND(
    100 * SUM(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END) /
      COUNT(DISTINCT customer_id)::NUMERIC
  ) AS percentage
FROM foodie_fi.subscriptions;
