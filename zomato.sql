select * from world.zomato_dataset;

#Total distinct country for country code
SELECT Distinct CountryCode FROM world.zomato_dataset;

# Give country name for mentioned countrycode with Join (2 table - Zomato dataset and country dataset)
select distinct c.CountryName, z.CountryCode
from world.zomato_dataset as z
Join  world.country_zomato as c
On z.CountryCode = c.CountryCode
order by 2 asc;

/* In how many countries zomato serves their services */
select count(distinct country_zomato.CountryName) as total_country
from world.zomato_dataset, world.country_zomato /*Joined the two tables */
where zomato_dataset.CountryCode = country_zomato.CountryCode;

# How many restaurants serves zomato service for each country
select c.CountryName, z.CountryCode, count(z.RestaurantID) as total_restaurants
from world.zomato_dataset as z
Join  world.country_zomato as c
On z.CountryCode = c.CountryCode
group by c.CountryName, z.CountryCode 
order by 2 asc;

#No. of restaurant in each city
select z.city, c.CountryName, count(z.RestaurantID) as total_restaurant
from world.zomato_dataset as z, world.country_zomato as c /*Joined the two tables */
where z.CountryCode = c.CountryCode
group by z.City, c.CountryName
order by 3 desc;

#Top 5 countries with most restaurant
select c.CountryName, count(z.RestaurantID) as total_restaurant
from world.zomato_dataset as z, world.country_zomato as c /*Joined the two tables */
where z.CountryCode = c.CountryCode
group by c.CountryName
ORDER BY 2 DESC
limit 5;

# Adding Country_name column 
SELECT z.CountryCode,c.CountryName
FROM  world.zomato_dataset as z
Join  world.country_zomato as c
On z.CountryCode = c.CountryCode;

ALTER TABLE world.zomato_dataset ADD COUNTRY_NAME VARCHAR(50);  /* Adding a new column as COUNRTY_NAME in first table  with Alter */

UPDATE world.zomato_dataset z
INNER JOIN world.country_zomato as c ON z.CountryCode = c.CountryCode
SET z.COUNTRY_NAME = c.CountryName;      /* Updating Country_Name from another table data with Update */
SELECT * FROM world.zomato_dataset ;

# City Column - Removing miss-spelled letter from city column
SELECT DISTINCT City FROM world.zomato_dataset 
WHERE CITY LIKE '%?%';					/*IDENTIFYING MISS-SPELLED WORD */

SELECT REPLACE(City,'?','i') 
FROM world.zomato_dataset WHERE City LIKE '%?%';         /*REPLACING MISS-SPELLED WORD */
UPDATE world.zomato_dataset SET City  = REPLACE(City,'?','i') 
WHERE City LIKE '%?%';	 			      /* UPDATING WITH REPLACE STRING FUNCTION */

SELECT Distinct City FROM world.zomato_dataset;

# CUISINES COLUMN 
SELECT Cuisines, COUNT(Cuisines) FROM world.zomato_dataset 
WHERE Cuisines IS NULL OR Cuisines = ' '
GROUP BY Cuisines
ORDER BY 2 DESC;


##DROP COLUMN,[LocalityVerbose][Address][Switch_to_order_menu]
ALTER TABLE world.zomato_dataset DROP COLUMN Address;
ALTER TABLE world.zomato_dataset DROP COLUMN LocalityVerbose;
ALTER TABLE world.zomato_dataset DROP COLUMN Switch_to_order_menu;

# ROLLING/MOVING COUNT OF Indian  RESTAURANTS IN INDIAN CITIES
SELECT COUNTRY_NAME,City,Locality,COUNT(Locality) TOTAL_REST,
SUM(COUNT(Locality)) OVER(PARTITION BY City ORDER BY Locality DESC) as Locality_per_City
FROM world.zomato_dataset
WHERE COUNTRY_NAME = 'INDIA'
GROUP BY  COUNTRY_NAME,City,Locality;

##WHICH COUNTRIES AND HOW MANY RESTAURANTS WITH PERCENTAGE PROVIDES ONLINE DELIVERY OPTION
CREATE VIEW COUNTRY_REST AS
(
  SELECT COUNTRY_NAME, COUNT(RestaurantID) AS REST_COUNT  #total restaurant as per country
  FROM world.zomato_dataset
  GROUP BY COUNTRY_NAME
);
SELECT * FROM COUNTRY_REST
ORDER BY 2 DESC;

SELECT A.COUNTRY_NAME,COUNT(A.RestaurantID) TOTAL_REST, 
ROUND(COUNT(CAST(A.RestaurantID AS DECIMAL))/CAST(B.REST_COUNT AS DECIMAL)*100, 2) as Online_Delivery_percent
FROM world.zomato_dataset A JOIN COUNTRY_REST B
ON A.COUNTRY_NAME = B.COUNTRY_NAME
WHERE A.Has_Online_delivery = 'YES'
GROUP BY A.COUNTRY_NAME,B.REST_COUNT
ORDER BY 2 DESC;

