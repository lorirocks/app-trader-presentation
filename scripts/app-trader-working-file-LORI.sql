--To get all play_store records
SELECT *
	FROM play_store_apps;

--To get all app_store records
SELECT *
	FROM play_store_apps;

--To get the count of play_store categories (33) and genres (119).
SELECT  COUNT (DISTINCT category)::numeric AS category, COUNT (DISTINCT genres)::numeric AS genres
	FROM play_store_apps;

--To get list of distinct currency types from app_store
SELECT currency
	FROM app_store_apps
	WHERE currency IS NOT NULL;

--FR0M DIEGO
--puts all apps in one table (overlap only counted once)
--
SELECT play_store_apps.category
	FROM app_store_apps FULL JOIN play_store_apps
	USING (name)
	ORDER BY name;

--FR0M DIEGO
--finds only the overlap
SELECT app_store_apps.primary_genre as app_genre, play_store_apps.genres as play_genre
	FROM app_store_apps FULL JOIN play_store_apps
	Using (name)
	WHERE app_store_apps.primary_genre IS NOT NULL AND play_store_apps.genres IS NOT NULL
	order by name;


SELECT COUNT(DISTINCT primary_genre) AS primary_genre 
FROM app_store_apps;
  --There are 23 distinct primary genres in the app_store (Apple).

SELECT COUNT(DISTINCT genres) AS genres, COUNT(DISTINCT category) AS category
FROM play_store_apps;
  --There are 119 genres and 33 category values in the play_store (Android).
  --"categories" in this table is more equivalent to "primary_genre" in the other table.
  --In the 

/*INNER JOIN of app_ & play_ table (designed by me)
	with naming protocols to create similar names (for readability), 
	and similar columns placed side by side. Excluded columns that only extist in one dataset 
	and were not needed for our analysis. */
--The below code was used as a CTE by other teammates, to standardize names of all calculations.
SELECT	
    app_store_apps.name AS name_a, play_store_apps.name AS name_p,
	app_store_apps.size_bytes AS size_a, play_store_apps.size AS size_p, 
	app_store_apps.price AS price_a, play_store_apps.price AS price_p, 
	app_store_apps.review_count AS rev_count_a, play_store_apps.review_count AS rev_count_p, 
	app_store_apps.rating AS rating_a, play_store_apps.rating AS rating_p, 
	app_store_apps.content_rating AS content_rating_a, play_store_apps.content_rating AS content_rating_p, 
	app_store_apps.primary_genre AS primary_genre_a, play_store_apps.category AS primary_genre_p, 
	play_store_apps.genres AS sub_genres_p, play_store_apps.install_count AS install_count_p 
FROM app_store_apps INNER JOIN play_store_apps USING (name);


SELECT DISTINCT (content_rating)
FROM play_store_apps;

--END initial work, personal------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------


--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
--From Ari & Diego - Friday 4/10/2020

SELECT *,profit_before_marketing_cost -  both_marketing_months*1000 AS both_profit
FROM ( SELECT *,
	  (app_lifespan*5000 - app_cost + play_lifespan*5000 - play_cost) AS profit_before_marketing_cost,
        --takes the highest lifespan then use it later to miltiply by 1000  as marketing cost
       (CASE WHEN app_lifespan>play_lifespan THEN app_lifespan
		ELSE play_lifespan END)
	    AS both_marketing_months
	  
--from Diego
      FROM ( SELECT  *,
--one time cost from buying the app. this depends on NULL values when app is only on one store
	       (CASE
		 --WHEN app_price IS NULL THEN 0
		   WHEN app_price<=1 THEN 10000
		   ELSE app_price*10000 END)
	       AS app_cost,
	
	      (CASE
		--WHEN play_price IS NULL THEN 0
		  WHEN play_price<=1 THEN 10000
		  ELSE play_price*10000 end)
	      AS play_cost,
	
--Turn rating to number of months, for 12 represents 1 year and so on.
	     CEIL(1+app_rating*2)*12 as app_lifespan,
	     CEIL(1+play_rating*2)*12 as play_lifespan
	    --CEIL(1+app_rating*2)*12*5000 AS app_revenue,
	    --CEIL(1+play_rating*2)*12*5000 AS play_revenue 
--from Diego	
--INNER JOIN both tables as subquery
        FROM (SELECT name,
		     app_store_apps.price as app_price, play_store_apps.price::money::numeric as play_price,
		     --Prices as money. for play_price, need to cast text to money then to numeric.
		     ROUND((COALESCE(app_store_apps.rating,0)/.5),0)*.5 as app_rating,
	         ROUND(COALESCE(play_store_apps.rating,0)/.5,0)*.5 as play_rating
		     --ratings, removing nulls and rounding to nearest .5
	         FROM app_store_apps INNER JOIN play_store_apps
	         Using (name)
             order by play_rating desc) as sub_query) AS total_profit) final_profit
	ORDER BY both_profit DESC;   --Added by Lori, to see top 10 both_profit (=net profit)
