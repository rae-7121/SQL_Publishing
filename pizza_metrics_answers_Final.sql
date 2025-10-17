-- Answering Pizza runner questions now:

-- Pizza Metrics: 

-- 1. How many pizzas were ordered?
SELECT COUNT(pizza_id) AS pizza_orders
FROM pizza_runner.cleaned_customer_orders;
-- Answer is 14
-- 2. How many unique customer orders were made?
SELECT 
COUNT(*) 
FROM(
	SELECT DISTINCT
    order_id,
    customer_id
    FROM pizza_runner.cleaned_customer_orders
) AS unique_orders;
-- Alternative solution, 1 covers if data is potentially dirty, with multiple customers attached to one order_id, but this is simpler and easier. 
SELECT COUNT(DISTINCT order_id) AS unique_orders
FROM pizza_runner.cleaned_customer_orders;
-- Answer is 10
-- 3. How many successful orders were delivered by each runner?
SELECT 
runner_id,
COUNT(DISTINCT(order_id)) AS successful_orders
FROM pizza_runner.cleaned_runner_orders
WHERE cleaned_cancellation IS NULL
GROUP BY runner_id;
-- Answers : 1 delivered 4 orders. 2 delivered 3 orders, 3 delivered one order
-- 4. How many of each type of pizza was delivered?
	SELECT
    c.pizza_name,
	b.pizza_id,
	COUNT(b.pizza_id) AS delivered_pizza
	FROM pizza_runner.cleaned_runner_orders a
	INNER JOIN pizza_runner.cleaned_customer_orders b 
		ON a.order_id = b.order_id
    INNER JOIN pizza_runner.pizza_names c
		ON b.pizza_id = c.pizza_id
	WHERE a.cleaned_cancellation IS NULL
	GROUP BY c.pizza_name, b.pizza_id;
-- Answers: pizza ID1 aka Meatlovers, had 9 successful deliveries, 2 aka vegetarian, had 3. 
-- CTE Attempt for question 4- improved flexibiltiy and scaleability:
WITH pizza_orders_overall AS(
	SELECT
    a.order_id,
    a.runner_id,
    a.clean_collection_time as collection_time,
    a.clean_distance as distance_km,
    a.clean_duration as duration_mins,
    a.cleaned_cancellation as cancellation,
	b.customer_id,
    b.pizza_id,
    b.clean_exclusions as exclusions,
    b.cleaned_extras as extras,
    b.order_time as order_timestamp,
    c.pizza_name,
    d.toppings,
    e.registration_date
    FROM pizza_runner.cleaned_runner_orders a
    LEFT JOIN pizza_runner.cleaned_customer_orders b
		ON a.order_id = b.order_id
	LEFT JOIN pizza_runner.pizza_names c
		ON b.pizza_id = c.pizza_id
	LEFT JOIN pizza_runner.pizza_recipes d
		ON b.pizza_id = d.pizza_id
	LEFT JOIN pizza_runner.runners e
		ON a.runner_id = e.runner_id
	)
SELECT
pizza_name,
pizza_id,
COUNT(pizza_id) AS succesful_orders
FROM pizza_orders_overall
WHERE cancellation IS NULL
GROUP BY pizza_name, pizza_id
;
	
-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
WITH pizza_orders_overall AS(
	SELECT
    a.order_id,
    a.runner_id,
    a.clean_collection_time as collection_time,
    a.clean_distance as distance_km,
    a.clean_duration as duration_mins,
    a.cleaned_cancellation as cancellation,
	b.customer_id,
    b.pizza_id,
    b.clean_exclusions as exclusions,
    b.cleaned_extras as extras,
    b.order_time as order_timestamp,
    c.pizza_name,
    d.toppings,
    e.registration_date
    FROM pizza_runner.cleaned_runner_orders a
    LEFT JOIN pizza_runner.cleaned_customer_orders b
		ON a.order_id = b.order_id
	LEFT JOIN pizza_runner.pizza_names c
		ON b.pizza_id = c.pizza_id
	LEFT JOIN pizza_runner.pizza_recipes d
		ON b.pizza_id = d.pizza_id
	LEFT JOIN pizza_runner.runners e
		ON a.runner_id = e.runner_id
	)
