
DROP VIEW IF EXISTS forestation;
CREATE VIEW forestation AS 
(
SELECT f.country_code f_country_code,
f.country_name f_country_name,
f.year f_year,
f.forest_area_sqkm f_area_sqkm,
l.country_code l_country_code,
l.country_name l_country_name,
l.year l_year,
l.total_area_sq_mi l_area_sq_mi,
r.country_name r_country_name,
r.country_code r_country_code,
r.region region,
r.income_group income_group,
l.total_area_sq_mi*2.59 l_area_sqkm,
ROUND((f.forest_area_sqkm/(l.total_area_sq_mi*2.59)*100)::numeric,2) percent_f_area
FROM forest_area f
JOIN land_area l ON f.year= l.year AND f.country_code=l.country_code
JOIN regions r  ON r.country_code= l.country_code);

/* 1.GLOBAL SITUATION
a. What was the total forest area (in sq km) of the world in 1990? Please keep in mind that you
can use the country record denoted as “World" in the region table.*/

SELECT SUM(f_area_sqkm)
FROM forestation
WHERE region ='World' AND f_year = 1990;

/*b. What was the total forest area (in sq km) of the world in 2016? Please keep in mind that you
can use the country record in the table is denoted as “World.”*/

SELECT SUM(f_area_sqkm)
FROM forestation
WHERE region = 'World' AND f_year = 2016;

/*c. What was the change (in sq km) in the forest area of the world from 1990 to 2016?*/

WITH F_90 AS
( SELECT f_country_code,SUM(f_area_sqkm) AS total_1990
FROM forestation
WHERE region = 'World' AND f_year =1990
GROUP BY 1
),
f_16 AS
(
SELECT f_country_code,SUM(f_area_sqkm) as total_2016
FROM forestation
WHERE region= 'World' AND f_year=2016
GROUP BY 1
)
SELECT f_90.f_country_code,(f_90.total_1990-f_16.total_2016 ) AS difference
FROM f_90
JOIN f_16 ON f_90.f_country_code= f_16.f_country_code
GROUP BY 1,2;

/*d. What was the percent change in forest area of the world between 1990 and 2016?*/

WITH F_90 AS
( SELECT f_country_code,SUM(f_area_sqkm) AS total_1990
FROM forestation
WHERE region = 'World' AND f_year =1990
GROUP BY 1
),
f_16 AS
(
SELECT f_country_code,SUM(f_area_sqkm) as total_2016
FROM forestation
WHERE region= 'World' AND f_year=2016
GROUP BY 1
)
SELECT f_90.f_country_code,ROUND(((f_90.total_1990-f_16.total_2016
)/f_90.total_1990*100)::numeric,2) AS percent_difference
FROM f_90
JOIN f_16 ON f_90.f_country_code= f_16.f_country_code
GROUP BY 1,2;

/*e. If you compare the amount of forest area lost between 1990 and 2016, to which
country's total area in 2016 is it closest to?*/

SELECT f_country_code, f_country_name, l_area_sq_mi
FROM forestation
WHERE l_area_sq_mi * 2.59 <
(SELECT
( SELECT forest_area_sqkm
FROM forest_area
WHERE country_name = 'World' AND year = 1990)-
(SELECT forest_area_sqkm
FROM forest_area
WHERE country_name = 'World' AND year = 2016))
AND f_year = '2016'
ORDER BY l_area_sq_mi DESC
LIMIT 1;


/*2. REGIONAL OUTLOOK
Create a table that shows the Regions and their percent forest area (sum of forest area divided
by sum of land area) in 1990 and 2016. (Note that 1 sq mi = 2.59 sq km).*/

DROP VIEW IF EXISTS region_percent;
CREATE VIEW region_percent AS
(SELECT region,f_year, ROUND((SUM(f_area_sqkm)/SUM(l_area_sqkm)*100)::numeric,2)
percent_region
FROM forestation
WHERE f_year=1990 OR f_year=2016
GROUP BY 1,2);
a. What was the percent forest of the entire world in 2016? Which region had the HIGHEST
percent forest
in 2016, and which had the LOWEST, to 2 decimal places?
SELECT *
FROM region_percent
WHERE f_year=2016 AND region='World';
SELECT region, MAX(percent_region) highest
FROM region_percent
WHERE f_year =2016
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;
SELECT region, MIN(percent_region) lowest
FROM region_percent
WHERE f_year =2016
GROUP BY 1
ORDER BY 2 ASC
LIMIT 1;
/*
b. What was the percent forest of the entire world in 1990? Which region had the HIGHEST
percent forest
in 1990, and which had the LOWEST, to 2 decimal places?*/