--WHERE app_price IS NOT NULL AND play_price IS NOT NULL

--END  From Ari & Diego - Friday 4/10/2020
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------

--START from Media - Sunday 4/12/2020
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------
---NOTE FROM LORI - Looks like revenue understated (shows for 12 mo. only, not full lifespan of app)

Select distinct name, genres, content_rating,  play_rating, round((1+play_rating/0.5), 0) as play_lifespan, app_rating, round((1+app_rating/0.5), 0) as app_lifespan

 -- to get maximum lifespan of play and app stores, we need to use case clause (2.c)
 , case when round((1+play_rating/0.5), 0) > round((1+app_rating/0.5), 0) then round((1+play_rating/0.5), 0) else round((1+app_rating/0.5), 0) end as max_lifespan

-- now multiply by 12,000 becuase we pay 12,000 per year (2.c)
 , (case when round((1+play_rating/0.5), 0) > round((1+app_rating/0.5), 0) then round((1+play_rating/0.5), 0) else round((1+app_rating/0.5), 0) end) * 12000 as cost_lifespan

-- calculate total revenue (2.b)
 , round((1+play_rating/0.5), 0) * 12 * 5000 as play_revenue --play_lifespan (year) x 12 months x 5000
 , round((1+app_rating/0.5), 0) * 12 * 5000 as app_revenue --app_lifespan (year) x 12 months x 5000
 , (round((1+play_rating/0.5), 0) * 12 * 5000) + (round((1+app_rating/0.5), 0) * 12 * 5000) as total_revenue -- play_revenue + app_revenue

-- calculate purchase cost (2.a)
  ,case when play_price >= 0 and play_price <=1 then 10000 else play_price * 10000 end as play_purchase 
  ,case when app_price >= 0 and app_price <=1 then 10000 else app_price * 10000 end as app_purchase
  ,(case when play_price >= 0 and play_price <=1 then 10000 else play_price * 10000 end) + (case when app_price >= 0 and app_price <=1 then 10000 else app_price * 10000 end) as total_purchase

-- calculate profit = total_revenue - cost_lifespan - total_purchase 
 , round((round((1+play_rating/0.5), 0) * 12 * 5000) + (round((1+app_rating/0.5), 0) * 12 * 5000) 
    - (case when round((1+play_rating/0.5), 0) > round((1+app_rating/0.5), 0) then round((1+play_rating/0.5), 0) else round((1+app_rating/0.5), 0) end) * 12000 
	- (case when play_price >= 0 and play_price <=1 then 10000 else play_price * 10000 end) + (case when app_price >= 0 and app_price <=1 then 10000 else app_price * 10000 end), 0)  as profit 

--, play_price, app_price, play_rating, app_rating, play_rev_count, app_rev_count, app_content_rating, genres --new column names

 from (
-- to get unique apps we need to use distinct in our subquery
 Select distinct p.name, p.price::money::numeric(5,2) as play_price, a.price as app_price
 		, round(p.rating/ 0.5, 0) * 0.5 as play_rating, round(a.rating/ 0.5, 0) * 0.5 as app_rating -- rounded rating by 0.5
		, p.review_count as play_rev_count, a.review_count::integer as app_rev_count
		, a.content_rating as content_rating --only using from app store bc description should be similar 
		, a.primary_genre as genres --only using from app store bc description should be similar
 from play_store_apps as P 
 inner join app_store_apps as A 
 using(name) 
) as sub_apps --use allias for subquery

-- order by profit to get the most profitable apps 
order by profit desc;
--limit 10;