## FINDING FROM WHICH CITY AND LOCALITY IN INDIA WHERE THE MAX RESTAURANTS ARE LISTED IN ZOMATO
WITH CT1 AS
(
SELECT City,Locality,COUNT(RestaurantID) as REST_COUNT
FROM world.zomato_dataset
WHERE COUNTRY_NAME = 'INDIA'
GROUP BY CITY,LOCALITY
)
SELECT Locality,REST_COUNT FROM CT1 WHERE REST_COUNT = (SELECT MAX(REST_COUNT) FROM CT1);

##MOST POPULAR FOOD IN INDIA WHERE THE MAX RESTAURANTS ARE LISTED IN ZOMATO
CREATE VIEW Top_food AS    /*extracts individual cuisines from the "Cuisines" column*/
(
   SELECT COUNTRY_NAME, City, Locality, SUBSTRING_INDEX(SUBSTRING_INDEX(Cuisines, '|', n), '|', -1) AS Cuisines
   FROM world.zomato_dataset
   JOIN (
      SELECT 1 + units.i + tens.i * 10 AS n
      FROM (
         SELECT 0 AS i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
      ) units
      CROSS JOIN (
         SELECT 0 AS i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
         SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
      ) tens
   ) AS numbers
   WHERE n <= 1 + (LENGTH(Cuisines) - LENGTH(REPLACE(Cuisines, '|', '')))
);

WITH CT1
AS
(
SELECT City,Locality,COUNT(RestaurantID) as REST_COUNT
FROM world.zomato_dataset
WHERE COUNTRY_NAME = 'INDIA'
GROUP BY CITY,LOCALITY
),
CT2 AS (
SELECT Locality,REST_COUNT FROM CT1 WHERE REST_COUNT = (SELECT MAX(REST_COUNT) FROM CT1)
)
SELECT A.Cuisines, COUNT(A.Cuisines) as Total_Restaurant

FROM Top_food A JOIN CT2 B
ON A.Locality = B.Locality
GROUP BY B.Locality,A.Cuisines
ORDER BY 2 DESC;

## WHICH LOCALITIES IN INDIA HAS THE LOWEST RESTAURANTS LISTED IN ZOMATO
WITH CT1 AS
(
SELECT City,Locality, COUNT(RestaurantID) as REST_COUNT
FROM world.zomato_dataset
WHERE COUNTRY_NAME = 'INDIA'
GROUP BY City,Locality
)
SELECT * FROM CT1 WHERE REST_COUNT = (SELECT MIN(REST_COUNT) FROM CT1) ORDER BY CITY;

##HOW MANY RESTAURANTS OFFER TABLE BOOKING OPTION IN INDIA WHERE THE MAX RESTAURANTS ARE LISTED IN ZOMATO
WITH CT1 AS (
SELECT City,Locality,COUNT(RestaurantID) REST_COUNT
FROM world.zomato_dataset
WHERE COUNTRY_NAME = 'INDIA'
GROUP BY CITY,LOCALITY
),
CT2 AS (
SELECT Locality,REST_COUNT FROM CT1 WHERE REST_COUNT = (SELECT MAX(REST_COUNT) FROM CT1)
),
CT3 AS (
SELECT Locality,Has_Table_booking TABLE_BOOKING
FROM world.zomato_dataset
)
SELECT A.Locality, COUNT(A.TABLE_BOOKING) TABLE_BOOKING_OPTION
FROM CT3 A JOIN CT2 B
ON A.Locality = B.Locality
WHERE A.TABLE_BOOKING = 'YES'
GROUP BY A.Locality

## HOW RATING AFFECTS IN MAX LISTED RESTAURANTS WITH AND WITHOUT TABLE BOOKING OPTION (Connaught Place)
SELECT 'WITH_TABLE' TABLE_BOOKING_OPT,COUNT(Has_Table_booking) TOTAL_REST, ROUND(AVG(Rating),2) AVG_RATING
FROM  world.zomato_dataset
WHERE Has_Table_booking = 'YES' AND Locality = 'Connaught Place'
UNION
SELECT 'WITHOUT_TABLE' TABLE_BOOKING_OPT,COUNT([Has_Table_booking]) TOTAL_REST, ROUND(AVG([Rating]),2) AVG_RATING
FROM  world.zomato_dataset
WHERE Has_Table_booking = 'NO' AND Locality = 'Connaught Place';

## FINDING THE BEST RESTAURANTS WITH MODRATE COST FOR TWO IN INDIA HAVING INDIAN CUISINES
SELECT *
FROM world.zomato_dataset
WHERE COUNTRY_NAME = 'INDIA'
AND Has_Table_booking = 'YES'
AND Has_Online_delivery = 'YES'
AND Price_range <= 3
AND Votes > 1000
AND Average_Cost_for_two < 1000
AND Rating > 4
AND Cuisines LIKE '%INDIA%';

##FIND ALL THE RESTAURANTS THOSE WHO ARE OFFERING TABLE BOOKING OPTIONS WITH PRICE RANGE AND HAS HIGH RATING
SELECT Price_range, COUNT(Has_Table_booking) NO_OF_REST
FROM world.zomato_dataset
WHERE Rating >= 4.5
AND Has_Table_booking = 'YES'
GROUP BY Price_range; 
