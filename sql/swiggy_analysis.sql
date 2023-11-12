/* CASE STUDY ON FOOD DELIVERY DATABASE

Questions:
1. Find customers who have never ordered
2. Average Price/dish
3. Find the top restaurant in terms of the number of orders for a given month
4. restaurants with monthly sales greater than 900 for the month of May
5. Show all orders with order details for a particular customer (Ankit) in a particular date range(10/6-10/7)
6. Find restaurants with max repeated customers 
7. Month over month revenue growth of swiggy
8. Customer - favorite food
9. Find names of most loyal customers for all restaurants
10. Month over month revenue growth of a restaurant (ID=2)*/

-- 1. Find customers who have never ordered
SELECT
	user_id,
    name
FROM users
WHERE user_id NOT IN(
	SELECT orders.user_id 
    FROM orders);
    
-- 2. Average Price/dish
SELECT 
	food.f_name,
    AVG(menu.price) AS avg_price
FROM menu JOIN food ON menu.f_id=food.f_id
GROUP BY 1;
    
-- 2.Find the top restaurant in terms of the number of orders.
SELECT 
	r_id,
	COUNT(CASE WHEN orders.r_id=1 THEN order_id ELSE NULL END) AS rest1_orders,
	COUNT(CASE WHEN orders.r_id=2 THEN order_id ELSE NULL END) AS rest2_orders,
	COUNT(CASE WHEN orders.r_id=3 THEN order_id ELSE NULL END) AS rest3_orders,
	COUNT(CASE WHEN orders.r_id=4 THEN order_id ELSE NULL END) AS rest4_orders
FROM orders
GROUP BY 1;


-- 3. Find the top restaurant in terms of the number of orders in June

-- METHOD 1: LONGER USING CASE STATEMENT
SELECT
	r_id,
	COUNT(CASE WHEN orders.r_id=1 THEN order_id ELSE NULL END) AS rest1_orders,
	COUNT(CASE WHEN orders.r_id=2 THEN order_id ELSE NULL END) AS rest2_orders,
	COUNT(CASE WHEN orders.r_id=3 THEN order_id ELSE NULL END) AS rest3_orders,
	COUNT(CASE WHEN orders.r_id=4 THEN order_id ELSE NULL END) AS rest4_orders,
	MONTHNAME(date) AS monthh
FROM orders
WHERE MONTHNAME(date) LIKE 'June'
GROUP BY 1,6
ORDER BY r_id ASC;

-- Restaurant 2

SELECT restaurants.r_id,restaurants.r_name
FROM restaurants;

-- SECOND METHOD: SIMPLER METHOD
SELECT restaurants.r_name,COUNT(orders.order_id) AS total_orders
FROM orders
	JOIN restaurants ON orders.r_id=restaurants.r_id
WHERE MONTHNAME(date) LIKE 'June'
GROUP BY 1
ORDER BY 2 DESC;

-- ANSWER: KFC

-- 4. Find out restaurants with monthly sales greater than 900 for June
SELECT orders.r_id, restaurants.r_name, SUM(orders.amount) AS sales
FROM orders 
		JOIN restaurants ON orders.r_id=restaurants.r_id
WHERE MONTHNAME(date) LIKE 'May'
GROUP BY 1,2
ORDER BY 3 DESC;

-- Answer: dominos

-- 5. Show all orders with order details for ANKIT in 10th July to 15th June

SELECT *
FROM users;

SELECT
	orders.order_id,
    orders.date,
    order_details.f_id,
    food.f_name,
    restaurants.r_name
FROM orders 
	JOIN restaurants ON orders.r_id=restaurants.r_id
	JOIN order_details ON orders.order_id=order_details.order_id
    JOIN food ON order_details.f_id=food.f_id
WHERE date > '2022-06-10' AND date < '2022-07-10'
	AND orders.user_id=4
ORDER BY 2,3;

-- 6. Find restaurants with max repeated customers 

SELECT restaurants.r_name, COUNT(user_id) AS repeat_customers
FROM (
	SELECT r_id, user_id, COUNT(order_id) AS visits
	FROM orders
	GROUP BY 1,2
	HAVING COUNT(order_id) > 1
    ) AS subquery
JOIN restaurants ON subquery.r_id=restaurants.r_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- Answer: Restaurant with ID 2, i.2. KFC

	
-- 7. Find out Month over month revenue growth of swiggy
SELECT 
	month_number,
    month, 
    revenue,
    LAG(revenue) OVER(ORDER BY month_number ASC) AS previous_month_revenue,
    ((revenue-LAG(revenue) OVER(ORDER BY month_number ASC))/LAG(revenue) OVER(ORDER BY month_number ASC))*100 AS mothly_growth_rate
