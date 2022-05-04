-- 1. What is the total amount each customer spent at the restaurant?
SELECT
  sales.customer_id,
  SUM(menu.price) AS total_sales
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu 
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT DISTINCT 
  customer_id,
  COUNT(DISTINCT order_date)
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;

-- 3. What was the first item(s) from the menu purchased by each customer?
WITH ordered_sales AS (
  SELECT
    sales.customer_id,
    menu.product_name,
    RANK() OVER (
    PARTITION BY sales.customer_id
    ORDER BY sales.order_date
    ) AS order_rank
  FROM dannys_diner.sales
  INNER JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
  )
SELECT DISTINCT * 
FROM ordered_sales 
WHERE order_rank <2 
ORDER BY customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
  menu.product_name,
  COUNT(sales.*) AS total_purchases
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY total_purchases DESC
LIMIT 1;

-- 5. Which item(s) was the most popular for each customer?
WITH customer_cte AS (
  SELECT 
    sales.customer_id,
    menu.product_name,
    COUNT(*) AS item_quantity,
    RANK() OVER (
      PARTITION BY sales.customer_id
      ORDER BY COUNT(*) DESC
        ) AS rank
  FROM dannys_diner.sales
  INNER JOIN dannys_diner.menu
  ON sales.product_id = menu.product_id
  GROUP BY sales.customer_id, menu.product_name
  ORDER BY sales.customer_id
)
SELECT 
  customer_id, 
  product_name, 
  item_quantity
FROM customer_cte 
WHERE rank < 2 
ORDER BY customer_id;

-- 6. Which item was purchased first by the customer after they became a member and what date was it? (including the date they joined)
WITH rank_after_joining AS(
  SELECT 
    members.customer_id,
    members.join_date,
    sales.order_date,
    menu.product_name,
    RANK() OVER (
    PARTITION BY members.customer_id
    ORDER BY sales.order_date - members.join_date
    ) AS rank
  FROM dannys_diner.members
  INNER JOIN dannys_diner.sales
  ON members.customer_id = sales.customer_id
  INNER JOIN dannys_diner.menu
  on sales.product_id = menu.product_id
  WHERE members.join_date <= sales.order_date
  ORDER BY customer_id
  )
SELECT
  customer_id,
  order_date,
  product_name
FROM rank_after_joining
WHERE rank < 2;

-- 7. Which menu item(s) was purchased just before the customer became a member and when?
WITH rank_after_joining AS(
  SELECT 
    members.customer_id,
    members.join_date,
    sales.order_date,
    menu.product_name,
    RANK() OVER (
    PARTITION BY members.customer_id
    ORDER BY members.join_date - sales.order_date 
    ) AS rank
  FROM dannys_diner.members
  INNER JOIN dannys_diner.sales
  ON members.customer_id = sales.customer_id
  INNER JOIN dannys_diner.menu
  on sales.product_id = menu.product_id
  WHERE members.join_date > sales.order_date
  ORDER BY customer_id
  )
SELECT
  customer_id,
  order_date,
  product_name
FROM rank_after_joining
WHERE rank < 2;

-- 8. What is the number of unique menu items and total amount spent for each member before they became a member?
WITH rank_after_joining AS(
  SELECT 
    members.customer_id,
    menu.product_name,
    menu.price,
    SUM(menu.price) OVER (
    PARTITION BY members.customer_id
    ) AS total_spent_before_joining
  FROM dannys_diner.members
  INNER JOIN dannys_diner.sales
  ON members.customer_id = sales.customer_id
  INNER JOIN dannys_diner.menu
  on sales.product_id = menu.product_id
  WHERE members.join_date > sales.order_date
  ORDER BY customer_id
  )
SELECT 
  customer_id,
  COUNT(DISTINCT product_name) AS unique_menu_items,
  total_spent_before_joining
FROM rank_after_joining
GROUP BY customer_id, total_spent_before_joining

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
  sales.customer_id,
  SUM(
  CASE WHEN menu.product_name = 'sushi' then 2 * 10 * menu.price
  ELSE 10 * menu.price
  END) AS abc
FROM dannys_diner.sales
LEFT JOIN dannys_diner.menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT 
  sales.customer_id,
  SUM(
  CASE WHEN sales.order_date BETWEEN members.join_date AND members.join_date + 7 THEN menu.price * 2 * 10
  ELSE 
    CASE WHEN menu.product_name = 'sushi' THEN menu.price * 2 * 10
    ELSE menu.price * 10
    END
  END) AS points
FROM dannys_diner.sales
INNER JOIN dannys_diner.members
ON sales.customer_id = members.customer_id
LEFT JOIN dannys_diner.menu
ON sales.product_id = menu.product_id
WHERE order_date < '2021-02-01'
GROUP BY sales.customer_id
ORDER BY sales.customer_id;