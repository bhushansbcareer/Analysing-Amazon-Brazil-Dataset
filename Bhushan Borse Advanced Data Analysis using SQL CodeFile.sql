/* 
A new database was created. Within the new database a new schema amazon_brazil was created 
*/


/* 
Used the CREATE TABLE SQL command to define the schema 
for each table making sure to include all necessary columns 
and set primary keys based on the schema.
*/


-- defining the structure of customers table
CREATE TABLE amazon_brazil.customers (
customer_id varchar PRIMARY KEY,
customer_unique_id varchar,
customer_zip_code_prefix int
);


-- defining the structure of orders table
CREATE TABLE amazon_brazil.orders (
    order_id VARCHAR PRIMARY KEY,
    customer_id VARCHAR,
    order_status VARCHAR,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES amazon_brazil.customers(customer_id)
);


-- defining the structure of payments table
CREATE TABLE amazon_brazil.payments (
    order_id VARCHAR,
    payment_sequential int,
    payment_type VARCHAR,
    payment_installments int,
	payment_value int,
    FOREIGN KEY (order_id) REFERENCES amazon_brazil.orders(order_id)
);


-- defining the structure of sellers table
CREATE TABLE amazon_brazil.seller (
    seller_id VARCHAR PRIMARY KEY,
    seller_zip_code_prefix int
);


-- defining the structure of order_items table
CREATE TABLE amazon_brazil.order_items (
    order_id VARCHAR,
	order_item_id int,
	product_id varchar,
    seller_id VARCHAR,
    shipping_limit_date TIMESTAMP,
    price int,
	freight_value int,
    FOREIGN KEY (order_id) REFERENCES amazon_brazil.orders(order_id),
	FOREIGN KEY (product_id) REFERENCES amazon_brazil.product(product_id),
	FOREIGN KEY (seller_id) REFERENCES amazon_brazil.seller(seller_id)
);


-- defining the structure of product table
CREATE TABLE amazon_brazil.product(
    product_id VARCHAR PRIMARY KEY,
	product_category_name varchar,
	product_name_length int,
	product_description_length int,
	product_photo_qty int,
	product_weight_g int,
	product_length_cm int,
	product_height_cm int,
	product_width_cm int	
);


/* 
Data was fed into respective tables from their csv files 
using the Import/Export tool of PostgreSQL 
*/

-- Checking whether the required data got imported in the tables

select * from amazon_brazil.customers;

select * from amazon_brazil.order_items;

select * from amazon_brazil.orders;

select * from amazon_brazil.payments;

select * from amazon_brazil.product;

select * from amazon_brazil.seller;


-- Analysis - I

/*
1) To simplify its financial reports, Amazon India needs to standardize payment values. 
Round the average payment values to integer (no decimal) for each payment type and display the results sorted in ascending order.

Output: payment_type, rounded_avg_payment
*/

select 
	payment_type, 
	-- average payment value rounded to closest integer
	round(avg(payment_value)) as rounded_avg_payment 
from 
	amazon_brazil.payments
group by 
	payment_type
order by 
	rounded_avg_payment desc;


/*
2) To refine its payment strategy, Amazon India wants to know the distribution of orders by payment type.
Calculate the percentage of total orders for each payment type, rounded to one decimal place, and display them in descending order

Output: payment_type, percentage_orders
*/

select 
	payment_type, 
	-- computing count of order_id for each payment_type, 
	-- dividing with total no. of payments and rounding to find percentage
	round(count(order_id)*100*1.0/
	-- computing total number of payments
	(select count(*) from amazon_brazil.payments),1) as percentage_orders 
from 
	amazon_brazil.payments
group by 
	payment_type
order by 
	percentage_orders desc;


/*
3) Amazon India seeks to create targeted promotions for products within specific price ranges. 
Identify all products priced between 100 and 500 BRL that contain the word 'Smart' in their name. 
Display these products, sorted by price in descending order.

Output: product_id, price
*/

select 
	p.product_id, 
	oi.price
from 
	amazon_brazil.product p
join  -- joining product and order_items tables
	amazon_brazil.order_items oi
on 
	p.product_id = oi.product_id
where 
	-- for products priced between 100 and 500
	oi.price between 100 and 500
