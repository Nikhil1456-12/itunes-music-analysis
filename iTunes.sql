use itunes_analysis;
SELECT COUNT(*) FROM album;
SELECT COUNT(*) FROM artist;
SELECT COUNT(*) FROM customer;
SELECT COUNT(*) FROM employee;
SELECT COUNT(*) FROM genre;
SELECT COUNT(*) FROM invoice;
SELECT COUNT(*) FROM invoiceline;
SELECT COUNT(*) FROM playlist;
SELECT COUNT(*) FROM playlisttrack;
SELECT COUNT(*) FROM track;
SELECT COUNT(*) FROM mediatype;
-- part 3: data cleaning (phase 8)

-- check for null values in critical columns
select 'customer email null check' as check_type, count(*) as null_count
from customer
where email is null;

select 'employee email null check' as check_type, count(*) as null_count
from employee
where email is null;

select 'track unit_price null check' as check_type, count(*) as null_count
from track
where unit_price is null;

-- check for duplicates in primary key columns
select 'customer duplicates' as check_type, customer_id, count(*)
from customer
group by customer_id
having count(*) > 1;

select 'employee duplicates' as check_type, employee_id, count(*)
from employee
group by employee_id
having count(*) > 1;

select 'track duplicates' as check_type, track_id, count(*)
from track
group by track_id
having count(*) > 1;

-- check for orphaned records (foreign key violations)
select 'orphaned albums' as check_type, count(*) as orphan_count
from album a
left join artist ar on a.artist_id = ar.artist_id
where ar.artist_id is null;

select 'orphaned tracks' as check_type, count(*) as orphan_count
from track t
left join album a on t.album_id = a.album_id
where a.album_id is null;

-- part 4: exploratory analysis
-- q1: senior most employee
select *
from employee
order by  levels desc
limit 1;

-- q2: countries with most invoices
select billing_country,
count(*) as invoice_count
from invoice
group by billing_country
order by invoice_count desc;

-- q3: top 3 invoice values
select distinct total
from invoice
order by total desc
limit 3;

-- q4: best city by revenue
select billing_city,
sum(total) as revenue
from invoice
group by billing_city
order by revenue desc
limit 1;

-- q5: best customer (highest spender)
select c.first_name,
c.last_name,
sum(i.total) as total_spent
from customer c
join invoice i on c.customer_id = i.customer_id
group by c.customer_id, c.first_name, c.last_name
order by total_spent desc
limit 1;

-- q6: rock music listeners
select distinct c.email,
c.first_name,
c.last_name
from customer c
join invoice i on c.customer_id = i.customer_id
join invoiceline il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
where g.name = 'rock'
order by email;

-- q7: top rock artists
select ar.name as artist_name,
count(*) as track_count
from artist ar
join album al on ar.artist_id = al.artist_id
join track t on al.album_id = t.album_id
join genre g on t.genre_id = g.genre_id
where g.name = 'rock'
group by ar.artist_id, ar.name
order by track_count desc
limit 10;

-- q8: songs longer than average
select name as track_name,
milliseconds
from track
where milliseconds > (select avg(milliseconds) from track)
order by milliseconds desc;

-- q9: customer spending by artist
select concat(c.first_name, ' ', c.last_name) as customer_name,
ar.name as artist_name,
sum(il.unit_price * il.quantity) as total_spent
from customer c
join invoice i on c.customer_id = i.customer_id
join invoiceline il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join album al on t.album_id = al.album_id
join artist ar on al.artist_id = ar.artist_id
group by customer_name, artist_name
order by total_spent desc;

-- q10: most popular genre by country
with genre_sales as (
select i.billing_country,
g.name as genre_name,
count(*) as purchase_count
from invoice i
join invoiceline il on i.invoice_id = il.invoice_id
join track t on il.track_id = t.track_id
join genre g on t.genre_id = g.genre_id
group by i.billing_country, g.name
),
ranked_genres as (
select *,
rank() over (partition by billing_country order by purchase_count desc) as rank_num
from genre_sales
)
select billing_country, genre_name, purchase_count
from ranked_genres
where rank_num = 1
order by billing_country;

-- q11: top customer by country
with customer_spending as (
select c.customer_id,
concat(c.first_name, ' ', c.last_name) as customer_name,
i.billing_country,
sum(i.total) as total_spent
from customer c
join invoice i on c.customer_id = i.customer_id
group by c.customer_id, customer_name, i.billing_country
),
ranked_customers as (
select *,
rank() over (partition by billing_country order by total_spent desc) as rank_num
from customer_spending
)
select billing_country, customer_name, total_spent
from ranked_customers
where rank_num = 1
order by billing_country;

-- q12: most popular artists
select ar.name as artist_name,
sum(il.quantity) as total_sales
from artist ar
join album al on ar.artist_id = al.artist_id
join track t on al.album_id = t.album_id
join invoiceline il on t.track_id = il.track_id
group by ar.artist_id, ar.name
order by total_sales desc
limit 5;

-- q13: most popular song
select t.name as track_name,
sum(il.quantity) as total_quantity_sold
from track t
join invoiceline il on t.track_id = il.track_id
group by t.track_id, t.name
order by total_quantity_sold desc
limit 1;

-- q14: average price by media type
select m.name as media_type_name,
avg(t.unit_price) as avg_price
from track t
join mediatype m on t.media_type_id = m.media_type_id
group by m.name;

-- q15: revenue by country
select billing_country,
sum(total) as total_revenue
from invoice
group by billing_country
order by total_revenue desc;
