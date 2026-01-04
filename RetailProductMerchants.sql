CREATE DATABASE uber_case_study CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

use uber_case_study;

-- Creating a table for catalog_store

CREATE TABLE catalog_store(
id INT PRIMARY KEY,
name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci);

-- Checking if the data has been fully uploaded for all tables

select count(*)
from catalog_product;

select count(*)
from catalog_productbranches;


select count(*)
from catalog_store;


select count(*) from catalog_storebranch;

select count(*)
from geo_city;

select count(*)
from orders_order;


-- Exploring the datasets

select *
from catalog_product;

select *
from catalog_productbranches;

select *
from catalog_store;

select * 
from catalog_storebranch;

select *
from geo_city;

select *
from orders_order;

-- Order Fulfilment KPI 

-- Found Rate 

-- 1. Calculating Found rate which is the Found products divided by the Total ordered Products.

select round((sum(qty_products_found)/sum(qty_products_ordered))*100,2) as Found_Rate
from orders_order;

select sum(qty_products_ordered) - sum(qty_products_found) as Unfulfilled_items
from orders_order;

-- The Found rate is 89.69% 

-- 2. Finding the total number of orders delivered.

-- Checking if there is a delivery time that is null

select actual_delivery_time
from orders_order
where actual_delivery_time is null;

-- This tells us that there were no orders that were undelivered. Below is the answer to the question of how many orders were delivered.

select count(id) as total_delivered
from orders_order;

-- There were a total of 4556 orders that were delivered.

-- Catalog Assortment KPI 

-- 1. Percentage(%) Out of Stock : Out of stock from all active products.

select *
from catalog_productbranches;

select 
concat(
round((sum((case when availability_status = 'OUT_OF_STOCK' then 1 else 0 end))
/
count(id)) *100,2), '%') as Out_of_Stock
from catalog_productbranches
where active = TRUE;

-- There's 3.50% of products that are out of stock from all active products.

-- 2. Percentage(%) Available : Available Products from all active products.

select *
from catalog_productbranches;


select
concat(
round(sum(case when availability_status = 'AVAILABLE' then 1 else 0 end)/
count(id) * 100,2),'%') as Available_products_percentage
from catalog_productbranches
where active = TRUE;

-- The Available % of active products is 96.48%

-- Find the number of available : Total number of active and available products.

select count(id) as Total_Available_Count
from catalog_productbranches
where availability_status = 'AVAILABLE' and active = TRUE;

-- The total number of active & available products are 114807

-- Now that we have checked the overall metrics for both of our KPI's, i will dive deep into granular details of this data.

-- Query 1: Analyze Found Rate by Store Brand and City.

select cs.name as Store_brand,gc.name as Geo_city,
count(oo.id) as total_orders,
round(sum(oo.qty_products_found)/sum(oo.qty_products_ordered)*100,2) as Found_Rate
from orders_order as oo
join catalog_storebranch as csb on 
oo.shopper_store_branch_id= csb.id
join geo_city as gc on 
csb.city_id = gc.id
join catalog_store as cs on 
csb.store_id = cs.id
group by cs.name, gc.name 
order by Found_Rate desc;

-- Insights : What i can see here is that the Found Rate is extremely high in Valparaiso and La Serena for Store brand - 'Farmacias Ahumada'
-- The lowest Found Rate is in La Serena for Store brand - 'Jumbo' which is 79.24% and it says that a single strategy would not work for all of the store brands for all cities.
-- This means that for every 100 items ordered at this store, nearly 21 are not found
-- leading to a significant negative customer experience and potential order cancellations.

-- Moving to the caatlog assortment KPI to find how that KPI is doing in terms of store brand by city.

-- Finding the % out of stock from all active products by store brand and geo city.

select cs.name as Store_brand,gc.name as Geo_city,
round(
sum(case when cpb.availability_status = 'OUT_OF_STOCK' and cpb.active = TRUE then 1 else 0 end ) * 100
/
sum(case when cpb.active = TRUE then 1 else 0 end),2) as OOS_percent,

