--Analysis 1 --
--Q1. Rounding Average Payment Values--
SELECT payment_type,ROUND(AVG(payment_value)) AS rounded_avg_payment 
FROM amazon_brazil.payments 
GROUP BY payment_type
ORDER BY rounded_avg_payment ASC;

--Q2. Percentage of Total Orders by Payment Type--
SELECT payment_type,ROUND(COUNT(DISTINCT order_id) * 100.0 / (SELECT COUNT(DISTINCT order_id) 
FROM amazon_brazil.payments), 1) AS percentage_orders
FROM amazon_brazil.payments 
GROUP BY payment_type 
ORDER BY percentage_orders DESC;

--Q3. Find Products Priced Between 100 and 500 BRL & Smart in name--
SELECT DISTINCT oi.product_id, price 
FROM amazon_brazil.product p JOIN amazon_brazil.order_items oi ON p.product_id = oi.product_id
WHERE p.product_category_name LIKE '%smart%' AND oi.price BETWEEN 100 AND 500 
ORDER BY oi.price DESC;

--Q4. Determine the Top 3 Months with the Highest Total Sales--
SELECT TO_CHAR(order_purchase_timestamp, 'YYYY-MM') AS order_month,
SUM(payment_value) AS total_sales
FROM amazon_brazil.orders o
JOIN amazon_brazil.payments p ON o.order_id = p.order_id
GROUP BY TO_CHAR(order_purchase_timestamp, 'YYYY-MM')
ORDER BY total_sales DESC
LIMIT 3;

--Q5. Product Categories With Significant Price Variation--
SELECT distinct product_category_name, MAX(price) - MIN(price) AS price_difference 
FROM amazon_brazil.product p JOIN amazon_brazil.order_items oi ON p.product_id = oi.product_id
GROUP BY product_category_name 
HAVING MAX(price) - MIN(price) > 500 
ORDER BY price_difference DESC;

--Q6. Payment Types with the Most Consistent Transaction Amounts--
SELECT payment_type, STDDEV(payment_value) AS std_deviation 
FROM amazon_brazil.payments 
GROUP BY payment_type 
ORDER BY std_deviation ASC;

--Q7. Identify Products with Missing or Incomplete Product Category Names--
SELECT product_id, product_category_name 
FROM amazon_brazil.product 
WHERE product_category_name IS NULL OR LENGTH(product_category_name) = 1;

--Analysis 2--
--Q1. Identify Popular Payment Types by Order Value Segments--
SELECT 
CASE 
	WHEN payment_value < 200 THEN 'Low (<200 BRL)' 
	WHEN payment_value BETWEEN 200 AND 1000 THEN 'Medium (200-1000 BRL)'
	ELSE 'High (>1000 BRL)' 
END AS order_value_segment, payment_type, COUNT(*) AS count 
FROM amazon_brazil.payments 
GROUP BY order_value_segment, payment_type
ORDER BY count DESC;

--Q2. Price Range and Average Price by Product Category--
SELECT product_category_name, MIN(price) AS min_price, MAX(price) AS max_price, AVG(price) AS avg_price
FROM amazon_brazil.product p JOIN amazon_brazil.order_items oi ON p.product_id = oi.product_id 
GROUP BY product_category_name
ORDER BY avg_price DESC;

--Q3. Identify Customers with Multiple Orders--
Select customer_id, count(*) as total_orders
from amazon_brazil.orders
group by customer_id
having count(*) > 1
order by total_orders desc;

--Q4. Categorize Customers Based on Purchase History--
CREATE TEMPORARY TABLE customer_types AS
SELECT  o.customer_id,
CASE 
    WHEN COUNT(o.order_id) = 1 THEN 'New'
    WHEN COUNT(o.order_id) BETWEEN 2 AND 4 THEN 'Returning'
    WHEN COUNT(o.order_id) > 4 THEN 'Loyal'
  END AS customer_type
FROM amazon_brazil.orders o
GROUP BY o.customer_id;
SELECT  customer_id,customer_type 
FROM customer_types ;
SELECT CUSTOMER_TYPE,COUNT(*) AS COUNT
FROM CUSTOMER_TYPES
GROUP BY CUSTOMER_TYPE ;

--Q5. Categorize Customers Based on Purchase History--
SELECT p.product_category_name, SUM(oi.price) AS total_revenue 
FROM amazon_brazil.product p JOIN amazon_brazil.order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_category_name 
ORDER BY total_revenue DESC LIMIT 5;

