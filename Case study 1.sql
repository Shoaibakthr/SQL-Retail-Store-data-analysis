Select * from Customer 
Select * from Prod_cat_info
Select * from Transactions

--DATA PREPARATION AND UNDERSTANDING
--1. What is the total number of rows in each of the 3 tables in the databasase 
Select Count (*) As [Count] from Customer
Union 
Select Count (*) As [Count] from Prod_cat_info
Union 
Select Count (*) As [Count] from Transactions

--2.What is the total number of transactions that have a return?
Select Count(distinct(transaction_id))as Total_Transactions From Transactions
Where Qty<0

--3.What is the time range of the transaction data available for analysis? 
--Show the output in number of days, months and years simultaneously in different columns.
Select
    MIN(tran_date) AS Start_Date,
    MAX(tran_date) AS End_Date,
    DATEDIFF(DAY, MIN(tran_date), MAX(tran_date)) AS Duration_Days,
    DATEDIFF(MONTH, MIN(tran_date), MAX(tran_date)) AS Duration_Months,
    DATEDIFF(YEAR, MIN(tran_date), MAX(tran_date)) AS Duration_Years
From Transactions;

--4.Which product category does the sub-category “DIY” belong to?
Select prod_cat, prod_subcat from Prod_cat_info
Where prod_subcat = 'DIY'

--DATA ANALYSIS
--1. Which channel is most frequently used for transactions?
Select Top 1 Store_type, count(*) as [Count] from Transactions 
Group by Store_type
Order by [count] desc

--2. What is the count of Male and Female customers in the database?
Select Gender, count(Gender) as [Count] from Customer
where Gender is not null
group by Gender

--3. From which city do we have the maximum number of customers and how many?
Select top 1 city_code, count(*) As [Count] from Customer
group by city_code
order by [Count] desc

--4. How many sub-categories are there under the Books category?
select prod_subcat as Products , prod_cat as Category, count(*) as [Count]from Prod_cat_info
where prod_cat = 'Books'
Group by prod_cat,prod_subcat 

--5. What is the maximum quantity of products ever ordered?
Select prod_cat_code As [Product Code], max(Qty) As [Count] from Transactions
Group by prod_cat_code

--6. What is the net total revenue generated in categories Electronics and Books?
Select sum(total_amt) As [Net Revenue] from Prod_cat_info as t1 
join Transactions as T2 on t1.prod_cat_code = t2.prod_cat_code and t1.prod_sub_cat_code = t2.prod_subcat_code
Where prod_cat='Electronics' or prod_cat='Books'

--7. How many customers have >10 transactions with us, excluding returns?
Select count(*) as [Total Customers] from(Select cust_id , count(transaction_id) As [Count] from Transactions
Where Qty>0
Group by cust_id
Having count(transaction_id)> 10
) As T5;

--8.What is the combined revenue earned from the “Electronics” & “Clothing” categories, from “Flagship stores”?
Select sum(total_amt) from Prod_cat_info as t1 
join Transactions as t2 on t1.prod_cat_code = t2.prod_cat_code and t1.prod_sub_cat_code = t2.prod_subcat_code
Where (Store_type='Flagship store') and (prod_cat ='Electronics' or prod_cat ='Clothing') and Qty>0

--9. What is the total revenue generated from “Male” customers in “Electronics” category? Output should display total revenue by prod sub-cat.
Select prod_subcat As Products, Sum(total_amt) as [Total Revenue], count(prod_subcat) as [No. of Items] from Customer as T1 Join Transactions as T2 on T1.customer_Id = T2.cust_id 
Join Prod_cat_info as T3 on T2.prod_cat_code= T3.prod_cat_code and T2.prod_subcat_code= T3.prod_sub_cat_code
Where (Gender = 'M' and prod_cat= 'Electronics')
Group by(prod_subcat)

-- 10. What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?
SELECT T5.prod_subcat,
       T5.[Percentage Sales],
       T6.[Percentage Returns]
FROM (
    SELECT TOP 5
        prod_subcat,
        SUM(total_amt) / (SELECT SUM(total_amt) AS [Total Sales] FROM Transactions WHERE Qty > 0) AS [Percentage Sales]
    FROM
        Prod_cat_info AS T1
        JOIN Transactions AS T2 ON T1.prod_cat_code = T2.prod_cat_code AND T1.prod_sub_cat_code = T2.prod_subcat_code
    WHERE
        Qty > 0
    GROUP BY
        prod_subcat
    ORDER BY
        [Percentage Sales] DESC
) AS T5
JOIN (
    SELECT
        prod_subcat,
        SUM(total_amt) / (SELECT SUM(total_amt) AS [Total Sales] FROM Transactions WHERE Qty > 0) AS [Percentage Returns]
    FROM
        Prod_cat_info AS T1
        JOIN Transactions AS T2 ON T1.prod_cat_code = T2.prod_cat_code AND T1.prod_sub_cat_code = T2.prod_subcat_code
    WHERE
        Qty > 0
    GROUP BY
        prod_subcat
) AS T6 ON T5.prod_subcat = T6.prod_subcat;

--11.
-- Age of customer 
Select * from (
Select * from (
Select cust_id,datediff(Year,DOB,[Max Date])as Age, Revenue from (
Select cust_id, DOB, max(tran_date) as [Max Date], Sum(total_amt) as Revenue
from Customer T1 join Transactions T2 on T1.customer_Id = t2.cust_id
where Qty>0
group by cust_id,DOB 
) As A ) as B 
where Age between 25 and 35 ) as C
Join (
-- Last 30 Days Transactions 
Select cust_id,tran_date 
from Transactions
group by cust_id,tran_date
having tran_date >= (Select dateadd(day, -30, max(tran_date)) as [Cutoff Date] from Transactions) 
)as D
on c.cust_id= d.cust_id

--12. Which product category has seen the max value of returns in the last 3 months of transactions?
Select top 1 prod_cat_code, sum(Returns) as [Total Returns] from (
Select prod_cat_code,tran_date, sum(qty) as Returns 
from Transactions
where Qty<0
group by prod_cat_code,tran_date
having tran_date >= (Select dateadd(MONTH,-3, max(tran_date)) as [Cutoff Date] from Transactions) 
) as A 
Group by prod_cat_code
order by [Total Returns]

--13. Which store-type sells the maximum products; by value of sales amount and by quantity sold?
Select Top 1 Store_type, sum(total_amt) as [Total sales], sum(qty)as Quality from Transactions 
where Qty>0
group by Store_type
order by [Total sales]desc, Quality desc

--14.What are the categories for which average revenue is above the overall average.
SELECT prod_cat_code
FROM (
    SELECT prod_cat_code, AVG(total_amt) AS avg_revenue_by_category
    FROM transactions
    GROUP BY prod_cat_code
) AS category_avg
WHERE avg_revenue_by_category > (SELECT AVG(total_amt) FROM transactions)

-- 15. Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.
Select prod_subcat_code, sum(total_amt) as Revenue , avg(total_amt)as [Avg Revenue] from Transactions
where Qty>0 and prod_cat_code In (Select Top 5  prod_cat_code from Transactions
Where Qty>0
group by prod_cat_code
order by sum (qty)desc )
group by prod_subcat_code