round(sum(case when cpb.availability_status = 'AVAILABLE' and cpb.active = TRUE then 1 else 0 end) *100
/
sum(case when cpb.active = TRUE then 1 else 0 end),2) as Available_percent

from catalog_storebranch as csb
join catalog_productbranches as cpb on 
csb.id = cpb.branch_id
join catalog_store as cs on 
csb.store_id = cs.id
join geo_city as gc on 
csb.city_id = gc.id
group by cs.name,gc.name
order by OOS_percent desc;

-- Insights: What i can see here is that the Store brands like Unimarc in La Serena, Jumbo in Santiago, Unimarc in Santiago tend to have a higher OOS % value.

-- In this step i will use a CTE to combine both these queries into one to display them so that i can compare each table for a correlation analysis.

with OrderFulfillmentKPI as (

select cs.name as Store_brand,gc.name as Geo_city,
count(oo.id) as total_orders,
round(sum(oo.qty_products_found)/sum(oo.qty_products_ordered)*100,2) as Found_Rate
from orders_order as oo
join catalog_storebranch as csb on 
oo.shopper_store_branch_id= csb.id
join geo_city as gc on 
csb.city_id = gc.id
join catalog_store as cs on 
csb.store_id = cs.id
group by cs.name, gc.name 
order by Found_Rate desc
),

CatalogAssortmentKPI as (
select cs.name as Store_brand,gc.name as Geo_city,
round(
sum(case when cpb.availability_status = 'OUT_OF_STOCK' and cpb.active = TRUE then 1 else 0 end ) * 100
/
sum(case when cpb.active = TRUE then 1 else 0 end),2) as OOS_percent,
round(sum(case when cpb.availability_status = 'AVAILABLE' and cpb.active = TRUE then 1 else 0 end) *100
/
sum(case when cpb.active = TRUE then 1 else 0 end),2) as Available_percent
from catalog_storebranch as csb
join catalog_productbranches as cpb on 
csb.id = cpb.branch_id
join catalog_store as cs on 
csb.store_id = cs.id
join geo_city as gc on 
csb.city_id = gc.id
group by cs.name,gc.name
order by OOS_percent desc
)

select o.Store_brand,o.Geo_city,o.Found_Rate,c.OOS_percent,c.Available_percent
from OrderFulfillmentKPI as o
join CatalogAssortmentKPI as c on
o.Store_brand = c.Store_brand 
and o.Geo_city=c.Geo_city
order by o.Found_Rate desc ;

-- Final Insights : By merging both these tables, i can draw a direct correlation saying that the Found rate % is directly correlated to low out of stock %.
-- Store Brands 'Farmacias Ahumada' in City 'Valparaiso' have a very low % of Out of Stock whereas 
-- 'Unimarc' in 'La Serena' has a lower Found Rate % & higher OOS %. 


-- I am trying to find another indicator that we could use to track apart from the Order fulfillment KPI & Catalog Assortment KPI.

-- Additional Analytics : Exploring Unfulfilled orders

select cs.name,
gc.name,
count(oo.id) as total_orders,
round(avg(oo.qty_products_ordered - oo.qty_products_found),2) as avg_unfulfilled_orders
from orders_order as oo
join catalog_storebranch as csb on 
oo.shopper_store_branch_id = csb.id
join catalog_store as cs on 
csb.store_id = cs.id
join geo_city as gc on 
csb.city_id = gc.id
group by cs.name, gc.name
order by avg_unfulfilled_orders desc;

-- Insights: On an average, for the store Unimarc in Valparaiso there have been 2.87 orders unfulfilled. 
-- For Jumbo in La Serena, the store has 2.73 orders unfulfilled. Overall, the Store Unimarc seems to be having maximum unfulfilled orders.
-- They are also the stores with a low found rate as shown earlier.

