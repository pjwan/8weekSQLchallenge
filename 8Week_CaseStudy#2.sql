-- 1. How many pizzas were ordered?
SELECT COUNT(*)
FROM pizza_runner.customer_orders;
-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id)
FROM pizza_runner.customer_orders;
-- 3. How many successful orders were delivered by each runner?
DROP TABLE IF EXISTS cleaned_runner;
CREATE TEMP TABLE cleaned_runner AS
SELECT
  order_id,
  runner_id,
  pickup_time,
  distance,
  duration,
  CASE
    WHEN cancellation = '' THEN NULL
    WHEN cancellation = 'null' THEN NULL
    ELSE cancellation
  END AS cleaned_cancellation
FROM pizza_runner.runner_orders;

SELECT
  runner_id,
  COUNT(*)
FROM
  cleaned_runner
WHERE
  cleaned_cancellation IS NULL
GROUP BY
  runner_id
ORDER BY
  runner_id;

--4. How many of each type of pizza was delivered?
SELECT 
  pizza_names.pizza_name,
  COUNT(*) 
FROM cleaned_runner
LEFT JOIN pizza_runner.customer_orders
ON cleaned_runner.order_id = customer_orders.order_id
LEFT JOIN pizza_runner.pizza_names
ON customer_orders.pizza_id = pizza_names.pizza_id
WHERE cleaned_cancellation IS NULL
GROUP BY pizza_names.pizza_name;

     ---or
SELECT
  t2.pizza_name,
  COUNT(t1.*) AS delivered_pizza_count
FROM pizza_runner.customer_orders AS t1
LEFT JOIN pizza_runner.pizza_names AS t2
  ON t1.pizza_id = t2.pizza_id
WHERE EXISTS(
SELECT 1 FROM cleaned_runner AS t3 
WHERE t1.order_id = t3.order_id 
  AND t3.cleaned_cancellation IS NULL
  )
GROUP BY t2.pizza_name;
--5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
  t1.customer_id,
  SUM(CASE WHEN t2.pizza_name = 'Meatlovers' THEN 1 ELSE 0 END) AS Meatlovers,
  SUM(CASE WHEN t2.pizza_name = 'Vegetarian' THEN 1 ELSE 0 END) AS Vegetarian
FROM pizza_runner.customer_orders AS t1
LEFT JOIN pizza_runner.pizza_names AS t2 
ON t1.pizza_id = t2.pizza_id
GROUP BY t1.customer_id
ORDER BY t1.customer_id;
-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT 
  t1.order_id,
  COUNT(*) AS pizza_count
FROM cleaned_runner AS t1 
INNER JOIN pizza_runner.customer_orders AS t2 
ON t1.order_id = t2. order_id
WHERE t1.cleaned_cancellation IS NULL
GROUP BY t1.order_id
ORDER BY pizza_count DESC
LIMIT 1;
--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH cte_change AS(
  SELECT 
   customer_id,
   CASE WHEN t1.exclusions IN ('null','') THEN NULL
   ELSE exclusions END,
   CASE WHEN t1.extras IN ('', 'null') THEN NULL
   ELSE extras END
  FROM pizza_runner.customer_orders AS t1
  INNER JOIN cleaned_runner AS t2 
  ON t1.order_id = t2.order_id
  WHERE t2.cleaned_cancellation IS NULL
  )
SELECT 
  customer_id,
  SUM(CASE WHEN exclusions IS NULL AND extras IS NULL THEN 1 ELSE 0 END) AS no_changes,
  SUM(CASE WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1 ELSE 0 END) AS at_least_1_change
FROM cte_change
GROUP BY customer_id;
-- 8. How many pizzas were delivered that had both exclusions and extras?
WITH cte_change AS(
  SELECT 
   customer_id,
   CASE WHEN t1.exclusions IN ('null','') THEN NULL
   ELSE exclusions END,
   CASE WHEN t1.extras IN ('', 'null') THEN NULL
   ELSE extras END
  FROM pizza_runner.customer_orders AS t1
  INNER JOIN cleaned_runner AS t2 
  ON t1.order_id = t2.order_id
  WHERE t2.cleaned_cancellation IS NULL
  )
SELECT 
  COUNT(*)
FROM cte_change
WHERE exclusions IS NOT NULL 
  AND extras IS NOT NULL  
-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
  DATE_PART('hour', order_time::TIMESTAMP) AS hour_of_day,
  COUNT(*) AS pizza_count
FROM pizza_runner.customer_orders
GROUP BY hour_of_day
ORDER BY hour_of_day

-- 10. 