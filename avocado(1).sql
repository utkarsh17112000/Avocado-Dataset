# Retrieve all records from the avocado table
SELECT * FROM avocado.avocado;

# Modify the 'Date' column to change its datatype to 'date' format
ALTER TABLE avocado.avocado
MODIFY COLUMN Date date;

# Count the total number of records in the avocado table
SELECT count(*) as "Total Numbers" FROM avocado.avocado;

# List all distinct regions where avocado sales were recorded
select distinct region FROM avocado.avocado;


# Get the first and last date of avocado sales data
select min(Date) as Start_date, max(Date) as Last_Date FROM avocado.avocado;


# Calculate total revenue by multiplying price and volume for all transactions
select round(sum(AveragePrice*`Total Volume`),2) as Total_Revenue FROM avocado.avocado;

# Compare total volume of avocados sold based on type (organic/conventional)
select type, round(sum(`Total Volume`),2) as Total_Volume FROM avocado.avocado
group by type
order by Total_Volume desc;


# Determine the price volatility (max - min price) for each region
select region, round(Max(AveragePrice)-min(AveragePrice),3) as Highest_Volatility
FROM avocado.avocado
group by region
order by Highest_Volatility desc;

# Find the year with the highest total revenue from avocado sales
select Year(str_to_date(Date,"%d-%m-%Y")) as Years, round(sum(AveragePrice*`Total Volume`),2) as Total_Revenue
FROM avocado.avocado
group by Years
order by Total_Revenue desc
limit 1 ;

# Identify the month with the highest revenue across all years
select month(str_to_date(Date,"%d-%m-%Y")) as Months, round(sum(AveragePrice*`Total Volume`),2) as Average_Price
FROM avocado.avocado
group by Months
order by Average_Price desc
limit 1 ;

# Aggregate avocado sales by quarter and year
select Year(str_to_date(Date,"%d-%m-%Y")) as Years, Quarter(str_to_date(Date,"%d-%m-%Y")) as Quarters,
round(sum(`Total Volume`),0) as Total_Volume
FROM avocado.avocado
group by Years, Quarters
order by Years, Quarters ;



#Identify outlier prices (significantly high or low prices).
with Price_Stats as (
select Avg(AveragePrice) as Average_Price,
stddev(AveragePrice) as std_dev
FROM avocado.avocado
)
select * FROM avocado.avocado
where AveragePrice>(select Average_Price+2*std_dev from Price_Stats)
or AveragePrice < (select Average_Price-2*std_dev from Price_Stats);


# Compare yearly average price and identify price drops year over year
with yearly_prices as (
select Year(str_to_date(Date,"%d-%m-%Y")) as Years,Avg(AveragePrice) as Average_Price
FROM avocado.avocado
group by Years) 

select Years,Average_Price,LAG(Average_Price) OVER (ORDER BY Years) as Previous_Year
, Average_Price-LAG(Average_Price) OVER (ORDER BY Years) as Price_drop
from yearly_prices
order by Price_drop asc;


# Analyze price changes per region over the years
with yearly_prices_region as (
select Region,Year(str_to_date(Date,"%d-%m-%Y")) as Years,Avg(AveragePrice) as Average_Price
FROM avocado.avocado
group by Region,Years) 

select Region, Years,Average_Price,LAG(Average_Price) OVER (Partition by Region ORDER BY Years) as Previous_Year
, Average_Price-LAG(Average_Price) OVER (Partition by Region ORDER BY Years) as Price_drop
from yearly_prices_region
order by Price_drop desc;


# Calculate % change in volume per region over the years
with yearly_volumes_region as (
select Region,Year(str_to_date(Date,"%d-%m-%Y")) as Years,sum(`Total Volume`) as Total_Volume
FROM avocado.avocado
group by Region,Years) 