-- Additional Analytics : Finding the % of Out of Stock based on each product category

select cp.name as product_name,
count(cpb.id) as total_active_products,
round(
sum(case when cpb.availability_status = 'OUT_OF_STOCK' then 1 else 0 end) 
/
count(cpb.id) * 100 , 2) as percent_out_of_stock
from catalog_product as cp
join catalog_productbranches as cpb on 
cp.id = cpb.product_id
where cpb.active = TRUE
group by cp.name
having percent_out_of_stock>10 and total_active_products > 10
order by total_active_products desc;

-- Insights : This tells us that some products are high risk which means that the % Out of stock is higher and it also has a higher active number of products.
-- For Eg : Product 'Detergente liquido' has Total Active Products = 51 and a Out of Stock % of 31.37% which means that there is an 
-- operational inefficiency because there are higher active products but is actually out of stock. Similar for the Top 10 products too.
-- We can see that this can be a cause for Customer Dissatisfaction. 

-- This query provides a direct comparison of KPIs for top-performing vs. bottom-performing stores.
-- It highlights the operational trade-offs between Found Rate and Catalog Assortment.


-- Finding out the Operational Trade offs. 

-- In this query i will create two CTE's , one for the FoundRate which i will use to reference Accuracy and the other will be the 
-- CatalogAssortmentRate for the Variety. The idea here is to get a correlation between the Accuracy vs Variety.

with FoundRate as (
select cs.name as Store_name,
gc.name as city_name,
round(sum(oo.qty_products_found)/sum(oo.qty_products_ordered)*100,2) as found_rate,
count(oo.id) as total_orders
from orders_order as oo
join catalog_storebranch as csb on 
oo.shopper_store_branch_id = csb.id
join catalog_store as cs on 
csb.store_id = cs.id
join geo_city as gc on
csb.city_id = gc.id
group by cs.name,gc.name),

CatalogAssortmentRate as (
select cs.name as Store_name , gc.name as city_name,
round(sum(case when cpb.availability_status = 'OUT_OF_STOCK' then 1 else 0 end)/
count(cpb.id)*100,2) as OutofStock_percent
from catalog_storebranch as csb
join catalog_productbranches as cpb on
csb.id = cpb.branch_id
join catalog_store as cs on 
csb.store_id = cs.id
join geo_city as gc on 
csb.city_id = gc.id
where cpb.active = TRUE
group by cs.name, gc.name)

select f.Store_name, f.city_name, f.total_orders, f.found_rate,car.OutofStock_percent
from FoundRate as f
join CatalogAssortmentRate as car on
f.Store_name=car.Store_name and f.city_name=car.city_name
order by f.found_rate desc; 

-- Insights: The Accuracy/Found Rate is higher in stores like 'Farmacias Ahumada' who are doing exceptionally well in all cities.
-- They have a lower Out of Stock percentage whereas stores like 'Jumbo' & 'Unimarc' in La Serena and Valparaiso have a poor found rate as compared to all other stores.
-- Hence, their OutofStock % is also higher. This operation strategy is paying off well in the top stores but is backfiring on the 
-- lower ones. This may also lead to customer dissatisfaction. This trade off is critical and to sum it up i can say that accuracy should be considered
-- a key element in determining the strategies success.




select distinct brand
from catalog_product;

select *
from catalog_storebranch

select *
from catalog_productbranches

-- Strategic color : Product level Out of Stock Analysis
-- In this query, i am going to give a product level analysis to find how many times each product has been out of stock. 


select cp.name as ProductName,
count(cp.id) as Count_of_OOS
from catalog_productbranches as cpb
join catalog_product as cp on 
cpb.product_id = cp.id
where cpb.availability_status = 'OUT_OF_STOCK' and cpb.active = TRUE
group by cp.name
order by Count_of_OOS desc
limit 10;