SELECT 
customer_id,
pizza_name,
COUNT(pizza_id) AS pizzas_ordered
FROM pizza_orders_overall
GROUP BY customer_id, pizza_name
;
-- 6. What was the maximum number of pizzas delivered in a single order?
WITH pizza_orders_overall AS(
	SELECT
    a.order_id,
    a.runner_id,
    a.clean_collection_time as collection_time,
    a.clean_distance as distance_km,
    a.clean_duration as duration_mins,
    a.cleaned_cancellation as cancellation,
	b.customer_id,
    b.pizza_id,
    b.clean_exclusions as exclusions,
    b.cleaned_extras as extras,
    b.order_time as order_timestamp,
    c.pizza_name,
    d.toppings,
    e.registration_date
    FROM pizza_runner.cleaned_runner_orders a
    LEFT JOIN pizza_runner.cleaned_customer_orders b
		ON a.order_id = b.order_id
	LEFT JOIN pizza_runner.pizza_names c
		ON b.pizza_id = c.pizza_id
	LEFT JOIN pizza_runner.pizza_recipes d
		ON b.pizza_id = d.pizza_id
	LEFT JOIN pizza_runner.runners e
		ON a.runner_id = e.runner_id
	)
SELECT
MAX(pizzas_ordered)
FROM(
    SELECT
order_id,
COUNT(pizza_id) AS pizzas_ordered
FROM pizza_orders_overall
GROUP BY order_id, customer_id) as order_counts
;
-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
WITH pizza_orders_overall AS(
	SELECT
    a.order_id,
    a.runner_id,
    a.clean_collection_time as collection_time,
    a.clean_distance as distance_km,
    a.clean_duration as duration_mins,
    a.cleaned_cancellation as cancellation,
	b.customer_id,
    b.pizza_id,
    b.clean_exclusions as exclusions,
    b.cleaned_extras as extras,
    b.order_time as order_timestamp,
    c.pizza_name,
    d.toppings,
    e.registration_date
    FROM pizza_runner.cleaned_runner_orders a
    LEFT JOIN pizza_runner.cleaned_customer_orders b
		ON a.order_id = b.order_id
	LEFT JOIN pizza_runner.pizza_names c
		ON b.pizza_id = c.pizza_id
	LEFT JOIN pizza_runner.pizza_recipes d
		ON b.pizza_id = d.pizza_id
	LEFT JOIN pizza_runner.runners e
		ON a.runner_id = e.runner_id
	)
    
    SELECT 
    customer_id,
    COUNT(pizza_id) AS delivered_pizzas,
    SUM(CASE 
		WHEN exclusions IS NULL AND extras IS NULL THEN 1 ELSE 0 END) AS 'unchanged',
    SUM(CASE
		WHEN exclusions IS NULL and extras IS NOT NULL THEN 1 ELSE 0 END) AS 'extras_added',
    SUM(CASE
		WHEN exclusions IS NOT NULL and extras IS NULL THEN 1 ELSE 0 END) AS 'exclusions_added'
    FROM pizza_orders_overall
    WHERE cancellation IS NULL
    GROUP BY customer_id
    ;
-- 8. How many pizzas were delivered that had both exclusions and extras?
WITH pizza_orders_overall AS(
	SELECT
    a.order_id,
    a.runner_id,
    a.clean_collection_time as collection_time,
    a.clean_distance as distance_km,
    a.clean_duration as duration_mins,
    a.cleaned_cancellation as cancellation,
	b.customer_id,
    b.pizza_id,
    b.clean_exclusions as exclusions,
    b.cleaned_extras as extras,
    b.order_time as order_timestamp,
    c.pizza_name,
    d.toppings,
    e.registration_date
    FROM pizza_runner.cleaned_runner_orders a
    LEFT JOIN pizza_runner.cleaned_customer_orders b
		ON a.order_id = b.order_id
	LEFT JOIN pizza_runner.pizza_names c
		ON b.pizza_id = c.pizza_id
	LEFT JOIN pizza_runner.pizza_recipes d
		ON b.pizza_id = d.pizza_id
	LEFT JOIN pizza_runner.runners e
		ON a.runner_id = e.runner_id
	)
    SELECT 
    COUNT(pizza_id) AS delivered_pizzas,
	SUM( CASE
		WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1 ELSE 0 END) AS 'exclusions_and_additions'
    FROM pizza_orders_overall
    WHERE cancellation IS NULL
    ;
-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
HOUR(order_time) AS ordered_hr,
COUNT(pizza_id) AS pizzas_ordered
FROM pizza_runner.cleaned_customer_orders
GROUP BY ordered_hr
ORDER BY ordered_hr ASC
;
-- 10. What was the volume of orders for each day of the week?
SELECT
DAYNAME(order_time) as ordered_day,
COUNT(pizza_id) AS pizzas_ordered
FROM pizza_runner.cleaned_customer_orders
GROUP BY ordered_day
ORDER BY pizzas_ordered DESC

