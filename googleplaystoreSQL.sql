create database googleplaystore;

use googleplaystore;

select * from playstore;
truncate table playstore;

LOAD DATA INFILE 'D:/playstore.csv'
INTO TABLE playstore
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;


-- 1.	You're working as a market analyst for a mobile app development company. 
-- Your task is to identify the most promising categories (TOP 5) for launching new free apps based on their average ratings.

select Category, round(avg(Rating),2) as 'avg'
from playstore 
where Type = 'free'
group by Category
order by avg(Rating) desc
limit 5;


-- 2.	As a business strategist for a mobile app company, your objective is to pinpoint the three categories that generate the most revenue from paid apps. 
-- This calculation is based on the product of the app price and its number of installations.

select Category, avg(rev) as 'revenue'
from	
(select *,(Installs*Price) as 'rev'
from playstore
where type='paid')t 
group by category
order by revenue desc
limit 3;


-- 3.	As a data analyst for a gaming company, you're tasked with calculating the percentage of games within each category. 
-- This information will help the company understand the distribution of gaming apps across different categories.

select Category,(cnt/(select count(*) from playstore)*100) as 'percentage' from
(
select Category, count(App) as 'cnt' from playstore group by Category
)t ;


-- 4.	As a data analyst at a mobile app-focused market research firm 
-- you’ll recommend whether the company should develop paid or free apps for each category based on the ratings of that category.

with t1 as
(
select Category, round(avg(Rating),2) as 'Rating_of_free_apps' from playstore where Type = 'Free' group by Category
),
t2 as
(
select Category, round(avg(Rating),2) as 'Rating_of_paid_apps' from playstore where Type = 'Paid' group by Category
)
select *, (if (Rating_of_paid_apps > Rating_of_free_apps, 'develop paid apps','develop free apps')) as 'decision' from
(
select t1.Category, Rating_of_free_apps, Rating_of_paid_apps from t1 inner join t2 on t1.Category=t2.Category
)t ;


-- 5.	Suppose you're a database administrator your databases have been hacked and hackers are changing price of certain apps on the database, 
-- it is taking long for IT team to neutralize the hack, however you as a responsible manager don’t want your data to be changed, 
-- do some measure where the changes in price can be recorded as you can’t stop hackers from making changes.

create table priceChangeLog(
app varchar(20),
old_price decimal(10,2),
new_price decimal(10,2),
operation_type varchar(20),
operation_date timestamp
);

select * from priceChangeLog;

create table play as 
select * from playstore;

select * from play;

DELIMITER //
create trigger price_change_log
after update
on play
for each row
begin
	insert into priceChangeLog(app, old_price, new_price, operation_type, operation_date)
    values(new.app, old.price, new.price,'update', current_timestamp);
end;
// DELIMITER ;

set sql_safe_updates = 0;  

update play 
set price = 8
where App = 'Infinite Painter';

update play 
set price = 5
where App = 'Coloring book moana';


-- 6.	Your IT team have neutralized the threat; however, hackers have made some changes in the prices,
-- but because of your measure you have noted the changes, now you want correct data to be inserted into the database again.

select * from play as a inner join priceChangeLog b on a.app=b.app;

drop trigger price_change_log;

set sql_safe_updates = 0;  

update play as a
inner join priceChangeLog as b on a.app=b.app
set a.price=b.old_price;

select * from play where App = 'Infinite Painter';

-- 7.	As a data person you are assigned the task of 
-- investigating the correlation between two numeric factors: app ratings and the quantity of reviews.

set @x = (select round(avg(Rating),2) from playstore);
set @y = (select round(avg(Reviews),2) from playstore);
with t as
(
	select *, round((rat*rat),2) as 'sqrt_rat', round((rev*rev),2) as 'sqrt_rev'
	from
		(
			select Rating, @x, round((Rating-@x),2) as 'rat', Reviews, @y, round((Reviews-@y),2) as 'rev'
			from playstore
		)k
)
select * from t;
select @nemerator := round(sum((rat*rev)),2), @deno_1 := round(sum(sqrt_rat),2), @deno_2 := round(sum(sqrt_rev),2) from t;
select round(((@numerator)/(sqrt(@deno_1*@deno_2))),2) as 'corr_coefficient';


-- 8.	Your boss noticed that some rows in genres columns have multiple genres in them,
-- which was creating issue when developing the recommender system from the data he/she assigned you the task to clean the genres column and make two genres out of it, 
-- rows that have only one genre will have other column as blank.

delimiter //
create function f_name(a varchar(100))
returns varchar(100)
deterministic
begin
	set @l = locate(';',a);
    set @s = if(@l>0, left(a,@l - 1),a);
    return @s;
end;
// delimiter ;

delimiter //
create function l1_name(a varchar(100))
returns varchar(100)
deterministic
begin
	set @l = locate(';',a);
    set @s = if(@l=0,' ', substring(a,@l + 1,length(a)));
    return @s;
end;
// delimiter ;

select App, Genres, f_name(Genres) as 'Genre_1', l1_name(Genres) as 'Genre_2'
from playstore;
