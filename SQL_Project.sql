Use E_Commerce;

Select * from Customers

---A. Create a YOY analysis for the count of customers enrolled with the company each month. The output should look like:

select Months, sum([2020]) AS Year_2020,sum([2021]) as Year_2021
from 
(Select month(DateEntered) As Months , [2020] , [2021] 
from (Select * , Year(DateEntered) As year_  From Customers) dat
Pivot 
(Count(year_) for year_ in ([2020], [2021]) ) As pivt) fnl
group by fnl.Months



----Using_Case

Select  month(DateEntered) As Months , 
Sum(Case When Year(DateEntered) = 2020 then 1
else 0 
end ) As Year_2020,
Sum(Case When Year(DateEntered) = 2021 then 1
else 0 
end ) As Year_2021
From Customers
group by month(DateEntered)


--B. Find out the top 3 best-selling products in each of the categories that are currently active on the Website
---IF we Consider number of times purchased than

Select * from
(select cat.CategoryID, pro.ProductID,  Sum(ordt.Quantity) As Qnty, 
Dense_Rank () Over(Partition by CategoryID Order by Sum(ordt.Quantity) Desc) As D_Rank
from Category As cat
inner join Products As pro 
on cat.CategoryID = pro.Category_ID
inner join OrderDetails As ordt 
on pro.ProductID = ordt.ProductID 
where cat.Active = 1
group by pro.ProductID, cat.CategoryID) new
where D_Rank between 1 and 3



--------C. Find the out the least selling products in each of the categories that are currently active on the website

Select * from
(select cat.CategoryID, pro.ProductID,  Sum(ordt.Quantity) As Qnty, 
Dense_Rank () Over(Partition by CategoryID Order by Sum(ordt.Quantity)) As D_Rank
from Category As cat
inner join Products As pro 
on cat.CategoryID = pro.Category_ID
inner join OrderDetails As ordt 
on pro.ProductID = ordt.ProductID 
where cat.Active = 1
group by pro.ProductID, cat.CategoryID) new
where D_Rank = 1


------D. We are trying to find paired products that are often purchased together by the same user, such as chips and soft drinks, milk and curd etc.. 
----Find the top paired products names.


create view prd_ord5
As
(select ordtl.OrderDetailID, ordtl.OrderID, ordtl.ProductID , prdt1.Product, prdt1.Category_ID, ords.CustomerID from OrderDetails As ordtl
inner join Products As prdt1 on ordtl.ProductID = prdt1.ProductID 
inner join Orders As ords on Ords.OrderID = ordtl.OrderID);

create view prd_ord6
As
(select ordtl2.OrderDetailID, ordtl2.OrderID, ordtl2.ProductID , prdt2.Product, prdt2.Category_ID , ords2.CustomerID from OrderDetails As ordtl2
inner join Products As prdt2 on ordtl2.ProductID = prdt2.ProductID
inner join Orders As ords2 on Ords2.OrderID = ordtl2.OrderID);


Select prd_ord5.ProductID , prd_ord6.CustomerID,prd_ord5.Product,prd_ord6.ProductID ,  prd_ord6.Product,count(prd_ord5.ProductID) As number_of_times 
from prd_ord5 
inner join 
prd_ord6 
on prd_ord5.OrderID = prd_ord6.OrderID and prd_ord5.ProductID > prd_ord6.ProductID and prd_ord5.CustomerID = prd_ord6.CustomerID
group by prd_ord5.ProductID ,  prd_ord6.ProductID , prd_ord5.Product, prd_ord6.Product, prd_ord6.CustomerID
Order by number_of_times Desc


---E. We want to understand the impact of running a campaign during July’21-Oct’21 
---what was the total sales generated for the categories“Beauty & Hygiene” and “Bevarages” by
--a. entire customer base


Alter Table orderdetails Alter column Quantity int;
Alter table products Alter column sale_price int;




Select SUM( OrderDetails.Quantity* Products.Sale_Price) As rev from Orders
inner Join Customers on Customers.CustomerID = Orders.CustomerID
inner Join OrderDetails on OrderDetails.OrderID = Orders.OrderID
inner join Products on Products.ProductID = OrderDetails.ProductID
inner Join Category on Category.CategoryID = Products.Category_ID
where (year(orderDate) = 2021) and (month(orderDate)  between 7 and 10 )
and (Category.CategoryName = 'Beauty & Hygiene' or Category.CategoryName = 'Beverages' );




---b. customers who enrolled with the company during the same period

Select Sum(products.Sale_Price * orderdetails.Quantity) as total_sale_from_Beauty_Hygiene_Bevarages_from_new_cust 
from Orders
inner Join Customers on Customers.CustomerID = Orders.CustomerID
inner Join OrderDetails on OrderDetails.OrderID = Orders.OrderID
inner join Products on Products.ProductID = OrderDetails.ProductID
inner Join Category on Category.CategoryID = Products.Category_ID
where year(orderDate) = 2021 and month(orderDate)  between 7 and 10
and (Category.CategoryName = 'Beauty & Hygiene' or Category.CategoryName = 'Beverages' )
and (year(customers.DateEntered) = 2021 and month(customers.DateEntered) between 7 and 10);



