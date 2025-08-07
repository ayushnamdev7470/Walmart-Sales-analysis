CREATE DATABASE Internshala;
Use internshala;

SELECT * FROM walmartsales;

/*Task 1: Identifying the Top Branch by Sales Growth Rate*/
-- Question - Walmart wants to identify which branch has exhibited the highest sales growth over time. Analyze the total sales 
 -- for each branch and compare the growth rate across months to find the top performer.

-- Step 1st: Extract Monthly sales data -- First, we will calculate total sales for each branch grouped by month
 
 SELECT 
    Branch,
   Date_format(STR_To_Date(Date, '%d-%m-%Y'), '%Y-%m') AS Sales_month, 
	round(SUM(Total),2) AS Monthly_Sales
FROM WalmartSales
GROUP BY Branch, Sales_month
Order by Branch, Sales_month;

-- Step 2nd: Calculate Month-over-Month Growth -- 

SELECT Branch, Sales_Month,
Monthly_Sales, Monthly_Sales - LAG (Monthly_sales) 
OVER (Partition BY Branch ORDER BY Sales_Month) AS Sales_Growth
FROM (SELECT Branch, date_format(STR_TO_DATE(Date, '%d-%m-%Y'), '%Y-%m') AS Sales_month,
Round(SUM(Total),2) AS Monthly_sales From Walmartsales group by Branch, Sales_Month) AS Monthly_Data;

-- Step 3rd: Identify the top Branch -

SELECT Branch, MAX(Sales_Growth) AS MAx_growth 
FROM (Select Branch, Sales_Month, Monthly_sales, Monthly_sales - LAG (Monthly_Sales)
Over(Partition by Branch ORDER BY Sales_Month) AS Sales_Growth FROM 
(Select Branch, date_format(STR_To_Date(Date, '%d-%m-%Y'), '%Y-%m') AS Sales_Month,
round(Sum(Total),2) AS Monthly_sales From walmartsales Group by Branch, Sales_Month)
AS Monthly_data) AS Growth_Data GROUP BY Branch ORDER BY MAX_Growth DESC;


 SeLECT * FROM walmartsales;
 
 /*Task 2: Finding the Most Profitable Product Line for Each Branch*/
 --  Walmart needs to determine which product line contributes the highest profit to each branch.The profit margin
-- should be calculated based on the difference between the gross income and cost of goods sold --

-- Step 1st: Calculate Profit for Each Product Line --

SELECT Branch, Product_line,
Round(SUM(gross_income - cogs),2) AS Profit
From walmartsales
Group by Branch, Product_line
Order by Branch, Profit DESC;

-- Step 2nd: Rank Product lines Within Each Branch --

With Ranked_Product_Lines AS (
Select Branch, Product_line, 
Round(SUM(gross_income - cogs),2) AS Profit,
Rank() OVER (Partition By Branch ORDER BY round(SUM(gross_income - cogs),2) DESC) AS
`Rank` From walmartsales Group By Branch, Product_line)
Select Branch, Product_line, Profit From Ranked_Product_lines 
Where `Rank` = 1;

/* Task 3: Analyzing Customer Segmentation Based on Spending*/
-- Walmart wants to segment customers based on their average spending behavior. Classify customers into three
-- tiers: High, Medium, and Low spenders based on their total purchase amounts.

-- Step 1st: Calculate total spending per customer

Select Customer_Id,
round(SUM(Total),2) AS Total_Spending 
From walmartsales 
Group By Customer_ID 
Order By Total_spending DESC;

-- Step 2nd: Define Spending --

select Customer_ID, total_spending,
Case
	When Total_spending > 500 Then 'High spender' 
    When Total_spending Between 200 AND 500 THEN 'Medium spender'
    Else 'Low Spender' 
    END 
    As Spending FROM (
    Select Customer_Id, Round(Sum(Total),2) AS Total_spending 
    from walmartsales
    Group by Customer_ID) AS Customer_Spending
    Order by Total_Spending DESC;

-- Task 4th Detecting Anomalies in Sales Transactions
-- Walmart suspects that some transactions have unusually high or low sales compared to the average for the
-- product line. Identify these anomalies.

-- Step 1st Calculate the average sales for each product line

Select Product_line, 
Round(AVG(Total),3) AS Avg_sales
From walmartsales
GROUP by Product_line;

-- Step 2nd Compare transaction to the Average 

SELECT Invoice_ID, Product_line, Total, 
(SELECT AVG(Total) 
FROM walmartsales 
AS sub Where Sub.Product_line = main.Product_line) AS Avg_sale,
CASE
	When Total > 1.5 * (Select AVG(Total)
    From walmartsales AS sub
    Where Sub.Product_line = main.Product_line) 
THEN 'High Anomaly'
When Total <0.5 * (SELECT avg(Total) From walmartsales AS sub
Where sub.Product_line = main.Product_line) 
THEN 'Low Anomaly' ELSE 'Normal' 
END 
AS Anomaly_Status From walmartsales AS main;

-- Task 5th:  Most Popular Payment Method by City
-- Walmart needs to determine the most popular payment method in each city to tailor marketing strategies.

-- Step 1st: Aggregate Payment Method Counts by city

SELECT City, Payment, 
Count(Payment) AS Payment_Count
From walmartsales 
Group by City, Payment
Order By City, Payment_count DESC;

-- Step 2nd:Identify the most popular Payment method per city 

WITH Ranked_Payment AS (
SELECT city, payment, 
COUNT(Payment) AS Payment_count, Rank()
OVER (partition by City ORDER BY Count(Payment)DESC) AS `Rank` 
From Walmartsales 
GROUP BY City, Payment) 
Select city, Payment AS Popular_Payment_method, Payment_count
From Ranked_Payment 
WHERE `Rank` = 1; 

