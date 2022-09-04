-- Query 1
-- 1. What is the total amount each customer spent at the restaurant?

SELECT
  	customer_id,
    sum(price) total_amount
FROM dannys_diner.sales s
	INNER JOIN dannys_diner.menu m
    	ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Query 2
-- 2. How many days has each customer visited the restaurant?

SELECT
	customer_id,
    COUNT(DISTINCT order_date) num_days
FROM dannys_diner.sales
GROUP BY 1
ORDER BY 2 DESC;

-- Query 3
-- 3. What was the first item from the menu purchased by each customer?

WITH cte AS (
  SELECT
	customer_id,
    product_name,
    ROW_NUMBER() OVER(
      PARTITION BY customer_id
      ORDER BY order_date
      ) num
	FROM dannys_diner.sales s
	INNER JOIN dannys_diner.menu m
    	ON s.product_id = m.product_id
  )
SELECT 
	customer_id,
    product_name
FROM cte
WHERE num = 1;


-- Query 4
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH cte AS (
  SELECT
	s.product_id,
    product_name,
    COUNT(s.product_id) count_of_purchases
  FROM dannys_diner.sales s
      INNER JOIN dannys_diner.menu m
          ON s.product_id = m.product_id
  GROUP BY 1, 2
  ORDER BY count_of_purchases DESC
  LIMIT 1
);
 
-- Most purchased item
SELECT product_name
FROM cte;
 
--  -- How many times did each customer purchase that product?
 SELECT 
	customer_id,
    COUNT(product_id) num_purchased
FROM dannys_diner.sales 
WHERE product_id IN (
  SELECT product_id
  FROM cte
)  
GROUP BY 1;


-- Query 5
-- 5. Which item was the most popular for each customer?

WITH cte AS (
  SELECT
	customer_id,
    product_name,
    COUNT(product_name) cnt
  FROM dannys_diner.sales s
  	INNER JOIN dannys_diner.menu m
  		ON s.product_id = m.product_id
  GROUP BY 1, 2
  ORDER BY 1, 3 DESC
  ),
  
cte2 AS (
  SELECT
	*,
    ROW_NUMBER() OVER(
      PARTITION BY customer_id
      ORDER BY cnt DESC
      ) ranking
   FROM cte
  )
  
SELECT 
	customer_id,
    product_name AS most_popular_product,
    cnt AS purchase_no
FROM cte2
WHERE ranking = 1;


-- Query 6
-- 6. Which item was purchased first by the customer after they became a member?

WITH cte AS (
  SELECT 
	s.customer_id,
	s.product_id,
    product_name,
    ROW_NUMBER() OVER(
      PARTITION BY s.customer_id
      ORDER BY order_date ASC
      ) rn
    FROM dannys_diner.sales s
        INNER JOIN dannys_diner.members m
            ON s.customer_id = m.customer_id
        INNER JOIN dannys_diner.menu me
            ON me.product_id = s.product_id
    WHERE order_date > join_date
)

SELECT
	customer_id,
    product_id,
    product_name
FROM cte
WHERE rn = 1;

-- Query 7
-- 7. Which item was purchased just before the customer became a member?

WITH cte AS (
  SELECT
	s.customer_id,
    s.product_id,
    product_name,
    ROW_NUMBER() OVER(
      PARTITION BY s.customer_id
      ORDER BY order_date DESC
      ) rn
  FROM dannys_diner.sales s
      INNER JOIN dannys_diner.members m
          ON m.customer_id = s.customer_id
      INNER JOIN dannys_diner.menu me
          ON me.product_id = s.product_id
  WHERE order_date < join_date
)

SELECT
	customer_id,
    product_id,
    product_name
FROM cte
WHERE rn = 1;

-- Query 8
-- 8. What is the total items and amount spent for each member before they became a member?

SELECT   
	s.customer_id,
    COUNT(s.product_id) total_items,
    SUM(price) amount_spent
FROM dannys_diner.sales s
	INNER JOIN dannys_diner.menu me
    	ON s.product_id = me.product_id
    INNER JOIN dannys_diner.members m
    	ON m.customer_id = s.customer_id
WHERE order_date < join_date
GROUP BY 1
ORDER BY 1;

-- Query 9
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- how many points would each customer have?

SELECT 
	s.customer_id,
    SUM(
      CASE 
      	WHEN product_name = 'sushi' THEN 20*price ELSE 10*price END
      ) points
FROM dannys_diner.sales s
	INNER JOIN dannys_diner.menu m
    	ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Query 10
-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
	s.customer_id,
    SUM(
      CASE
      	WHEN (order_date >= join_date) 
      		AND (order_date < join_date + INTERVAL'7days') THEN 20*price
      	WHEN product_name = 'sushi' THEN 20*price
      	ELSE 10*price
      	END
      ) points
      
FROM dannys_diner.sales s
	INNER JOIN dannys_diner.menu me
    	ON s.product_id = me.product_id
    INNER JOIN dannys_diner.members m
    	ON m.customer_id = s.customer_id
WHERE order_date < '2021-02-01'
GROUP BY 1;