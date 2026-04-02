-- Monday Coffee -- Data Analysis 
SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Data Analysis


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
SELECT 
    city_name,
    ROUND((population * 0.25) / 1000000.0, 2) AS coffee_consumers_in_millions,
    city_rank
FROM city
ORDER BY 2 DESC;

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
SELECT 
    SUM(total) AS total_revenue
FROM sales
WHERE 
    YEAR(sale_date) = 2023
    AND DATEPART(QUARTER, sale_date) = 4;

    SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
WHERE 
    YEAR(s.sale_date) = 2023
    AND DATEPART(QUARTER, s.sale_date) = 4
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
    p.product_name,
    COUNT(s.sale_id) AS total_orders
FROM products p
LEFT JOIN sales s ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city
SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_cx,
    ROUND(
        CAST(SUM(s.total) AS DECIMAL(10,2)) /
        CAST(COUNT(DISTINCT s.customer_id) AS DECIMAL(10,2)), 
    2) AS avg_sale_pr_cx
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN city ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table AS (
    SELECT 
        city_name,
        ROUND((population * 0.25) / 1000000.0, 2) AS coffee_consumers
    FROM city
),
customers_table AS (
    SELECT 
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_cx
    FROM sales s
    JOIN customers c ON c.customer_id = s.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
)
SELECT 
    ct.city_name,
    ct.coffee_consumers,
    cust.unique_cx
FROM city_table ct
JOIN customers_table cust 
ON ct.city_name = cust.city_name;

-- Q6 Top 3 Products per City

SELECT *
FROM (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER(
            PARTITION BY ci.city_name 
            ORDER BY COUNT(s.sale_id) DESC
        ) AS rank
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    JOIN customers c ON c.customer_id = s.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
) t
WHERE rank <= 3;

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products

SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_cx
FROM city ci
LEFT JOIN customers c ON c.city_id = ci.city_id
JOIN sales s ON s.customer_id = c.customer_id
GROUP BY ci.city_name;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions

WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            CAST(SUM(s.total) AS DECIMAL(10,2)) /
            CAST(COUNT(DISTINCT s.customer_id) AS DECIMAL(10,2)), 
        2) AS avg_sale_pr_cx
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT city_name, estimated_rent
    FROM city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_cx,
    ct.avg_sale_pr_cx,
    ROUND(
        CAST(cr.estimated_rent AS DECIMAL(10,2)) /
        CAST(ct.total_cx AS DECIMAL(10,2)), 
    2) AS avg_rent_per_cx
FROM city_rent cr
JOIN city_table ct ON cr.city_name = ct.city_name
ORDER BY avg_sale_pr_cx DESC;

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city
WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        MONTH(sale_date) AS month,
        YEAR(sale_date) AS year,
        SUM(s.total) AS total_sale
    FROM sales s
    JOIN customers c ON c.customer_id = s.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, YEAR(sale_date), MONTH(sale_date)
),
growth_ratio AS (
    SELECT
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale, 1) OVER(
            PARTITION BY city_name 
            ORDER BY year, month
        ) AS last_month_sale
    FROM monthly_sales
)
SELECT
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(
        (cr_month_sale - last_month_sale) * 100.0 / last_month_sale,
    2) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;

-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            CAST(SUM(s.total) AS DECIMAL(10,2)) /
            CAST(COUNT(DISTINCT s.customer_id) AS DECIMAL(10,2)), 
        2) AS avg_sale_pr_cx
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name,
        estimated_rent,
        ROUND((population * 0.25) / 1000000.0, 3) AS estimated_coffee_consumer
    FROM city
)
SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent,
    ct.total_cx,
    cr.estimated_coffee_consumer,
    ct.avg_sale_pr_cx,
    ROUND(
        CAST(cr.estimated_rent AS DECIMAL(10,2)) /
        CAST(ct.total_cx AS DECIMAL(10,2)), 
    2) AS avg_rent_per_cx
FROM city_rent cr
JOIN city_table ct ON cr.city_name = ct.city_name
ORDER BY total_revenue DESC;

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.