and 
	-- for products containing word 'Smart' in their name
	p.product_category_name like '%smart%'
order by 
	oi.price desc;


/*
4) To identify seasonal sales patterns, Amazon India needs to focus on the most successful months. 
Determine the top 3 months with the highest total sales value, rounded to the nearest integer.

Output: month, total_sales
*/

select 
	-- extracting month from date
	TO_CHAR(o.order_delivered_customer_date, 'Month') as month,
	-- caculating sum of price to get total sales
	round(SUM(oi.price)) as total_sales
from 
	amazon_brazil.order_items oi
join -- joining order_items and orders tables
	amazon_brazil.orders o
on 
	oi.order_id = o.order_id
where 
	-- filtering orders which have been delivered
	o.order_status = 'delivered'
group by 
	month
order by 
	total_sales desc
limit 3;


/*
5) Amazon India is interested in product categories with significant price variations. 
Find categories where the difference between the maximum and minimum product prices is greater than 500 BRL.

Output: product_category_name, price_difference
*/

select 
	p.product_category_name, 
	-- computing difference between max and min price
	max(oi.price) - min(oi.price) as price_difference 
from 
	amazon_brazil.order_items oi
join -- joining product and order_items tables
	amazon_brazil.product p
on 
	oi.product_id = p.product_id
group by 
	p.product_category_name
having 
	-- filtering only the product category with difference > 500
	max(oi.price) - min(oi.price) > 500
order by 
	price_difference desc;


/*
6) To enhance the customer experience, Amazon India wants to find which payment types have the most consistent transaction amounts. 
Identify the payment types with the least variance in transaction amounts, sorting by the smallest standard deviation first.

Output: payment_type, std_deviation
*/

select 
	payment_type, 
	-- computing standard deviation for payment value
	round(stddev(payment_value),2) as std_deviation
from 
	amazon_brazil.payments
group by 
	-- grouping by payment type
	payment_type
order by 
	std_deviation;


/*
7) Amazon India wants to identify products that may have incomplete name in order to fix it from their end. 
Retrieve the list of products where the product category name is missing or contains only a single character.

Output: product_id, product_category_name
*/

select 
	product_id, 
	product_category_name 
from 
	amazon_brazil.product
where
	-- product category name with only single character 
	product_category_name like '_'

union all -- combining result of both the queries

select 
	product_id, 
	product_category_name 
from 
	amazon_brazil.product
where 
	-- product category name which is null 
	product_category_name is null;



-- Analysis - II

/*
1) Amazon India wants to understand which payment types are most popular across different order value segments (e.g., low, medium, high). 
Segment order values into three ranges: orders less than 200 BRL, between 200 and 1000 BRL, and over 1000 BRL. 
Calculate the count of each payment type within these ranges and display the results in descending order of count

Output: order_value_segment, payment_type, count
*/

SELECT 
    CASE
		-- segmenting order value as low, medium, high
        WHEN payment_value < 200 THEN 'low'
        WHEN payment_value BETWEEN 200 AND 1000 THEN 'medium'
        WHEN payment_value > 1000 THEN 'high'
    END AS order_value_segment,
    payment_type,
	--  computing count of each payment type within each order value segment
    COUNT(*) as count
FROM 
	amazon_brazil.payments
GROUP BY 
	order_value_segment, payment_type
order by 
	payment_type, count(*) desc ;


/*
2) Amazon India wants to analyse the price range and average price for each product category. 
Calculate the minimum, maximum, and average price for each category, and list them in descending order by the average price.

Output: product_category_name, min_price, max_price, avg_price
*/

select 
	p.product_category_name, 
	-- computing minimum price for product category
	min(oi.price) as min_price,
	-- computing maximum price for product category
	max(oi.price) as max_price, 
	-- computing average price for product category
	round(avg(oi.price),2) as avg_price
from 
	amazon_brazil.order_items oi
join -- joining order_items and product tables
	amazon_brazil.product p
on 
	oi.product_id = p.product_id
group by 
	p.product_category_name
order by 
	avg_price desc;
	

/*
3) Amazon India wants to identify the customers who have placed multiple orders over time. 
Find all customers with more than one order, and display their customer unique IDs along with the total number of orders 
they have placed.

Output: customer_unique_id, total_orders
*/