--F. Create a Quarter-wise ranking in terms of revenue generated in each category in Year 2020

Create View qf2 As
(Select Category.CategoryID, orders.Total_order_amount, 
Case 
When month(orderDate) between 1 and 3 then 'Q1'
when month(orderDate) between 4 and 6 then 'Q2'
when month(orderDate) between 7 and 9 then 'Q3'
When month(orderDate) between 9 and 12 then 'Q4'
end
As Qtr
from Orders
inner Join Customers on Customers.CustomerID = Orders.CustomerID
inner Join OrderDetails on OrderDetails.OrderID = Orders.OrderID
inner join Products on Products.ProductID = OrderDetails.ProductID
inner Join Category on Category.CategoryID = Products.Category_ID
where year(orderDate) = 2020)

Select *, Dense_RANK() OVER(Partition by Qtr order by TOTAL_amount Desc) from
(Select CategoryID,Qtr ,SUM(Total_order_amount) As TOTAL_amount from qf2
group by CategoryID,Qtr)C





--F. Create a Quarter-wise ranking in terms of revenue generated in each category in Year 2020

Select * , Rank() over(Partition by CategoryName order by Revenue DESC) As Rank_ from (
Select DATEPART(q, OrderDate) As Qtr, CategoryName, Sum(products.Sale_Price * Quantity) As revenue from Orders
inner Join Customers on Customers.CustomerID = Orders.CustomerID
inner Join OrderDetails on OrderDetails.OrderID = Orders.OrderID
inner join Products on Products.ProductID = OrderDetails.ProductID
inner Join Category on Category.CategoryID = Products.Category_ID
where year(Orders.OrderDate) = 2020
Group by DATEPART(q, OrderDate), CategoryName)c
Order By Qtr;

----------------------------method 2

Select * , Rank() over(Partition by CategoryName order by Revenue DESC) As Rank_ from (
Select DATEPART(q, OrderDate) As Qtr, CategoryName, Sum(products.Sale_Price * Quantity) As revenue from Orders
inner Join Customers on Customers.CustomerID = Orders.CustomerID
inner Join OrderDetails on OrderDetails.OrderID = Orders.OrderID
inner join Products on Products.ProductID = OrderDetails.ProductID
inner Join Category on Category.CategoryID = Products.Category_ID
where year(Orders.OrderDate) = 2020
Group by DATEPART(q, OrderDate), CategoryName)c
Order By Qtr;























----
---G. Find the top 3 Shipper companies in terms of
	---a. Average delivery time for each category for the latest year
--------------------------------------------------------------------------------

Select * from 
(Select * , ROw_number() over( Partition by Category_ID order by Avg_delvry_time ) Rank_Dns from
(Select Products.Category_ID,ShipperID, Avg(datediff(day, OrderDate, DeliveryDate)) As Avg_delvry_time  from OrderDetails 
inner join Orders on OrderDetails.OrderID=orders.OrderID
inner join Products on Products.ProductID = OrderDetails.ProductID
where year(OrderDate) in (Select Year (MAx(OrderDate) )from orders) 
Group by ShipperID, Products.Category_ID)C)D
where Rank_Dns between 1 and 3;


---b. Volume for latest year

Select TOP 3 Shippers.ShipperID, CompanyName, Sum(Quantity) As total_volume from OrderDetails 
inner join Orders on OrderDetails.OrderID=orders.OrderID
inner join Products on Products.ProductID = OrderDetails.ProductID
inner join Shippers on Shippers.shipperID = orders.shipperID
where year(OrderDate) in (Select Year (MAx(OrderDate) )from orders) 
Group by Shippers.ShipperID, CompanyName
order by total_volume desc


--------------Short cut MEthod 2

SELECT * FROM 
(SELECT P.Category_ID,O.ShipperID,AVG(DATEDIFF(DAY,O.OrderDate,O.DeliveryDate)) AS 'Delivery Period',
ROW_NUMBER() OVER(PARTITION BY P.Category_ID ORDER BY AVG(DATEDIFF(DAY,O.OrderDate,O.DeliveryDate))) AS 'Rank'
FROM Products AS P 
JOIN OrderDetails AS OD ON P.ProductID=OD.ProductID
JOIN Orders AS O ON OD.OrderID=O.OrderID
WHERE YEAR(O.OrderDate)=2021
GROUP BY P.Category_ID,O.ShipperID
)DT
WHERE DT.Rank<=3;






---H. Find the top 25 customers in terms of

----a. Total no. of orders placed for Year 2021

