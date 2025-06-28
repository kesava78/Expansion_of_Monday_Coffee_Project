-- Monday Coffee SCHEMAS

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;

-- Import Rules
-- 1st import to city
-- 2nd import to products
-- 3rd import to customers
-- 4th import to sales


CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);


CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);


CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

-- END of SCHEMAS
select * from city;
select * from customers;
select * from products;
select * from sales;

# Reports & Analysis:
/*1.Coffee Consumers Count
 How many people in each city are estimated to consume coffee, given that 25% of the population does?*/
select city_name,round((population*0.25)/1000000,2) as coffee_consumer,city_rank
from city 
order by coffee_consumer desc;

/*Total Revenue from Coffee Sales
What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?*/
select sum(total) as total_revenue
from sales
where quarter(sale_date)=4 and year(sale_date)=2023;


/*Sales Count for Each Product
How many units of each coffee product have been sold?*/
select p.product_name,count(s.sale_id) as total_orders
from products p 
left join 
sales s
on s.product_id=p.product_id
group by p.product_name
order by total_orders desc;


/*Average Sales Amount per City
What is the average sales amount per customer in each city?*/
select city_name,round(sum(total)/count( distinct cu.customer_id),2) as average
from city c
join customers cu on cu.city_id=c.city_id
join sales s on s.customer_id=cu.customer_id
group by city_name
order by average desc;


/*City Population and Coffee Consumers
Provide a list of cities along with their populations and estimated coffee consumers.*/
with city_table as
(
select city_name,round((population * 0.25)/1000000,2) as coffee_consumers
from city 
) ,
customers_table as(
select c.city_name,count(distinct cu.customer_id) as unique_customer
from sales s
join customers cu on cu.customer_id=s.customer_id
join city c on c.city_id=cu.city_id
group by c.city_name
) 
select ct.city_name,ct.coffee_consumers, cta.unique_customer
from city_table ct
join customers_table cta
on cta.city_name=ct.city_name;


/*Top Selling Products by City
What are the top 3 selling products in each city based on sales volume?*/
select * from
(
select c.city_name,p.product_name,count(s.sale_id) as total_orders,
dense_rank() over (partition by c.city_name order by count(s.sale_id)  desc) as r
from sales s
join products p on s.product_id=p.product_id
join customers cu on cu.customer_id=s.customer_id
join city as c on c.city_id=cu.city_id
group by 1,2
#order by 1,3 desc
) as t1
where r<=3;


/*Customer Segmentation by City
How many unique customers are there in each city who have purchased coffee products?*/
select city_name,count(distinct customer_id) as Unique_customers
from city c
join customers cu on cu.city_id=c.city_id
group by city_name;


/*Average Sale vs Rent
Find each city and their average sale per customer and avg rent per customer*/
with city_table as(
select city_name,count(distinct s.customer_id) as total_cx,round(sum(total)/count( distinct s.customer_id),2) as average_sales
from sales s
join customers cu on cu.customer_id=s.customer_id
join city c on c.city_id=cu.city_id
group by city_name
order by average_sales desc
),
city_rent as(
select city_name,estimated_rent
from city
)
select cr.city_name,cr.estimated_rent,ct.total_cx,ct.average_sales,round(cr.estimated_rent/ct.total_cx,2)as avg_rent_per_customer
from city_rent cr
join city_table ct on cr.city_name=ct.city_name
order by 5 desc;


/*Monthly Sales Growth
Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).*/
with monthly_sales as
(select c.city_name,
month(sale_date) as month,
year(sale_date) as year,
sum(s.total) as total_sale
from sales s 
join customers cu on cu.customer_id=s.customer_id
join city c on c.city_id=cu.city_id
group by 1,2,3
order by 1,3,2
),
growth_ratio as(
select city_name,month,year,total_sale as cr_month_sale,lag(total_sale,1)over(partition by city_name order by year ,month) as last_month_sale
from monthly_sales
)
select city_name,month,year,cr_month_sale,last_month_sale,
round(((cr_month_sale-last_month_sale)/last_month_sale)*100,2) as growth
from growth_ratio


/*Market Potential Analysis
Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer*/
with city_table as(
select city_name,sum(s.total) as total_revenue ,count(distinct s.customer_id) as total_cx,round(sum(total)/count( distinct s.customer_id),2) as average_sales
from sales s
join customers cu on cu.customer_id=s.customer_id
join city c on c.city_id=cu.city_id
group by city_name
order by average_sales desc
),
city_rent as(
select city_name,estimated_rent,population*0.25 as estimated_coffee_consumer
from city
)
select cr.city_name,cr.estimated_rent,ct.total_cx,ct.total_revenue,ct.average_sales,estimated_coffee_consumer,round(cr.estimated_rent/ct.total_cx,2)as avg_rent_per_customer
from city_rent cr
join city_table ct on cr.city_name=ct.city_name
order by  4 desc;






