select 
	c.customer_unique_id, 
	-- counting total number of orders for each customer
	count(o.customer_id) as total_orders
from 
	amazon_brazil.orders o
join -- joining orders and customers tables
	amazon_brazil.customers c
on 
	o.customer_id  = c.customer_id
group by 
	c.customer_unique_id
having 
	-- filtering only customers having more than 1 order
	count(o.customer_id) > 1
order by 
	total_orders desc;


/*
4) Amazon India wants to categorize customers into different types 
('New – order qty. = 1' ;  'Returning' –order qty. 2 to 4;  'Loyal' – order qty. >4) based on their purchase history. 
Use a temporary table to define these categories and join it with the customers table to update and display the customer types.

Output: customer_id, customer_type
*/

with -- creating a temporary table using CTE
temp_table as 
	(
	select 
		customer_id,
		-- counting the total number of orders for each customer id
		count(*) as order_count 
	from 
		amazon_brazil.orders 
	group by 
		customer_id
	)
select 
	c.customer_id,
	case -- segregation of customer_id on basis of order quantity
		when t.order_count = 1 then 'New'
		when t.order_count between 2 and 4 then 'Returning'
		when t.order_count > 4 then 'Loyal' 
		end as customer_type
from 
	amazon_brazil.customers c
join --joining customer and temp_table on common column customer_id
	temp_table t
on 
	c.customer_id = t.customer_id
order by 
	customer_type desc;


/*
5) Amazon India wants to know which product categories generate the most revenue. 
Use joins between the tables to calculate the total revenue for each product category. 
Display the top 5 categories.

Output: product_category_name, total_revenue
*/

select 
	p.product_category_name,
	-- computing total revenue for each product category
	sum(oi.price) as total_revenue
from 
	amazon_brazil.order_items oi
join -- joining order_items and product on common column product_id
	amazon_brazil.product p
on 
	oi.product_id = p.product_id
group by 
	p.product_category_name
order by 
	total_revenue desc
limit 5; -- displaying just first five



-- Analysis - III

/*
1) The marketing team wants to compare the total sales between different seasons. 
Use a subquery to calculate total sales for each season (Spring, Summer, Autumn, Winter) based on order purchase dates, 
and display the results. 
Spring is in the months of March, April and May. 
Summer is from June to August,
Autumn is between September and November 
and rest months are Winter. 

Output: season, total_sales
*/

with  -- creating a temporary table using CTE to determine the season for each order 
	temp_table as 
	(
	select 
		order_id, 
		case 
		when cast(to_char(order_purchase_timestamp, 'mm') as integer) between 3 and 5 then 'Spring'
		when cast(to_char(order_purchase_timestamp, 'mm') as integer) between 6 and 8 then 'Summer'
		when cast(to_char(order_purchase_timestamp, 'mm') as integer) between 9 and 11 then 'Autum'
		else 'Winter' end as season
	from
		amazon_brazil.orders)

select 
	t.season, 
	-- sum aggregation of price to calculate total sales for each season
	sum(oi.price) as total_sales
from 
	amazon_brazil.order_items oi
join -- joining order_items and temp_table on common column order_id
	temp_table t
on 
	oi.order_id = t.order_id
group by 
	t.season;


/*
2) The inventory team is interested in identifying products that have sales volumes above the overall average. 
Write a query that uses a subquery to filter products with a total quantity sold above the average quantity.

Output: product_id, total_quantity_sold
*/

select 
	product_id,
	-- calculating total quantity sold of each product
	count(product_id) as total_quantity_sold 
from 
	amazon_brazil.order_items
group by 
	product_id
having 
	-- filtering only products with quantity sold above overall average
	count(product_id) > 
	(select 
		round(count(*)*1.0/count(distinct product_id),2) 
	from 
		amazon_brazil.order_items)
order by 
	total_quantity_sold desc;


/*
3) To understand seasonal sales patterns, the finance team is analysing the monthly revenue trends over the past year (year 2018). 
Run a query to calculate total revenue generated each month and identify periods of peak and low sales. 
Export the data to Excel and create a graph to visually represent revenue changes across the months. 

Output: month, total_revenue
*/