-- Insights: The highest products that are Out Of Stock the most times are the 'Detergente liquido', 'Limpiador bicarbonato naranja limón', 
-- 'Huevo AA rojo', 'Desodorante mujer dermo aclarant' etc are the ones that a shopper would find to be out of stock very easily. 
-- This shows us that the data provided by merchants might not be updated and in sync. 


-- Flagging the highest Out of stock products & checking their availability status count.

with HighestOutofStockProd as (
select cp.name as ProductName, count(cp.id) as Numberoftimes
from catalog_productbranches as cpb
join catalog_product as cp on
cpb.product_id = cp.id
where cpb.availability_status = 'OUT_OF_STOCK' and cpb.active = TRUE
group by cp.name
order by Numberoftimes desc
limit 5)

select cp.name as ProductName,cpb.availability_status, count(cpb.id) as numberoftimes
from catalog_productbranches as cpb
join catalog_product as cp on
cpb.product_id = cp.id
where cp.name in (
select ProductName from HighestOutofStockProd)
group by cp.name, cpb.availability_status
order by ProductName, numberoftimes desc;


-- Insights: These top 5 out of stock products mentioned in the CTE as the ones where the Count of those products have the highest number of OOS instances.
-- now if we look at the table, we can clearly see that the product that is displayed as AVAILABLE 31 times is also OUT OF STOCK 8 times and similarly for 
-- other products like 'Detergente liquido' where the #Available shows as 35 but that same product is Out of stock 43 times. 
-- This tells us that there is a data inconsistency problem here. 

-- Solution : As a manager when i look at this it is a situation that needs to be avoided at all costs. So here is the solution that we can work on.
-- We can create an innovative solution to take it to the global stage, the way i plan on doing it is we basically create an AI model in the ingestion pipeline.
-- Whenever we have a new product inventory entering our system, we can make the AI run a historical analysis on that same data to see if that product is 
-- high performing or low. If it is high and is detected as Out of Stock, then we can ask the AI to auto-flag it as a "RISK" or "need a check" on the item.
-- This model can be deployed globally to adapt to different countries too. Here i have thought about it in a way that we can do it globally while keeping
-- in mind that we have to be INNOVATIVE and drive innovation. 


-- Step 4 ; Adding strategic color - Consider how stock thresholds or merchant delays might be skewing performance?

SELECT
cs.name AS store,
gc.name AS city, COUNT(*) AS orders_count,
round(sum(oo.qty_products_found) * 100.0 / sum(oo.qty_products_ordered), 2) as foundrate_percent,

round(avg(oo.qty_products_found = oo.qty_products_ordered) * 100.0, 2) as percentorders_fulfilled

from orders_order AS oo
join catalog_storebranch 
as sb ON oo.shopper_store_branch_id = sb.id
join catalog_store       as cs on sb.store_id = cs.id
join geo_city            as gc on sb.city_id = gc.id
where left(oo.actual_delivery_time, 7) = '2023-06'
group by cs.name, gc.name
having sum(oo.qty_products_ordered) > 0
order by foundrate_percent DESC;

-- Insight: Yes, the performance is getting skewed. As we can see there is a huge gap between Foun Rate % and 
-- % orders fullfilled in cities like Santiago for store named JUMBO where (~90% FR vs ~29% fulfilled) & 
-- Unimarc store in city of Valparaíso (~83% vs ~17%) are great examples that performance is being inflated by 
-- lenient stock thresholds and/or stale merchant inventory feeds. 
-- If it were just measurement noise, you wouldn’t see gaps of 60+ points especially when Farmacias Ahumada–Santiago 
-- shows almost no gap (~90% vs ~89%), proving the metric can be robust when data and thresholds are healthy.


select *
from orders_order


-- Recommendation : ROI Statement: "Therefore, we can say that a 1% increase in Found Rate could lead to a measurable increase in customer retention, 
-- which we know is a key driver of Customer Satisfaction."