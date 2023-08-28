-- convert all film titles to uppercase 
SELECT
	UPPER(title)
FROM public.film as myfilm

--calculate the len in hours(round by 2) for each film in the film table
SELECT
	ROUND(CAST(public.film.length AS NUMERIC)/60 , 2) as LengthInHours
FROM public.film  

--Extract the year from the last_update column in the actor table
SELECT
	EXTRACT(YEAR FROM CAST(last_update AS DATE)) AS YEAR
FROM public.actor

--2.COUNT total number of films in film table
SELECT
	COUNT(film_id) as totalFilms
FROM public.film
--avg rental rentalrate fo films in the film table
SELECT
	AVG(rental_rate) AS AvgRentalRate
FROM public.film
--highest and lowest film lenghts
SELECT
	MAX(film.length) as highestFilmLength,
	MIN(film.length) as lowestFilmLenght
FROM public.film
--total number of films in each film category
SELECT
	mycategory.name,
	COUNT(myfilm.film_id)
FROM public.film as myfilm
INNER JOIN public.film_category as myfilmcategory
ON myfilm.film_id = myfilmcategory.film_id
INNER JOIN public.category as mycategory
ON myfilmcategory.category_id = mycategory.category_id
GROUP BY
	mycategory.name
--3.RANK FILMS by length 
SELECT
	title,
	film.length,
	RANK() OVER (ORDER BY film.length DESC) AS filmLengthRank
FROM public.film
--calculate cummulative(running) sum of film lengths using sum
SELECT
	film_id,
	title,
	SUM(film.length) OVER( ORDER BY film_id) AS cumulativeFilmLength
FROM public.film
--for each film, get title of the next film in terms of alphabetical order using lead
SELECT
	title,
	LEAD(title) OVER(ORDER BY title) AS nextTitle
FROM public.film
--4. classify films in the film table based on their lengths
SELECT
	title,
	length,
	CASE 
		WHEN length < 60 THEN 'Short'
		WHEN length >= 60 AND length <= 120 THEN 'Medium'
		WHEN length > 120 THEN 'Long'
	END AS lengthCategory
FROM public.film
--use coalesce to replace null values in the amount with avg payment amount
SELECT
	payment_id,
	COALESCE(amount,(SELECT AVG(amount) FROM public.payment)) as amount
FROM public.payment
GROUP BY payment_id
--5. CREATE UDF film_category that accepts film title as input and returns 
--category of film
CREATE OR REPLACE FUNCTION film_category( seTitle TEXT)
RETURNS TABLE
(
	film_category TEXT
)
AS
$$	
BEGIN
	RETURN QUERY
		SELECT
			CAST(mycategory.name AS TEXT) AS CATEGORY
		FROM public.film AS myfilm
		INNER JOIN public.film_category as myfilmcat
		ON myfilm.film_id = myfilmcat.film_id
		INNER JOIN public.category as mycategory
		ON myfilmcat.category_id = mycategory.category_id
		WHERE myfilm.title = seTitle ;
END;
$$
LANGUAGE plpgsql;

select * from film_category(seTitle:='Airport Pollock') -- easyyyy

--udf total_rentals takes film title and returns count rental_id
CREATE OR REPLACE FUNCTION total_rentals(seTitle TEXT)
RETURNS TABLE
(
	total_rentals INT
)
AS
$$
BEGIN
	RETURN QUERY
		SELECT 
			CAST(COUNT(myrental.rental_id) AS INT)
		FROM public.film as myfilm
		INNER JOIN public.inventory AS myinven
		ON myfilm.film_id = myinven.film_id
		INNER JOIN public.rental as myrental
		ON myinven.inventory_id = myrental.inventory_id
		WHERE myfilm.title = seTitle;
END;
$$
LANGUAGE plpgsql;

select * from total_rentals(seTitle:='Airport Pollock')


--create udf customer_stats which takes customer_id :input
--retusns json containing the customer's name, total rentals, and total amount spent
CREATE OR REPLACE FUNCTION customer_stats(customerid INT)
RETURNS JSONB
AS
$$
DECLARE
	customer_name TEXT;
	total_rentals INT;
	total_amount NUMERIC;
	return_jsonb JSONB;
BEGIN
	SELECT
		CONCAT(myCustomer.first_name,' ',myCustomer.last_name),
		COUNT(myPayment.rental_id) ,
		COALESCE(SUM(myPayment.amount),0)
		INTO 
			customer_name,
			total_rentals,
			total_amount
	FROM public.customer as myCustomer
	LEFT OUTER JOIN public.payment AS myPayment
	ON myCustomer.customer_id = myPayment.customer_id
	WHERE 
		myCustomer.customer_id = customerid
	GROUP BY
		myCustomer.first_name,
		myCustomer.last_name;
		return_jsonb := json_build_object(
		'Name',customer_name,
		'TotalRentals',total_rentals,
		'TotalAmountSpent',total_amount`
		);
RETURN return_jsonb;
END;
$$
LANGUAGE plpgsql;

SELECT * FROM customer_stats(customerid:=1)










