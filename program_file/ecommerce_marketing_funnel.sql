CREATE TABLE ecommerce(
	event_time TIMESTAMP,
	event_type VARCHAR(20),
	product_id BIGINT,
	category_id BIGINT,
	category_code VARCHAR(100),
	brand VARCHAR(100),
	price DECIMAL(10,2),
	user_id BIGINT,
	user_session VARCHAR(100)
);

--Previewing the data
SELECT * FROM ecommerce LIMIT 10;

--Checking Missing values
SELECT COUNT(*) AS total_rows,
		COUNT(user_id) AS user_id_count,
		COUNT(event_type) AS event_type_count,
		COUNT(event_time) AS event_time_count
FROM ecommerce;

UPDATE ecommerce
SET category_code = 'Unknown'
WHERE category_code IS NULL;

UPDATE cleaned_data
SET category_code = 'Unknown'
WHERE category_code IS NULL;

--Remove duplicates
CREATE TABLE cleaned_data AS
SELECT DISTINCT *
FROM ecommerce;

--Convert Date Format
SELECT event_time,
		DATE(event_time) AS event_date
FROM cleaned_data;

--FUNNEL METRICS
--Overall Funnel Count
SELECT 
	COUNT(CASE WHEN event_type = 'view' THEN 1 END) AS views,
	COUNT(CASE WHEN event_type = 'cart' OR event_type = 'purchase' THEN 1 END) AS engages,
	COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS purchases
from cleaned_data;

--Conversion Rates
SELECT 
	COUNT(CASE WHEN event_type = 'view' THEN 1 END) AS views,
	COUNT(CASE WHEN event_type = 'cart' OR event_type = 'purchase' THEN 1 END) AS engages,
	COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS purchases,
	
	ROUND(
		COUNT(CASE WHEN event_type IN ('cart','purchase') THEN 1 END)*100.0 /
		COUNT(CASE WHEN event_type = 'view' THEN 1 END),4
	) AS view_to_engage_rate,
	
	ROUND(
		COUNT(CASE WHEN event_type = 'purchase' THEN 1 END)*100.0 /
		COUNT(CASE WHEN event_type IN ('cart','purchase') THEN 1 END),4
	) AS engage_to_purchase_rate,

	ROUND(
		COUNT(CASE WHEN event_type = 'purchase' THEN 1 END)*100.0 /
		COUNT(CASE WHEN event_type = 'view' THEN 1 END),4
	) AS overall_conersion_rate
FROM cleaned_data;

--USER LEVEL FUNNEL
--Unique Users per Stage
SELECT 
	COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS users_view,
	COUNT(DISTINCT CASE WHEN event_type = 'cart' OR event_type = 'purchase' THEN user_id END) AS users_engages,
	COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS users_purchase
FROM cleaned_data;

--User Journey classification
SELECT
	user_id,
	MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS viewed,
	MAX(CASE WHEN event_type = 'cart' OR event_type = 'purchase' THEN 1 ELSE 0 END) AS engaged,
	MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
FROM cleaned_data
GROUP BY user_id;

CREATE TABLE user_funnel AS
SELECT 
	user_id,
	MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS viewed,
	MAX(CASE WHEN event_type = 'cart' OR event_type = 'purchase' THEN 1 ELSE 0 END) AS engaged,
	MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
FROM cleaned_data
GROUP BY user_id;

SELECT COUNT(*) AS cnts
FROM user_funnel
WHERE viewed =1 and engaged =1 and purchased =1;

--Drop-off Analysis
SELECT
	COUNT(*) AS total_users,
	SUM(viewed) AS viewed_users,
	SUM(engaged) AS engaged_users,
	SUM(purchased) AS purchase_users,
	
	ROUND(
		(SUM(viewed) - SUM(engaged))*100.0 / SUM(viewed) ,4
	) AS drop_view_to_cart,
	
	ROUND(
		(SUM(engaged) - SUM(purchased))*100.0 / SUM(engaged) ,4
	) AS drop_engage_to_purchase
FROM user_funnel;

SELECT 
    COUNT(*) AS users_with_purchase_no_cart
FROM user_funnel
WHERE purchased = 1 AND engaged = 0;

--CATEGORY ANALYSIS
--Funnel By Category
SELECT 
	category_code,
	COUNT(CASE WHEN event_type = 'view' THEN 1 END) AS views,
	COUNT(CASE WHEN event_type IN ('cart','purchase') THEN 1 END) AS engages,
	COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS purchases
FROM cleaned_data
GROUP BY category_code
ORDER BY purchases DESC;

--Category Conversion Rate
SELECT 
	category_code,
	
	COUNT(CASE WHEN event_type = 'view' THEN 1 END) AS views,
	COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS purchases,
	
	ROUND(
		COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) * 100.0 /
		COUNT(CASE WHEN event_type = 'view' THEN 1 END), 4
	) AS conversion_rate
FROM cleaned_data
GROUP BY category_code
ORDER BY conversion_rate DESC;

--TIME ANALYSIS
--Daily Funnel Trend
SELECT 
	DATE(event_time) AS date,
	
	COUNT(CASE WHEN event_type = 'view' THEN 1 END) AS views,
	COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS purchases
FROM cleaned_data
GROUP BY DATE(event_time)
ORDER BY date;

--Monthly Trend
SELECT 
	EXTRACT(MONTH FROM event_time) AS month,
	COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS purchases
FROM cleaned_data
GROUP BY month
ORDER BY month;

--REVENUE ANALYSIS 
--Total Revenue
SELECT 
	SUM(price) AS total_revenue
FROM cleaned_data
WHERE event_type = 'purchase';

--Average Order Value(AOV)
SELECT
	ROUND(SUM(PRICE) * 100.0 /COUNT(*),2) AS avg_order_value
FROM cleaned_data
WHERE event_type = 'purchase';

SELECT 
	SUM(CASE WHEN event_type='purchase' THEN price ELSE 0 END) AS total_revenue,
	ROUND(AVG(CASE WHEN event_type='purchase' THEN price END),2) AS avg_order_value
FROM cleaned_data;


--Top Performing Products
SELECT 
	product_id,
	COUNT(product_id) AS purchases,
	SUM(price) AS revenue
FROM cleaned_data
WHERE event_type = 'purchase'
GROUP BY product_id
ORDER BY revenue DESC
LIMIT 10;

select * from user_funnel;

copy user_funnel TO '/Users/vijaykumar/Desktop/future_intern/Task3/dashboard/data/user_funnel.csv' DELIMITER ',' CSV HEADER;