Select TOP 25 Orders.CustomerID,Customers.FirstName, Customers.LastName, Count(orders.OrderID) As num_of_order from orders
inner join Customers on Customers.CustomerID = Orders.CustomerID
where year(OrderDate) = 2021
Group by Orders.CustomerID, Customers.FirstName, Customers.LastName
order by num_of_order Desc;


---------Method 2

Select * from(
Select CustomerID,FirstName, LastName, No_order , rank() over (order by No_order DESC) As Rank_cust from
(Select Customers.CustomerID , Customers.FirstName, Customers.LastName, Count(orders.OrderID) over (partition by Customers.CustomerID) No_order from orders
inner join Customers on Customers.CustomerID = Orders.CustomerID
where year(OrderDate) = 2021)C
Group by CustomerID, FirstName,LastName, No_order) d where d.Rank_cust <= 25;



---H. Find the top 25 customers in terms of
--b. Total Purchase Amount for the Year 2021

Select * from(
Select CustomerID,FirstName, LastName, Total_amount , rank() over (order by Total_amount DESC) As Rank_cust_amount from
(Select Customers.CustomerID , Customers.FirstName, Customers.LastName, Sum(orders.Total_order_amount) 
over (partition by Customers.CustomerID) Total_amount from orders
inner join Customers on Customers.CustomerID = Orders.CustomerID
where year(OrderDate) = 2021)C
Group by CustomerID, FirstName,LastName, Total_amount) D where D.Rank_cust_amount <= 25;

-----------Method 2

Select TOP 25 Orders.CustomerID,Customers.FirstName, Customers.LastName, Sum(orders.Total_order_amount) As num_of_order from orders
inner join Customers on Customers.CustomerID = Orders.CustomerID
where year(OrderDate) = 2021
Group by Orders.CustomerID, Customers.FirstName, Customers.LastName
order by num_of_order Desc;


--I. Find out the difference between the last two order dates for each of the
---customers and categorize the customers in two categories such that if the
---difference is less than 5 days tag the customer as “Frequent Buyer” else tag
---it as “Infrequent”.

Create View I_View
As	
(Select * from 
(Select CustomerID, OrderID, OrderDate, Rank_ 
from (select *, Dense_rank() OVER (partition by CustomerId Order by OrderDate Desc) As rank_ from Orders) c
group by CustomerID, OrderID, OrderDate,rank_) c 
where rank_ = 1 or rank_ = 2)

Select CustomerID, Case
When Datediff( day, Min(OrderDate) , Max(OrderDate)) < 5 then 'Frequent'
Else 'Infrequent'
End
 As  Tag_
from I_View
group by CustomerID




---J. FInd the cumulative average order amount at a monthly level for year 2021
---a. Each category


Select *, Avg(monthly_total) Over (Partition by Category_ID order by months)As Cum_avg from 
(Select C.Category_ID, Month(OrderDate) As months, SUM(Sale_Price* Quantity) As monthly_total from Orders As A
inner Join OrderDetails As B
on A.OrderID = B.OrderID
inner join Products As C on C.ProductID = B.ProductID
where Year(OrderDate) = 2021
Group by C.Category_ID, Month(OrderDate))c


----b. Each customer
----------------------

Select *, Avg(monthly_total) Over (Partition by CustomerID order by months)As Cum_avg from 
(Select A.CustomerID, Month(OrderDate) As months, SUM(Total_order_amount) As monthly_total from Orders As A
inner Join OrderDetails As B
on A.OrderID = B.OrderID
inner join Products As C on C.ProductID = B.ProductID
where Year(OrderDate) = 2021
Group by A.CustomerID, Month(OrderDate))c

---K. Find the 3-day rolling average for the total purchase amount by each customer.


Select * , AVG(Total_Order_amount) 
Over ( Partition by CustomerId Order by orderdate Rows 2 PRECEDING  ) As three_day_rolling 
from Orders


---L. Create the below table where values for each Payment method should
----contain the total order amount by each customer resp.

Create View 
PVT_view
As
(Select A.CustomerID, A.Total_order_amount,B.PaymentType  from Orders As A inner join Payments AS B on A.PaymentID = B.PaymentID)

Select CustomerID,[Debit Card],[POD],[PayPal], [Credit Card],[Wallet],[Net banking] from PVT_view
Pivot
(Sum(Total_order_amount) for PaymentType in ([Debit Card],[POD],[PayPal],[Credit Card],[Wallet],[Net banking])) As Pvt

----M. Create a Procedure to filter the orders from Orders table where 
---total purchase amount in a each order id < @x and purchase of year is @Y where @x and @y are the inputs provided by the user.


Create Procedure Filter_ @X int, @y int
As 
begin 
Select * from Orders
where OrderID < @X and year(OrderDate) = @Y
End 

Exec Filter_ 77000000, 2021