select Region, Years,Total_Volume,LAG(Total_Volume) OVER (Partition by Region ORDER BY Years) as Previous_Year
, (Total_Volume-LAG(Total_Volume) OVER (Partition by Region ORDER BY Years))*100/LAG(Total_Volume) OVER (Partition by Region ORDER BY Years) as Price_drop
from yearly_volumes_region
group by Region,Years
order by Price_drop desc;


# Find top 5 regions with the highest total revenue
select region, round(sum(AveragePrice*`Total Volume`),2) as Total_Revenue
FROM avocado.avocado
group by region
order by Total_Revenue desc
limit 5;


# Compare total avocado volume for selected regions: West and Northeast
select Region,round(sum(`Total Volume`),2) as "Total Volume"
FROM avocado.avocado
where Region="West" or Region="Northeast"
group by region;




# Calculate price elasticity of demand based on yearly change in price and volume
WITH price_volume AS (
    SELECT YEAR(str_to_date(Date,"%d-%m-%Y")) AS Years, 
           AVG(AveragePrice) AS avg_price, 
           SUM(`Total Volume`) AS total_volume
	FROM avocado.avocado
    GROUP BY Years
)
select Years,avg_price,total_volume,
LAG(avg_price) OVER (ORDER BY years) AS prev_price,
LAG(total_volume) OVER (ORDER BY years) AS prev_volume,
((total_volume - LAG(total_volume) OVER (ORDER BY years)) / LAG(total_volume) OVER (ORDER BY years)) /
((avg_price - LAG(avg_price) OVER (ORDER BY years)) / LAG(avg_price) OVER (ORDER BY years)) AS price_elasticity
from price_volume 
WHERE prev_price IS NOT NULL;


# Calculate 3-month moving average of avocado prices
SELECT Date, 
       round(AVG(AveragePrice) OVER (ORDER BY Date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),3) AS moving_avg_3_months
FROM avocado.avocado;



# Identify top 5 months with the highest total volume
select Month(str_to_date(Date,"%d-%m-%Y")) as Months, round(sum(`Total Volume`),3) as Total_Volume
FROM avocado.avocado
group by Months
order by Total_Volume desc
limit 5;

# Get total volume sold in selected years: 2015 and 2018
select Year(str_to_date(Date,"%d-%m-%Y")) as Years, round(sum(`Total Volume`),3) as Total_Volume
FROM avocado.avocado
group by Years
having Years in (2015,2018);



# Identify the top revenue-generating month for each year
with Month_Revenue as (
select Year(str_to_date(Date,"%d-%m-%Y")) as Years,
Month(str_to_date(Date,"%d-%m-%Y")) as Months,
round(sum(AveragePrice *`Total Volume`),2) as Total_Revenue
FROM avocado.avocado
Group by Years, Months)
select Years,Months,Total_Revenue
from(
select Years,Months,Total_Revenue,
Rank() over (Partition By Years order by Total_Revenue desc) as Ranks
from Month_Revenue
)ranked
where Ranks=1;




# Compare total sales by bag size: small, large, and extra large
with total_size_bags as (
select
round(sum(`Small Bags`),2) as Small_Bags,
round(sum(`Large Bags`) ,2) as Large_Bags,
round(sum(`XLarge Bags`),2) as XLarge_Bags
FROM avocado.avocado
)
 select "Small Bags" as Bag_Type, Small_Bags as Total_sales from total_size_bags
union all
select "Large Bags" as Bag_Type, Large_Bags as Total_sales from total_size_bags
union all
select "XLarge Bags" as Bag_Type, XLarge_Bags as Total_sales from total_size_bags
order by  Total_sales desc;


# Find top 5 regions with highest total volume each year
with state_year as (
select Year(str_to_date(Date,"%d-%m-%Y")) as Years, region,
sum(`Total Volume`) as Total_Volume
FROM avocado.avocado
group by Years, region
 )
select Years , region
from (
select Years, region, Total_Volume, 
Rank() over (partition by Years order by Total_Volume) as Ranks
from state_year
)ranked
where Ranks between 1 and 5;







