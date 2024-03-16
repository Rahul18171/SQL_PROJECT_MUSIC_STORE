/* Q1: Who is the senior most employee based on job title? */

select * from employee
order by levels desc
limit 1


/* Q2: Which countries have the most invoices? */

select * from invoice

select count(*) as count_of_invoices, billing_country
from invoice
group by billing_country
order by count_of_invoices desc


/* Q3: What are top 3 values of total invoice? */

select total from invoice
order by total desc
limit 3


/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select sum(total) as invoice_total, billing_city
from invoice
group by billing_city
order by invoice_total desc

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

select customer.customer_id,customer.first_name,customer.last_name, sum(invoice.total) as total
from customer
join invoice on customer.customer_id=invoice.customer_id
group by customer.customer_id
order by total desc
limit 1


/*Q5:Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */

select distinct email as Email, first_name as FirstName, last_name as LastName, genre.name as Name
from customer
join invoice on invoice.customer_id=customer.customer_id
join invoice_line on invoice_line.invoice_id=invoice.invoice_id
join track on track.track_id=invoice_line.track_id
join genre on genre.genre_id=track.genre_id
where genre.name like 'Rock'
order by email;


/* Q6:Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select artist.artist_id,artist.name,count(artist.artist_id) as number_of_songs
from track
join album on album.album_id=track.album_id
join artist on artist.artist_id=album.artist_id
join genre on genre.genre_id=track.genre_id
where genre.name Like 'Rock'
group by artist.artist_id
order by number_of_songs desc
limit 10

/* Q7:Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

select name,milliseconds 
from track 
where milliseconds > (
          select avg(milliseconds) as avg_track_length
	      from track)
order by milliseconds desc


/* Q8:Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

with best_selling_artist as(
    select artist.artist_id as artist_id, artist.name as artist_name,
	sum(invoice_line.unit_price*invoice_line.quantity) as total_sales
	from invoice_line
	join track on track.track_id=invoice_line.track_id
	join album on album.album_id=track.album_id
	join artist on artist.artist_id=album.artist_id
	group by 1
	order by 3 desc
	limit 1
)
select customer.customer_id,customer.first_name,customer.last_name,best_selling_artist.artist_name,
sum(invoice_line.unit_price*invoice_line.quantity) as amount_spent
from invoice
join customer on customer.customer_id=invoice.customer_id
join invoice_line on invoice_line.invoice_id=invoice.invoice_id
join track on track.track_id=invoice_line.track_id
join album on album.album_id=track.album_id
join best_selling_artist on best_selling_artist.artist_id=album.artist_id
group by 1,2,3,4
order by 5 desc



/* Q9:We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

with popular_genre as(
      select count(invoice_line.quantity) as purchases,customer.country,genre.name,genre.genre_id,
	  ROW_NUMBER() OVER(partition by customer.country order by count(invoice_line.quantity) desc) as RowNo
	  from invoice_line
	  join invoice on invoice.invoice_id=invoice_line.invoice_id
	  join customer on customer.customer_id=invoice.customer_id
	  join track on track.track_id=invoice_line.track_id
	  join genre on genre.genre_id= track.genre_id
	  group by 2,3,4
	  order by 2 asc, 1 desc
)
  select* from popular_genre where RowNo <= 1
  
  
/* Q10:Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

WITH RECURSIVE
    customer_with_country as(
	   select customer.customer_id,first_name,last_name,billing_country, sum(total) as total_spending
	   from invoice
	   join customer on customer.customer_id=invoice.customer_id
	   group by 1,2,3,4
       order by 1,5 desc),
	   
	country_max_spending as(
	   select billing_country, max(total_spending) as max_spending
	   from customer_with_country
	   group by billing_country)
	
	select cc.billing_country,cc.first_name,cc.last_name,cc.total_spending,cc.customer_id
	from customer_with_country cc
	join country_max_spending ms
	on cc.billing_country=ms.billing_country
	where cc.total_spending=ms.max_spending
	order by 1
    
	-- with cte method
	
	with customer_with_country as(
	      select customer.customer_id,first_name,last_name,billing_country,sum(total) as total_spending,
		  Row_number() over(partition by billing_country order by sum(total) desc) as RowNo
		  from 	invoice
		  join customer on customer.customer_id=invoice.customer_id
		  group by 1,2,3,4
		  order by 4 asc, 5 desc)
	select*from customer_with_country where RowNo <=1
	