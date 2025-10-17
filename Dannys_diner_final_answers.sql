-- Dannys diner question 1: What is the total amount each customer spent at the restaurant?

SELECT s.Customer_id,
SUM(m.price) As Total_Spent
FROM dannys_diner.Sales s
LEFT JOIN 
dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY Customer_id
;

-- Dannys diner question 2: How many days has each customer visited the restaurant?

SELECT
COUNT(DISTINCT(s.order_date)) AS days_visited,
s.Customer_id
FROM dannys_diner.Sales s
GROUP BY Customer_id;

 -- Dannys diner question 3: What was the first item from the menu purchased by each customer?

SELECT 
r.Customer_id,
r.order_date,
r.product_id,
m.product_name
From
	(select s.*,
		ROW_NUMBER() OVER(PARTITION BY s.Customer_id order by s.order_date) as rnk
	from dannys_diner.Sales s ) r
LEFT JOIN dannys_diner.menu m ON r. product_id = m.product_id
WHERE rnk = 1
ORDER BY Customer_id, product_id
;

-- Dannys diner question 4: What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
s.product_id,
m.product_name,
COUNT(s.product_id) Total_times_ordered
FROM dannys_diner.Sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY product_id, product_name
ORDER BY COUNT(*) DESC
LIMIT 1
;

-- Dannys diner question 5: Which item was the most popular for each customer?

-- Step 3: Final outer layer to filter only the top-ranked (most popular) item per customer
SELECT
    ranked.customer_id,
    m.product_name,
    ranked.count_of_prods
FROM (
    -- Step 2: Add ranking based on purchase count per customer
    SELECT
        agg.customer_id,
        agg.product_id,
        agg.count_of_prods,
        RANK() OVER (
            PARTITION BY agg.customer_id
            ORDER BY agg.count_of_prods DESC
        ) AS rnk
    FROM (
        -- Step 1: Aggregate to count how many times each customer bought each product
        SELECT
            s.customer_id,
            s.product_id,
            COUNT(*) AS count_of_prods
        FROM dannys_diner.sales s
        GROUP BY s.customer_id, s.product_id
    ) AS agg
) AS ranked
-- Step 3 continued: Join to menu to get product names
LEFT JOIN dannys_diner.menu m
    ON ranked.product_id = m.product_id
-- Step 3 continued: Filter to only the top item per customer
WHERE ranked.rnk = 1
ORDER BY ranked.customer_id;

-- Dannys diner question 6: Which item was purchased first by the customer after they became a member?
SELECT
organised.Customer_id,
organised.order_date,
organised.product_id,
m.product_name,
organised.join_date
FROM(
	SELECT 
	a.Customer_id,
	a.order_date,
	a.product_id,
	a.join_date,
	ROW_NUMBER() OVER(PARTITION BY Customer_id ORDER BY order_date ASC) AS Frst_order
	FROM( 
		SELECT
		s.Customer_id,
		s.order_date,
		s.product_id,
		m.join_date
		FROM dannys_diner.Sales s
		LEFT JOIN dannys_diner.members m
		ON s.Customer_id = m.customer_id
		WHERE order_date >= join_date) a
        ) AS organised
LEFT JOIN Dannys_diner.menu m
ON organised.product_id = m.product_id 
WHERE Frst_order = 1
;

-- Danny's diner question 7: Which item was purchased just before the customer became a member?
SELECT
organised.Customer_id,
organised.order_date,
organised.product_id,
m.product_name,
organised.join_date
FROM(
	SELECT 
	a.Customer_id,
	a.order_date,
	a.product_id,
	a.join_date,
	ROW_NUMBER() OVER(PARTITION BY Customer_id ORDER BY order_date DESC) AS lst_order
	FROM( 
		SELECT
		s.Customer_id,
		s.order_date,
		s.product_id,
		m.join_date
		FROM dannys_diner.Sales s
		LEFT JOIN dannys_diner.members m
		ON s.Customer_id = m.customer_id
		WHERE order_date < join_date) a
        ) AS organised
LEFT JOIN Dannys_diner.menu m
ON organised.product_id = m.product_id 
WHERE lst_order = 1
;

-- Danny's diner question 8: What is the total items and amount spent for each member before they became a member?

with customer_orders as (SELECT
organised.Customer_id,
organised.order_date,
organised.product_id,
m.product_name,
m.price,
organised.join_date
FROM(
	SELECT 
	a.Customer_id,
	a.order_date,
	a.product_id,
	a.join_date
	FROM( 
		SELECT
		s.Customer_id,
		s.order_date,
		s.product_id,
		m.join_date
		FROM dannys_diner.Sales s
		LEFT JOIN dannys_diner.members m
		ON s.Customer_id = m.customer_id
		WHERE order_date < join_date) a
        ) AS organised
LEFT JOIN Dannys_diner.menu m
ON organised.product_id = m.product_id) 
SELECT
Customer_id,
COUNT(product_id) AS total_products,
SUM(price) AS total_spent
FROM customer_orders
GROUP BY Customer_id
;


-- Danny'a diner question 9: If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- For this i am assuming points can only be gained by membership customers, otherwise it seems to defeat the business case use of a membership. therefore my solution will reflect this.n

SELECT 
s.Customer_id,
SUM(
	CASE
		WHEN c.product_name = 'sushi' then c.price * 20 
		else c.price *10
	END) AS total_points_earned
FROM 
	(Dannys_diner.Sales s
		INNER JOIN Dannys_diner.members m ON 
		s.Customer_id = m.customer_id
		AND s.order_date >= m.join_date 
)
LEFT JOIN  Dannys_diner.menu c ON
	s.product_id = c.product_id
GROUP BY Customer_id
;

-- Danny'a diner question 10: In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

With jan_sales AS(
SELECT 
s.Customer_id,
SUM(
	CASE
		WHEN s.order_date BETWEEN m.join_date AND DATE_ADD(m.join_date, INTERVAL 6 DAY) then c.price * 20
        WHEN c.product_name = 'sushi' then c.price * 20 
		else c.price *10
	END) AS total_points_earned
FROM 
	(Dannys_diner.Sales s
		INNER JOIN Dannys_diner.members m ON 
		s.Customer_id = m.customer_id
		AND s.order_date >= m.join_date 
)
LEFT JOIN  Dannys_diner.menu c ON
	s.product_id = c.product_id
WHERE s.order_date <= '2021-01-31'
GROUP BY Customer_id
)

SELECT *
FROM jan_sales
;


SELECT
s.Customer_id,
s.order_date,
m.product_name,
m.price,
CASE 
WHEN c.join_date IS NULL THEN 'N'
WHEN s.order_date >= c.join_date   THEN 'Y'
ELSE 'N' 
END AS Member
FROM dannys_diner.Sales s
LEFT JOIN dannys_diner.menu m 
ON s.product_id = m.product_id
LEFT JOIN dannys_diner.members c
ON s.Customer_id = c.customer_id
;