-- TASK 6th  Monthly Sales Distribution by Gender
--  Walmart wants to understand the sales distribution between male and female customers on a monthly basis.

-- Step 1st: Extract Monthly sales Data

SELECT date_format(STR_To_DATE(Date, '%d-%m-%Y'), '%Y-%m') AS Sales_Month, Gender,
Round(SUM(Total),2) AS Total_sales
From walmartsales
Group By Sales_Month, Gender
Order By sales_Month, Gender;

-- Step 2nd: Calculate Sals distribution

With Monthly_Total_Sales AS  (
SELECT date_format(str_to_Date(Date, '%d-%m-%Y'),'%Y-%m')
AS Sales_Month, SUM(Total) As Monthly_Total
FROM walmartsales 
group by sales_Month)
SELECT w.Sales_Month, w.gender, w.Total_Sales,
(w.Total_Sales / m.Monthly_total) * 100 AS Percentage
From (Select Date_Format(STR_To_Date(Date, '%d-%m-%Y'), '%Y-%m')
AS Sales_Month, Gender, SUM(Total) AS total_Sales
From walmartsales 
Group By Sales_Month, Gender) AS W 
Join Monthly_Total_sales As m ON w.Sales_Month = m.Sales_Month 
ORDER By w.Sales_Month, w.Gender;

-- Task 7th:  Best Product Line by Customer Type
--  Walmart wants to know which product lines are preferred by different customer types(Member vs. Normal).

-- Step 1st Calculate Total Sales for each product line by customer types

SELECT Customer_Type, Product_line,
Round(sum(Total),2) AS Total_Sales
From walmartsales 
Group by Customer_type, Product_line
Order By Customer_Type, Total_sales DESC;

-- Step 2nd Identify the best Prodcut line per Customer Type

With Product_Sales AS (
SELECT Customer_type, Product_line,
Round(SUM(Total),2) AS total_sales
From Walmartsales
Group By Customer_Type, Product_line),
Ranked_Products AS (
SELECT *, Rank() Over (Partition By Customer_type ORDER By Total_sales DESC) AS `Rank`
From Product_sales
)
Select Customer_type, Product_line, Total_sales
from Ranked_Products
Where `rank` = 1;

-- Task 8th  Identifying Repeat Customers 
--  Walmart needs to identify customers who made repeat purchases within a specific time frame (e.g., within 30 days).

-- Step 1st Convert the date formate.alter 

SELECT Customer_ID, STR_To_Date(Date, '%d-%m-%Y') AS Purchase_Date
From walmartsales;

-- Step 2nd Identify Repeat Purchase

With Repeat_transaction AS (
SELECT Customer_ID, str_to_date(Date, '%d-%m-%Y') AS Purchase_Date,
DATEDIFF(STR_To_Date(Date, '%d-%m-%Y'), LAG(str_to_date(Date, '%d-%m-%Y'))
OVER (Partition By Customer_Id ORDER By STR_To_Date(Date, '%d-%m-%Y'))) AS 
Days_Between From walmartsales) Select  Customer_id, Purchase_date,
Days_Between From Repeat_Transaction 
Where Days_Between <= 30 
Order By Customer_ID, Purchase_Date;

-- Step 3rd Aggregate Repeat Customers

With Repeat_transaction AS (
SELECT Customer_ID, str_to_date(Date, '%d-%m-%Y') AS Purchase_Date,
DATEDIFF(STR_To_Date(Date, '%d-%m-%Y'), LAG(str_to_date(Date, '%d-%m-%Y'))
OVER (Partition By Customer_Id ORDER By STR_To_Date(Date, '%d-%m-%Y'))) AS 
Days_Between From walmartsales) Select DISTINCT Customer_ID
From Repeat_Transaction 
Where Days_Between <= 30 
Order By Customer_ID;

-- Task 9th  Finding Top 5 Customers by Sales Volume 
--  Walmart wants to reward its top 5 customers who have generated the most sales Revenue.

-- Step 1st: Calculate total sales per customer

SELECT Customer_ID,
Round(SUM(Total),2) AS Total_Sales
From Walmartsales 
Group By Customer_ID
Order By Total_sales DESC;

-- Step 2nd: Select The top 5 Customers

SELECT Customer_Id, Round(SUM(Total),2) AS Total_Sales
From walmartsales 
Group By Customer_ID
Order By Total_Sales DESC Limit 5;

-- Task 10th: Analyzing Sales Trends by Day of the Week
-- Walmart wants to analyze the sales patterns to determine which day of the week
 -- brings the highest sales.alter
 
 -- Step 1st: Extract the Day of the week
 
 Select DAYNAME(STR_To_Date(Date, '%d-%m-%Y')) AS Day_Of_Week,
 Round(SUM(Total),2) AS Total_sales
 From Walmartsales
 Group By Day_Of_Week
 Order By Total_sales DESC;
 
 -- Step 2nd: Identify the Day with the Highest Sales
 
 SELECT DAYNAME(STR_To_DATE(Date, '%d-%m-%Y')) AS Day_Of_Week,
 Round(SUM(Total),2) AS Total_Sales
 From Walmartsales 
 Group By Day_Of_Week
 ORDER By Total_Sales DESC limit 1;
 
 -- Step 3rd: Additional Insights

With Weekly_Sales AS (
 Select Round(SUM(Total),3) AS Total_Weekly_sales
 From walmartsales) 
 SELECT DAYNAME(STR_To_Date(Date, '%d-%m-%Y')) AS Day_Of_week,
 round(SUM(Total),3) AS Total_sales,
round((Sum(Total) / (Select total_Weekly_Sales From Weekly_sales)) * 100, 2) AS
Percentage_weekly_Sales
From Walmartsales 
Group by Day_Of_Week
Order By total_Sales DESC;