--- END from Media
--------------------------------------------------------------------
--------------------------------------------------------------------
--------------------------------------------------------------------

--START MAIN PROJECT WORK - LORI ------
--------------------------------------------------------------------
--------------------------------------------------------------------
-----------HERE'S WHAT I'M TRYING TO DO. HAVE A PROBLEM!-----------------------
/*TRIAL:  , to get strongest correlations (positive or negative))
	overall plan is to FIRST find strong correlations between both_profit (using code from Ari & Diego),
	as compared to COMBINED data from both app_store and play_store (since both_profit is from both stores, combined)
	then SECOND export data to make scatter plots of the ones with strongest correlations, and
	THIRD STEP (in Excel) make a dynamic chart to show each of the strongest correlations.
PROBLEM:   

Practice to show correlation from several columns in same table. It works fine until I try to use a 
	COUNT, like a count of distinct ratings
*/
SELECT corr(price::numeric, size_bytes::numeric) AS corr_price_size
		, corr(price::numeric, review_count::numeric) AS corr_price_revcount
	--PROBLEM COUNT(DISTINCT category) returns bigint. Trying to CAST it to numeric. Works independently, but not in here
		--, corr(price::numeric, (COUNT (DISTINCT category)::numeric)) AS corr_price_rating
		--, corr(rating::numeric, content_rating::numeric) AS corr_price_content_rating
	FROM app_store_apps;

--Justlook at top 10/20 apps.   Better than correlation...


SELECT COUNT(DISTINCT rating)::numeric
	FROM app_store_apps;
	
SELECT *
	FROM app_store_apps
	LIMIT 10;



--DO NOT USE--
--------------------------------------------------------------
--CLEANED CODE FOR both_profit (i.e., net profit for apps in both stores) (from Ari & Diego)

WITH full_table AS (SELECT *, ROUND(profit_before_marketing_cost -  highest_lifespan_months*1000 , 0)::numeric AS both_profit_after_marketing_cost
					FROM (SELECT *, (app_lifespan*5000 - app_cost + play_lifespan*5000 - play_cost) AS profit_before_marketing_cost,
       		 			--takes the highest lifespan then use it later to miltiply by 1000  as marketing cost
						(CASE WHEN app_lifespan>play_lifespan THEN app_lifespan ELSE play_lifespan END) AS highest_lifespan_months
					FROM (SELECT  *,   --one time cost from buying the app. this depends on NULL values when app is only on one store
							(CASE WHEN app_price<=1 THEN 10000 ELSE app_price*10000 END) AS app_cost,			--WHEN app_price IS NULL THEN 0
							(CASE WHEN play_price<=1 THEN 10000	ELSE play_price*10000 end) AS play_cost,		--WHEN play_price IS NULL THEN 0
								CEIL(1+app_rating*2)*12 AS app_lifespan, 	 --Turn rating to number of months, for 12 represents 1 year and so on.
								CEIL(1+play_rating*2)*12 AS play_lifespan
								--CEIL((1+app_rating*2)*12)*5000 AS app_revenue,
								--CEIL(1+play_rating*2)*12*5000 AS play_revenue 
					FROM (SELECT DISTINCT(name), app_store_apps.price AS app_price, 
						  	play_store_apps.price::money::numeric AS play_price,
							 --Prices as money. for play_price, need to cast from text to money (to get $ to be recognized appropriately) then to numeric.
							 ROUND(COALESCE(app_store_apps.rating,0)/.5,0)*.5 AS app_rating,
							 ROUND(COALESCE(play_store_apps.rating,0)/.5,0)*.5 AS play_rating,
							 --ratings, removing nulls and rounding to nearest .5
							  app_store_apps.primary_genre AS primary_genre_app,
							  play_store_apps.category AS primary_genre_play
					FROM app_store_apps 
						INNER JOIN play_store_apps USING (name)
						 		) AS price_rating_genre
						 		) AS total_profit
						 		) AS final_profit
					--WHERE app_price IS NOT NULL AND play_price IS NOT NULL
					ORDER BY both_profit_after_marketing_cost DESC)

SELECT DISTINCT(app_cost), COUNT(*), ROUND(AVG(both_profit_after_marketing_cost),0) AS avg_net_profit
FROM full_table
GROUP BY app_cost
ORDER BY avg_net_profit DESC;
				  