FROM
(
	SELECT MONTHNAME(date) AS month, MONTH(date) AS month_number, SUM(amount) AS revenue
	FROM orders
	GROUP BY 1,2
    ORDER BY month_number ASC
) AS monthly_revenue
GROUP BY 1,2
ORDER BY 1 ASC;

-- 8. Find out the favourite food of each user
CREATE TEMPORARY TABLE user_food_freq
SELECT 
	users.name AS username,
	orders.user_id AS user_id,
	order_details.f_id AS food_id,
    	food.f_name AS dish_name,
	COUNT(order_details.f_id) AS order_frequency
FROM users
	JOIN orders ON users.user_id=orders.user_id
	JOIN order_details ON orders.order_id=order_details.order_id
	JOIN food ON order_details.f_id=food.f_id
GROUP BY 1,2,3,4
ORDER BY 5 ASC;

SELECT *
FROM user_food_freq;

SELECT
	username,
    	dish AS fave_dish
FROM(
	SELECT 
		username,
        	dish,
        	ROW_NUMBER() OVER(PARTITION BY username ORDER BY frequency DESC) AS food_rank
	FROM 
		user_food_freq
	) AS userwise_ranked_foods
WHERE food_rank=1;
 

-- 9. Find names of most loyal customers for all restaurants

-- METHOD 1: USING SUBUQERIES AND WINDOW FUNCTION
SELECT 
	restaurants.r_id AS restaurant_id,
    restaurants.r_name AS restaurant,
	COUNT(orders.order_id) AS no_of_orders,
    users.name AS username
FROM orders
	JOIN users ON orders.user_id=users.user_id
    JOIN restaurants ON orders.r_id=restaurants.r_id
WHERE row_num=1
GROUP BY 1,2,4
ORDER BY 1 ASC;

SELECT * 
FROM(
SELECT 
	restaurant_id,
    restaurant,
    no_of_orders,
    username,
    ROW_NUMBER() OVER(PARTITION BY restaurant ORDER BY no_of_orders DESC) AS row_num
FROM
	(
    SELECT 
	restaurants.r_id AS restaurant_id,
    restaurants.r_name AS restaurant,
	COUNT(orders.order_id) AS no_of_orders,
    users.name AS username
FROM orders
	JOIN users ON orders.user_id=users.user_id
    JOIN restaurants ON orders.r_id=restaurants.r_id
GROUP BY 1,2,4
ORDER BY 1 ASC
	) AS subquery
		) AS outer_query -- because we cannot refer to a column alias in the WHERE statement directly
WHERE row_num=1;

-- METHOD 2: USING CTE AND WINDOW FUNCTION

WITH temp_table AS (
	SELECT 
	restaurants.r_id AS restaurant_id,
    restaurants.r_name AS restaurant,
	COUNT(orders.order_id) AS no_of_orders,
    users.name AS username,
	ROW_NUMBER() OVER(PARTITION BY restaurants.r_name ORDER BY COUNT(orders.order_id) DESC) AS row_num
FROM orders
	JOIN users ON orders.user_id=users.user_id
    JOIN restaurants ON orders.r_id=restaurants.r_id
GROUP BY 1,2,4
)

SELECT 
	restaurant_id,
    restaurant,
    no_of_orders,
    username
FROM temp_table
WHERE row_num=1;

	
-- 10. Pull up month over month revenue growth of a restaurant (with ID=2)

SELECT
	MONTH(orders.date) AS month_number,
    MONTHNAME(orders.date) AS month_name,
    SUM(orders.amount) AS revenue
FROM 
	orders
WHERE r_id=2
GROUP BY 1,2;

SELECT 
	month_number,
    month_name,
    revenue as present-month_revenue,
    LAG(revenue) OVER (ORDER BY month_number ASC) AS previous_month_revenue,
    ((revenue-LAG(revenue) OVER (ORDER BY month_number ASC))/ LAG(revenue) OVER (ORDER BY month_number ASC))*100 As monthly_growth
FROM (
SELECT
	MONTH(orders.date) AS month_number,
    MONTHNAME(orders.date) AS month_name,
    SUM(orders.amount) AS revenue
FROM 
	orders
WHERE r_id=2
GROUP BY 1,2
) AS subquery;


    





    


	
	







