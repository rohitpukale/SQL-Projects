--There are 2 csv files. The data contains 120 years of olympics history. There are 2 daatsets 
--1- athletes : it has information about all the players participated in olympics
--2- athlete_events : it has information about all the events happened over the year.(athlete id refers to the id column in athlete table)

use absql 
alter table athlete_events
alter column [athlete_id] int
alter table athlete_events
alter column [year] date
  
alter table athletes  
alter column [id] int
alter table athletes       
alter column [height] int     
alter table athletes       
alter column [weight] int        
      
--1 which team has won the maximum gold medals over the years.
select top 1000 * from athletes 
select top 1000 * from athlete_events;

select top 1 team,count(distinct [event]) as gold_medals_won from athletes a 
inner join athlete_events at
on a.id=at.athlete_id 
where medal like 'gold%'
group by team 
order by gold_medals_won desc ;

--2 for each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver
with cte as (
select a.team,ae.year , count(distinct event) as silver_medals
,rank() over(partition by team order by count(distinct event) desc) as rn
from athlete_events ae
inner join athletes a on ae.athlete_id=a.id
where medal='Silver'
group by a.team,ae.year)
select team,sum(silver_medals) as total_silver_medals, max(case when rn=1 then year end) as  year_of_max_silver
from cte
group by team;

--3 which player has won maximum gold medals  amongst the players 
--which have won only gold medal (never won silver or bronze) over the years
with cte as (
select name as dist_medal  ,
sum(case when medal like '%gold%' then 1 else 0 end) as gold_medal,
sum(case when medal like '%silver%' then 1 else 0 end) as silver_medal ,
sum(case when medal like '%bronze%' then 1 else 0 end) as bronze_medal
from athletes a 
inner join athlete_events at
on a.id=at.athlete_id 
group by name)
select * from cte
where gold_medal >=1 and silver_medal =0 and bronze_medal =0
order by gold_medal desc ;

--4 in each year which player has won maximum gold medal . Write a query to print year,player name 
--and no of golds won in that year 
with cte as (
select name , DATEPART(year,[year])as yr, 
sum(case when medal like '%gold%' then 1 else 0 end) as gold_medal
from athletes a 
inner join athlete_events at
on a.id=at.athlete_id
group by name , DATEPART(year,[year]))
select * from (
select *, rank()over(partition by yr order by gold_medal desc) as rn from cte)B
where rn=1;

--5 in which event and year India has won its first gold medal,first silver medal and first bronze medal
--print 3 columns medal,year,sport
with cte as(
select event, DATEPART(year,[year])as yr,
(case when medal like '%gold%' then 'gold' else    
case when medal like '%silver%' then 'silver'
else case when medal like '%bronze%' then 'bronze' else 'na' end end end) as medal_cat
from athletes a 
inner join athlete_events at
on a.id=at.athlete_id
where team like '%india%'),
B as (
select *,row_number()over(partition by medal_cat order by yr asc) as rn
from cte )
select * from B 
where rn=1 and medal_cat != 'na';

--6 find players who won gold medal in summer and winter olympics both.
select a.name  from athlete_events at
inner join athletes a
on a.id=at.athlete_id
where medal = 'gold'
group by name  
having count(distinct season)=2

--7 find players who won gold, silver and bronze medal in a single olympics. 
--print player name along with year.
select name, count(distinct medal) as three_medals_won, datepart(year,[year]) as yr from athletes a 
inner join athlete_events at 
on a.id=at.athlete_id
where medal in ('bronze','gold','silver')
group by name,datepart(year,[year])
having count(distinct medal)=3;

--8 find players who have won gold medals in consecutive 3 summer olympics in the same event . 
--Consider only olympics 2000 onwards. 
--Assume summer olympics happens every 4 year starting 2000. print player name and event name.
with cte as (
select name, datepart(year,[year]) as yr,[event]
from athletes a
inner join athlete_events at 
on a.id=at.athlete_id
where medal ='gold' and datepart(year,[year]) >= '2000' and season='Summer'
group by name, datepart(year,[year]) ,[event]),
B as (
select * , lag(yr,1) over(partition by name,event order by yr ) as prev_year
, lead(yr,1) over(partition by name,event order by yr ) as next_year
from cte)
select * from B 
where yr=prev_year+4 and yr=next_year-4