--Analysis 3--
--Q1. Total Sales for Each Season--
SELECT season, SUM(price) AS total_sales 
FROM 
(SELECT oi.price,
CASE 
	WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (3, 4, 5) THEN 'Spring'
	WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (6, 7, 8) THEN 'Summer' 
	WHEN EXTRACT(MONTH FROM o.order_purchase_timestamp) IN (9, 10, 11) THEN 'Autumn'
	ELSE 'Winter'
END AS season 
FROM amazon_brazil.orders o JOIN amazon_brazil.order_items oi ON o.order_id = oi.order_id) AS season_sales 
GROUP BY season
ORDER BY total_sales desc;

--Q2. Products With Sales Quantity Above The Overall Average--
SELECT product_id, total_quantity_sold 
FROM (SELECT product_id, COUNT(order_item_id) AS total_quantity_sold 
FROM amazon_brazil.order_items
GROUP BY product_id) AS product_sales 
WHERE total_quantity_sold > (SELECT AVG(total_quantity_sold) 
FROM (SELECT COUNT(order_item_id) AS total_quantity_sold
FROM amazon_brazil.order_items 
GROUP BY product_id) AS avg_sales);

--Q3. Monthly Revenue Trends--
SELECT EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month,SUM(oi.price) AS total_revenue 
FROM amazon_brazil.orders o
JOIN amazon_brazil.order_items oi ON o.order_id = oi.order_id 
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018 
GROUP BY month
ORDER BY month;

--Q4. Customers into segments based on purchase frequency --
WITH CustomerSegmentation AS 
(SELECT customer_id, COUNT(order_id) AS order_count, 
CASE 
	WHEN COUNT(order_id) <= 2 THEN 'Occasional'
	WHEN COUNT(order_id) BETWEEN 3 AND 5 THEN 'Regular'
	ELSE 'Loyal' 
END AS customer_type 
FROM amazon_brazil.orders
GROUP BY customer_id) 
SELECT customer_type, COUNT(*) AS count FROM CustomerSegmentation 
GROUP BY customer_type 
ORDER BY count DESC;

--Q5. Top 20 customers by average order value --
WITH order_totals AS (
  SELECT 
    O.customer_id,
    O.order_id,
    SUM(oi.price) AS order_value
  FROM amazon_brazil.orders o
  JOIN amazon_brazil.order_items oi ON o.order_id = oi.order_id
  GROUP BY o.customer_id, o.order_id
),
customer_avg_order AS (
  SELECT 
    Customer_id,
    AVG(order_value) AS avg_order_value
  FROM order_totals
  GROUP BY customer_id
)
SELECT 
  Customer_id,
  avg_order_value,
  RANK() OVER (ORDER BY avg_order_value DESC) AS customer_rank
FROM customer_avg_order
LIMIT 20;

--Q6. Compute cumulative sales month by month for each product--
WITH recursive product_sales AS (
  SELECT 
    oi.product_id,
    DATE_TRUNC('month', o.order_purchase_timestamp) AS sale_month,    SUM(oi.price) AS monthly_sales
  FROM amazon_brazil.order_items oi
  JOIN amazon_brazil.orders o ON oi.order_id = o.order_id
  GROUP BY oi.product_id, DATE_TRUNC('month', o.order_purchase_timestamp)
),
recursive_sales AS (
   SELECT  ps.product_id, ps.sale_month,ps.monthly_sales, ps.monthly_sales AS total_sales
  FROM product_sales ps
  WHERE NOT EXISTS (
    SELECT 1 FROM product_sales ps2 
    WHERE ps2.product_id = ps.product_id 
      AND ps2.sale_month < ps.sale_month
  )
UNION ALL
  SELECT  ps.product_id,ps.sale_month,ps.monthly_sales,
  rs.total_sales + ps.monthly_sales AS total_sales
  FROM product_sales ps
  JOIN recursive_sales rs 
    ON ps.product_id = rs.product_id 
    AND ps.sale_month = rs.sale_month + INTERVAL '1 month'
)
SELECT product_id, sale_month, total_sales
FROM recursive_sales
ORDER BY product_id, sale_month;

--Q7. Total monthly sales for each payment method and calculate the month-over-month growth rate for 2018 --
WITH monthly_sales AS (
  SELECT     payment_type,
    TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS sale_month,    SUM(p.payment_value) AS monthly_total
  FROM amazon_brazil.payments p
  JOIN amazon_brazil.orders o ON p.order_id = o.order_id
  WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018
  GROUP BY payment_type, TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM')
),
sales_with_lag AS (
  SELECT 
    payment_type,
    sale_month,
    monthly_total,
    LAG(monthly_total) OVER (PARTITION BY payment_type ORDER BY sale_month) AS prev_month_total
  FROM monthly_sales
)
SELECT  payment_type,
  sale_month,
  monthly_total,
  ROUND(100.0 * (monthly_total - COALESCE(prev_month_total, 0)) / NULLIF(prev_month_total, 0), 2  ) AS monthly_change
FROM sales_with_lag
ORDER BY payment_type, sale_month;