use creditCard
select * from credit_card_transcations

-- 1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 


select Top 5 city , sum(amount) as spend  , round(sum(cast (amount as bigint))*1.0 / (select sum(cast(amount as bigint )) from credit_card_transcations)*100,2) as percentage_contribution  from 
credit_card_transcations
group by city
order by spend desc

-- 2- write a query to print highest spend month and amount spent in that month for each card type

with A as (select card_type , datename(month , transaction_date) as month_name, datepart(year , transaction_date) as yt , sum(amount) as monthly_spend  from credit_card_transcations
group by datename(month , transaction_date), card_type , datepart(year , transaction_date))


select card_type , month_name , yt , monthly_spend from A 
where monthly_spend in (select max(monthly_spend) from A group by card_type)




-- 3- write a query to print the transaction details(all columns from the table) for each card type when
--    it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)


with cte1 as (select * , 
sum(amount) over(partition by card_type  order by transaction_date ,  transaction_id ) as running_sum from 
credit_card_transcations) 

select * from (select * , 
rank() over(partition by card_type order by running_sum asc) as rnk from cte1 
where running_sum >= 1000000) B
where rnk =1 

-- 4- write a query to find city which had lowest percentage spend for gold card type

with cte1 as (select city , card_type , sum(amount) as total_spend ,  
sum (case when card_type = 'Gold' then amount end )as gold_spend from credit_card_transcations
group by city , card_type )

select Top 1 city , sum(gold_spend) *1.0 / sum(total_spend) as ratio
from cte1 
group by city 
having sum(gold_spend) is not null 
order by ratio asc 



-- 5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)


with cte1 as (select city , exp_type , sum(amount) as total_spend 
from credit_card_transcations
group by city , exp_type) , 

cte2 as (select city , exp_type as highest_expense_type 
from (select cte1.* , 
max(total_spend) over(partition by city order by city) as highest_expense 
from cte1 ) B
where total_spend = highest_expense) , 

cte3 as (select city , exp_type as lowest_expense_type 
from (select cte1.* , 
min(total_spend) over(partition by city order by city) as   lowest_expense
from cte1 ) B
where total_spend = lowest_expense)

select cte2.city  , highest_expense_type , lowest_expense_type from cte2 
inner join cte3 on cte3.city = cte2.city 

-- 6- write a query to find percentage contribution of spends by females for each expense type



with A as(select  exp_type , sum(amount) as exp_type_spends from credit_card_transcations
group by exp_type) , 
B as (select  exp_type , sum(amount) as exp_type_spends_female from credit_card_transcations
where gender = 'F'
group by exp_type) 


select A.exp_type ,exp_type_spends,exp_type_spends_female ,   cast (exp_type_spends_female as bigint ) *1.0 / exp_type_spends as percentage_contribution
from A inner join B
on A.exp_type= B.exp_type 


--  7- which card and expense type combination saw highest month over month growth in Jan-2014

with A as (select card_type , exp_type ,datepart(year , transaction_date) as year_dec_jan,  sum(amount) as summed from credit_card_transcations
where transaction_date between '2013-12-01' and '2014-01-31' 
group by card_type , exp_type , datepart(year , transaction_date)),
B as (select A.* , 
lead(summed,1) over(order by card_type , exp_type ,  year_dec_jan) as nxt_summed
from A ) , 
c as (select B.* , nxt_summed - summed as growth from B 
where year_dec_jan = '2013' ) 

select card_type , exp_type , growth from c 
where growth = (select max(growth) from c ) 



-- ans = platinum - grocery 

-- 8- during weekends which city has highest total spend to total no of transcations ratio 

select top 1 city , sum(amount)*1.0/count(1) as ratio
from credit_card_transcations
where datepart(weekday,transaction_date) in (1,7)
group by city
order by ratio desc;

-- 9- which city took least number of days to reach its 500th transaction after the first transaction in that city

with A as (select city , transaction_id  , transaction_date ,
row_number() over(partition by city order by city  , transaction_date ) as rw 
from credit_card_transcations) , 

B as (select * , datediff( day , transaction_date , nxt_date) as days from (select *, 
lead(rw ,1 ) over(order by  city  , transaction_date ) as  nxt_rw,
lead(transaction_date ,1 ) over(order by  city  , transaction_date ) as  nxt_date
from A 
where rw  in (1 , 500)) B 
where rw=1 and nxt_rw = 500)

select Top 1  city , days from B 
order by days 