SELECT *
FROM region_percent
WHERE f_year=1990 AND region='World';
SELECT region, MAX(percent_region) highest
FROM region_percent
WHERE f_year =1990
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;
SELECT region, MIN(percent_region) lowest
FROM region_percent
WHERE f_year =1990
GROUP BY 1
ORDER BY 2 ASC
LIMIT 1;

/*c. Based on the table you created, which regions of the world DECREASED in forest area from
1990 to 2016?*/

With forest_percentage_1990 AS
(SELECT *
FROM region_percent
WHERE f_year=1990),
forest_percentage_2016 AS
(SELECT *
FROM region_percent
WHERE f_year=2016)
SELECT forest_percentage_1990.region,
forest_percentage_1990.percent_region fa_90,
forest_percentage_2016.percent_region fa_16
FROM forest_percentage_1990
JOIN forest_percentage_2016 ON
forest_percentage_1990.region=forest_percentage_2016.region
WHERE forest_percentage_1990.percent_region > forest_percentage_2016.percent_region;
3. COUNTRY-LEVEL DETAIL
SUCCESS STORIES
WITH forest_1990 AS
(SELECT f_country_code,f_country_name,f_year,f_area_sqkm,region,percent_f_area,
l_area_sqkm
FROM forestation
WHERE f_year=1990 ),
forest_2016 AS
(SELECT f_country_code,f_country_name,f_year,f_area_sqkm,region,percent_f_area,
l_area_sqkm
FROM forestation
WHERE f_year=2016),
JOIN_90_16 AS
(SELECT forest_2016.f_country_name country_name,
forest_1990.f_country_name,
forest_2016.f_country_code,
forest_1990.f_country_code,
forest_2016.region f_region,
forest_1990.region,
forest_2016.l_area_sqkm la_16,
forest_1990.l_area_sqkm  la_90,
forest_1990.f_area_sqkm fa_90,
forest_2016.f_area_sqkm fa_16,
forest_1990.percent_f_area p_fa_90,
forest_2016.percent_f_area p_fa_16
FROM forest_1990
JOIN forest_2016
ON forest_1990.f_country_code=forest_2016.f_country_code)
SELECT country_name,
f_region,
fa_90,
fa_16,
la_16,
la_90,
(fa_90-fa_16)  diff_area,
ABS(((p_fa_90-p_fa_16)/p_fa_90)*100) percent_diff
FROM JOIN_90_16
WHERE fa_90 IS NOT NULL AND fa_16 IS NOT NULL AND country_name!='World' AND
p_fa_90 !=0
ORDER BY 7
WITH forest_1990 AS
(SELECT f_country_code,f_country_name,f_year,f_area_sqkm,region,percent_f_area,
l_area_sqkm
FROM forestation
WHERE f_year=1990 ),
forest_2016 AS
(SELECT f_country_code,f_country_name,f_year,f_area_sqkm,region,percent_f_area,
l_area_sqkm
FROM forestation
WHERE f_year=2016),
JOIN_90_16 AS
(SELECT forest_2016.f_country_name country_name,
forest_1990.f_country_name,
forest_2016.f_country_code,
forest_1990.f_country_code,
forest_2016.region f_region,
forest_1990.region,
forest_2016.l_area_sqkm la_16,
forest_1990.l_area_sqkm  la_90,
forest_1990.f_area_sqkm fa_90,
forest_2016.f_area_sqkm fa_16,
forest_1990.percent_f_area p_fa_90,
forest_2016.percent_f_area p_fa_16
FROM forest_1990
JOIN forest_2016
ON forest_1990.f_country_code=forest_2016.f_country_code)
SELECT country_name,
f_region,
fa_90,
fa_16,
la_16,
la_90,
(fa_16-fa_90)  diff_area,
ABS(((p_fa_16-p_fa_90)/p_fa_90)*100) percent_diff
FROM JOIN_90_16
WHERE fa_90 IS NOT NULL AND fa_16 IS NOT NULL AND country_name!='World' AND
p_fa_90 !=0
ORDER BY 8 DESC
a. Which 5 countries saw the largest amount decrease in forest area from 1990 to 2016? What
was the difference
in forest area for each?
WITH forest_1990 AS
(SELECT f_country_code,f_country_name,f_year,f_area_sqkm,region
FROM forestation
WHERE f_year=1990 AND f_area_sqkm IS NOT NULL AND f_country_name!='World'),
forest_2016 AS
(SELECT f_country_code,f_country_name,f_year,f_area_sqkm,region
FROM forestation
WHERE f_year=2016 AND f_area_sqkm IS NOT NULL AND f_country_name!='World')
SELECT forest_2016.f_country_name,
forest_2016.f_country_code,
forest_2016.region,
forest_1990.f_area_sqkm fa_90,
forest_2016.f_area_sqkm fa_16,
forest_1990.f_area_sqkm - forest_2016.f_area_sqkm    f_area_diff
FROM forest_1990
JOIN forest_2016 ON forest_1990.f_country_code=forest_2016.f_country_code
WHERE forest_1990.f_area_sqkm IS NOT NULL AND forest_2016.f_area_sqkm IS NOT NULL
ORDER BY 6 DESC
LIMIT 5;
b. Which 5 countries saw the largest percent decrease in forest area from 1990 to 2016?
What was the percent change to 2 decimal places for each?
WITH forest_1990 AS
(SELECT f_country_code,f_country_name,f_year,f_area_sqkm,region,percent_f_area
FROM forestation
WHERE f_year=1990 AND f_area_sqkm IS NOT NULL AND f_country_name!='World'),
forest_2016 AS
(SELECT f_country_code,f_country_name,f_year,f_area_sqkm,region,percent_f_area
FROM forestation
WHERE f_year=2016 AND f_area_sqkm IS NOT NULL AND f_country_name!='World')
SELECT forest_2016.f_country_name,
forest_2016.f_country_code,
forest_2016.region,
forest_2016.percent_f_area p_16,
forest_1990.percent_f_area p_90,
forest_1990.f_area_sqkm f_90,
forest_2016.f_area_sqkm f_16,
forest_1990.f_area_sqkm - forest_2016.f_area_sqkm f_area_diff,
ABS(ROUND(((forest_1990.f_area_sqkm-forest_2016.f_area_sqkm)/forest_1990.f_area_sqkm*
100)::numeric,2)) percent_diff
FROM forest_1990
JOIN forest_2016 ON forest_1990.f_country_code=forest_2016.f_country_code
WHERE forest_1990.f_area_sqkm IS NOT NULL AND
forest_2016.f_area_sqkm IS NOT NULL AND forest_2016.f_country_name!='World' AND
forest_1990.f_area_sqkm>forest_2016.f_area_sqkm
ORDER BY percent_diff DESC
LIMIT 5;