select 
	-- extracting month from order delivered customer date
	TO_CHAR(o.order_delivered_customer_date, 'Month') as month,
	-- computing total revenue using SUM () aggregate function
	round(SUM(oi.price)) as total_revenue
from 
	amazon_brazil.order_items oi
join -- joining order_items and orders tables on common column order id
	amazon_brazil.orders o
on 
	oi.order_id = o.order_id
where --filtering records with delivered status and year as 2018
	o.order_status = 'delivered' 
	and 
	TO_CHAR(o.order_delivered_customer_date, 'yyyy') = '2018'
group by 
	month
order by 
	total_revenue desc;


/*
4) A loyalty program is being designed  for Amazon India. 
Create a segmentation based on purchase frequency: ‘Occasional’ for customers with 1-2 orders, ‘Regular’ for 3-5 orders, 
and ‘Loyal’ for more than 5 orders. 
Use a CTE to classify customers and their count and generate a chart in Excel to show the proportion of each segment.

Output: customer_type, count
*/

with -- creating a temporary table to include customer id and 
	-- assigning group to customers on basis of number of orders 
	temp_table as 
	(select 
		customer_id,
		-- assigning groups to customers using CASE
		case
		when count(customer_id) between 1 and 2 then 'Occasional'
		when count(customer_id) between 3 and 5 then 'Regular'
		when count(customer_id) > 5 then 'Loyal' end as customer_type
	from 
		amazon_brazil.orders 
	group by 
		customer_id)
select 
	t.customer_type,
	-- computing number of customers present in each customer type
	count(*) as "count"
from 
	temp_table t
group by 
	t.customer_type
order by 
	"count" desc;


/*
5) Amazon wants to identify high-value customers to target for an exclusive rewards program. 
You are required to rank customers based on their average order value (avg_order_value) to find the top 20 customers.

Output: customer_id, avg_order_value, and customer_rank
*/

select 
	o.customer_id,
	-- calculating average order value for each customer
	round(avg(oi.price),2) as avg_order_value,
	-- ranking each customer on the basis of average order value
	dense_rank() over (order by round(avg(oi.price),2) desc) as customer_rank
from 
	amazon_brazil.order_items oi
join -- joining order_items and orders tables on common column order_id
	amazon_brazil.orders o
on 
	oi.order_id = o.order_id
group by 
	o.customer_id
order by 
	avg_order_value desc
	-- fetching only the top 20 customers
limit 20;


/*
6) To understand how different payment methods affect monthly sales growth, Amazon wants to compute the total sales for 
each payment method and calculate the month-over-month growth rate for the past year (year 2018). 
Write query to first calculate total monthly sales for each payment method, then compute the percentage change from the 
previous month.

Output: payment_type, sale_month, monthly_total, monthly_change.
*/

WITH 
	-- using CTE to calculate total monthly sales
	-- and percentage change from previous month for each payment method 
	monthly_sales AS 
	(SELECT
        payment_type,
		-- extracting month and year from order purchase timestamp
		TO_CHAR(o.order_purchase_timestamp, 'MM-YYYY') AS sale_month,
        -- sum aggregation of payment value for each payment type
		SUM(p.payment_value) AS monthly_total
    FROM
        amazon_brazil.orders o
    JOIN -- joining orders and payments tables on common column order_id
		amazon_brazil.payments p 
	ON 
		o.order_id = p.order_id
    WHERE  -- extracting records only for year 2018
        o.order_purchase_timestamp >= '2018-01-01'
        AND 
		o.order_purchase_timestamp < '2018-12-31'
    GROUP BY
        payment_type, sale_month
	),
	monthly_growth AS 
	(SELECT
        payment_type,
        sale_month,
        monthly_total,
		-- fetching total sales for previous month
        LAG(monthly_total) OVER (PARTITION BY payment_type ORDER BY sale_month) AS previous_month_total
    FROM
        monthly_sales
	)
SELECT
    payment_type,
    sale_month,
    monthly_total,
    CASE
        WHEN previous_month_total IS NULL OR previous_month_total = 0 THEN NULL
        ELSE round((monthly_total - previous_month_total)* 100.0 / previous_month_total,3)
    END AS monthly_change
FROM
    monthly_growth
ORDER BY
    payment_type, sale_month;



