--SQL porfolio project.
--downloaded  credit card transactions dataset from below link :
--https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india
--import the dataset in sql server with table name : credit_card_transcations
--change the column names to lower case before importing data to sql server.Also replace space within column names with underscore.
--while importing make sure to change the data types of columns. by defualt it shows everything as varchar.
alter table credit_card_transcations
alter column transaction_id int

alter table credit_card_transcations
alter column transaction_date date 

alter table credit_card_transcations
alter column amount bigint	

select * from credit_card_transcations

--exploring dataset 
select min(transaction_date),max(transaction_date) from credit_card_transcations
--data ranges from 2013-10 to 2015-05

select distinct card_type from credit_card_transcations
--Gold
--Signature
--Platinum
--Silver

select distinct exp_type from credit_card_transcations;
--Grocery
--Food
--Travel
--Entertainment
--Fuel
--Bills

--solved below questions
--1- write a query to print top 5 cities with highest spends and their percentage contribution of
-- total credit card spends 
with cte as (
select  city, sum(amount)*1.0 as total_spend_citywise 
from credit_card_transcations
group by city), 
ts as (select sum(amount) as ftotal_spend from credit_card_transcations) 
select top 5 cte.*,ftotal_spend, (total_spend_citywise / ftotal_spend)*100.00 as percentage_contribution
from cte ,ts
order by percentage_contribution desc ;

--2- write a query to print highest spend month and amount spent in that month for each card type
with cte as (
select card_type ,DATEPART(year,transaction_date) as [year], DATEPART(month,transaction_date) as [month], sum(amount) as spend
from credit_card_transcations
group by card_type,DATEPART(year,transaction_date),DATEPART(month,transaction_date))
select * from 
(select *,rank()over(partition by card_type order by spend desc) as [rank]
from cte)A
where [rank]=1

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with cte as 
(select *,sum(amount)over(partition by card_type order by transaction_date , transaction_id)as cumm_spend 
from credit_card_transcations)
select * from 
(select *,rank()over(partition by card_type order by cumm_spend asc) as [rank]
from cte
where cumm_spend >=1000000)A
where [rank]=1

--4- write a query to find city which had lowest percentage spend for gold card type
with cte as (
select card_type , city ,sum(amount)as spend from credit_card_transcations
group by city,card_type),
b as (
select *,sum(spend)over(partition by city)as city_spend from cte)
select top 1 * , spend*1.00/city_spend*100.00 as percentage_spend from b
where card_type='gold'
order by percentage_spend asc 

--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type 
--(example format : Delhi , bills, Fuel)

with cte as 
(select city , exp_type, sum(amount) as spend from credit_card_transcations
group by city,exp_type),
b as (
select * ,(case when spend = max(spend)over(partition by city order by spend desc) then exp_type end) as highest_expense_type ,
(case when spend=min(spend)over(partition by city order by spend asc) then exp_type end) as lowest_expense_type from cte)
select city,max(highest_expense_type) as highest_expense_type,max(lowest_expense_type)as lowest_expense_type  from b
group by city ;

--6- write a query to find percentage contribution of spends by females for each expense type
with cte as (
select exp_type , sum(case when gender ='F' then amount end) as nfemale_spend ,  
sum(case when gender ='M' then amount end) as nmale_spend from credit_card_transcations
group by exp_type , gender)
select exp_type,sum(nfemale_spend) as female_spend,sum(nmale_spend) as male_spend,
sum(nfemale_spend)*1.0/(sum(nfemale_spend)+sum(nmale_spend))*100.0 as female_percentage_contribution
from cte
group by exp_type;

--7- which card and expense type combination saw highest month over month growth in Jan-2014
with cte as (
(select card_type , exp_type, datepart(year,transaction_date) as [year], datepart(MONTH,transaction_date) as [month],
sum(amount) as spend
from credit_card_transcations
group by card_type , exp_type,datepart(year,transaction_date),datepart(MONTH,transaction_date))),
b as 
(select *,lag(spend,1,spend)over(partition by card_type , exp_type order by [year],[month]) as last_month_spend,
(spend*1.0-lag(spend,1,spend)over(partition by card_type , exp_type order by [year],[month])*1.0)
/lag(spend,1,spend)over(partition by card_type , exp_type order by [year],[month])*100.0 as mom
from cte)
select top 1 * from B
where last_month_spend is not null and
[year]=2014 and [month]=1
order by mom desc

--8- during weekends which city has highest total spend to total no of transcations ratio 
select top  1 city, (sum(amount)*1.0/count(1)) as spend_to_total_no_of_transcations_ratio
from credit_card_transcations
where datepart(WEEKDAY,transaction_date) in (1,7)
group by city
order by spend_to_total_no_of_transcations_ratio desc 

--10- which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as (
select *
,row_number() over(partition by city order by transaction_date,transaction_id) as rn
from credit_card_transcations)
select  city,datediff(day,min(transaction_date),max(transaction_date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by datediff1 