--c. If countries were grouped by percent forestation in quartiles, which group had the most

countries in it in 2016?
WITH t1 AS (
SELECT f_country_name, percent_f_area,region,
CASE
WHEN percent_f_area <=25 THEN 1
WHEN percent_f_area >=25 AND percent_f_area <=50 THEN 2
WHEN percent_f_area >=50 AND percent_f_area <=75 THEN 3
ELSE 4
END AS quartiles
FROM forestation
WHERE f_year=2016 AND percent_f_area!=0 and f_country_name IS NOT NULL
GROUP BY 1,2,3
ORDER BY 1)
SELECT quartiles, count(f_country_name) countries
FROM t1
GROUP BY 1
ORDER BY 2 DESC;

--d. List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016

WITH t1 AS (
SELECT f_country_name, percent_f_area,region,
CASE
WHEN percent_f_area <=25 THEN 1
WHEN percent_f_area >=25 AND percent_f_area <=50 THEN 2
WHEN percent_f_area >=50 AND percent_f_area <=75 THEN 3
ELSE 4
END AS quartiles
FROM forestation
WHERE f_year=2016 AND percent_f_area!=0 and f_country_name IS NOT NULL
GROUP BY 1,2,3
ORDER BY 1)
SELECT f_country_name, quartiles, percent_f_area,region,count(*) as countries FROM T1
WHERE quartiles =4
GROUP BY 1,2,3,4
ORDER BY 3 DESC
e. How many countries had a percent forestation higher than the United States in 2016?
With t1 AS (SELECT f_country_code,
f_country_name,
f_year,
f_area_sqkm,
l_area_sqkm,
percent_f_area
FROM forestation
WHERE f_country_name != 'World' AND
f_area_sqkm IS NOT NULL AND
l_area_sq_mi IS NOT NULL AND f_year=2016
ORDER BY 6 DESC
)
SELECT COUNT(t1.f_country_name)
FROM t1
WHERE t1.percent_f_area > (SELECT t1.percent_f_area
FROM t1
