==================================================================================

										🚖 Uber Trip Data Analysis Using SQL Server

										-- 📌 Description: [Phase 2: Data Analyze]

==================================================================================


									🧭 Main Goal (Project Focus):


🔍 "Analyze how Uber rider behavior, demand patterns, and trip efficiency evolved from 2009 to 2015 to identify operational opportunities and behavioral shifts."

This is a defensible business question — no surge price assumption needed — and a strong real-world problem that reflects growth, efficiency, and strategic insights.

================================================================================
  File Name   : Uber_DataAnalysis.sql
  Author      : Santhosh
  Description : This view identifies directional imbalances in Uber trip flows 
                between pickup and dropoff zones, helping spot areas with more 
                departures than arrivals and vice versa.
  Created On  : [Enter Date]
  Dataset     : Uber Fares Dataset from Kaggle
               https://www.kaggle.com/datasets/yasserh/uber-fares-dataset
================================================================================


====================================================================================================================================================

/*  
Set the current database context
--------------------------------
This ensures all subsequent queries, views, and objects 
are created within the 'UBER' database.
*/

USE UBER;

====================================================================================================================================================


ALTER TABLE UBER ALTER COLUMN [DATE]  DATE;

ALTER TABLE UBER ALTER COLUMN [TIME]  TIME;

SELECT * FROM UBER

====================================================================================================================================================
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
													Task 1
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
====================================================================================================================================================
/*

1. 🗓️ Yearly Demand and Revenue Trend
What to track:

Total Trips

Total Revenue (fare_amount)

Total Distance

Revenue per KM / Revenue per Trip

View: vw_AnnualSummary

Why: Establishes long-term trend — useful for strategic deployment planning

Visualization: Line graph (Year vs Revenue/Trips)

*/

====================================================================================================================================================
										-- year Summary
====================================================================================================================================================

/* 
   Objective:
   ----------
   Generate yearly summary metrics for Uber rides:
   - Total Revenue
   - Average Revenue
   - Total Distance
   - Average Distance
   - Trip Count
   - Revenue per KM
   - Revenue per Trip

   Additional Note:
   ----------------
   2015 data includes only the first 6 months, so comparisons should consider this.
*/



						-- CTE 1: Year_Summary
						--CREATE VIEW vw_trip_summary_yearly AS
						SELECT 
							DATEPART(YEAR, [DATE]) AS [Year],                  -- Extract year from DATE column
							SUM(fare_amount) AS Total_Revenue,                 -- Total revenue per year
							AVG(fare_amount) AS Avg_Revenue,                   -- Average revenue per ride
							SUM(Distance_Km) AS Total_Distance,                -- Total distance traveled
							AVG(Distance_Km) AS Avg_Distance,                  -- Average distance per ride
							COUNT([Key]) AS Trip_Count,                        -- Number of rides per year
							SUM(fare_amount) / NULLIF(SUM(Distance_Km), 0) AS Revenue_per_KM,  -- Total revenue / total distance
							SUM(fare_amount) / COUNT([Key]) AS Revenue_per_Trip -- Total revenue / total trips
						FROM Uber
						WHERE Anomaly =0
						GROUP BY DATEPART(YEAR, [DATE])
						ORDER BY DATEPART(YEAR, [DATE]);

-- Note: 2015 has only 6 months of data. Consider this when comparing yearly results.


====================================================================================================================================================
									--Monthly_Summary
====================================================================================================================================================

/* 
   Objective:
   ----------
   1) Summarize trips monthly with trip count, total distance, and total revenue.
   2) Rank months within each year by trip count.
   3) Return the top 5 months per year.

   Dataset:
   --------
   Table: Uber
   Columns:
     - [DATE]        : Ride date
     - [Key]         : Unique ride ID
     - Distance_Km   : Distance of each ride
     - fare_amount   : Revenue for each ride
*/

									--CREATE VIEW  vw_trip_summary_monthly AS
									-- CTE 1: Monthly summary metrics
									WITH Monthly_Summary AS (
										SELECT
											DATEPART(YEAR, [DATE]) AS [Year],
											DATEPART(MONTH, [DATE]) AS [Monthly],
											DATENAME(MONTH, [DATE]) AS [Month_Name],
											COUNT([Key]) AS Trip_count,
											SUM(Distance_Km) AS Total_Distance,
											SUM(fare_amount) AS Total_Revenue
										FROM Uber
										WHERE Anomaly = 0
										GROUP BY
											DATEPART(YEAR, [DATE]),
											DATEPART(MONTH, [DATE]),
											DATENAME(MONTH, [DATE])
									),

									-- CTE 2: Rank months within each year by trip count
									Ranked_Month AS (
										SELECT *,
											ROW_NUMBER() OVER (PARTITION BY [Year] ORDER BY Trip_count DESC) AS rn
										FROM Monthly_Summary
									)

									-- Final Output: Top 5 months by trip count per year
									SELECT 
										[Year], 
										[Monthly],
										[Month_Name], 
										Trip_count, 
										Total_Distance, 
										Total_Revenue
									FROM Ranked_Month
									WHERE rn <= 5
									ORDER BY [Year], rn;

====================================================================================================================================================
									--Weekend vs Weekday 
====================================================================================================================================================

/* 
   Objective:
   ----------
   1) Classify each ride day as 'Weekend' or 'Weekday'.
   2) Calculate trip count, total distance, and total revenue for each day.
   3) Aggregate results at Year + Day_Type level.

   Dataset:
   --------
   Table: Uber
   Columns:
     - [DATE]        : Ride date
     - [Key]         : Unique ride ID
     - Distance_Km   : Distance of each ride
     - fare_amount   : Revenue for each ride
*/

								-- CTE: Daily Summary with Weekend/Weekday Classification
								WITH CTE_Week_Summary AS (
									SELECT
										DATEPART(YEAR, [DATE]) AS [Year],
										DATEPART(MONTH, [DATE]) AS [Monthly],
										[DATE],
										DATENAME(WEEKDAY, [DATE]) AS [Day_Name],
										CASE 
											WHEN DATENAME(WEEKDAY, [DATE]) IN ('Saturday','Sunday') THEN 'Weekend'
											ELSE 'Weekday'
										END AS Day_Type,
										COUNT([Key]) AS Trip_Count,        -- Daily Trip Count
										SUM(Distance_Km) AS Total_Distance, -- Daily Distance
										SUM(fare_amount) AS Total_Revenue   -- Daily Revenue
									FROM Uber
									WHERE Anomaly = 0
									GROUP BY
										DATEPART(YEAR, [DATE]),
										DATEPART(MONTH, [DATE]),
										[DATE]
								)

								-- Final Aggregation: Sum metrics by Year and Day_Type
								SELECT 
									[Year],
									Day_Type,
									SUM(Total_Distance) AS Total_Distance,
									SUM(Trip_Count) AS Trip_Count,     -- we sum Here because we already did Count in Sub-query And i dont want to add this column in GROUP BY(Work around)
									SUM(Total_Revenue) AS Total_Revenue --i dont want to add this column in GROUP BY(Work around)
								FROM CTE_Week_Summary
								GROUP BY 
									[Year], Day_Type
								ORDER BY 
									[Year], Day_Type;




====================================================================================================================================================
									--Hourly_Summary
====================================================================================================================================================



-- CTE 2: Hourly_Summary


/* 
   Objective:
   ----------
   1) Summarize trips hourly with trip count, total distance, and total revenue.
   2) Rank hours within each year by trip count.
   3) Return top 5 hours per year based on trip demand.

   Dataset:
   --------
   Table: Uber
   Columns:
     - [DATE]        : Ride date
     - [TIME]        : Ride time
     - [Key]         : Unique ride ID
     - Distance_Km   : Distance of each ride
     - fare_amount   : Revenue for each ride
*/

								-- CTE 1: Hourly Summary
								WITH Hourly_Summary AS (
								--CREATE VIEW vw_trip_demand_hourly_yearly AS
									SELECT
										DATEPART(YEAR, [DATE]) AS [Year],
										DATEPART(MONTH, [DATE]) AS [Monthly],
										DATENAME(MONTH, [DATE]) AS [Month_Name],
										DATEPART(HOUR, [TIME]) AS Hour_Of_Day,
										COUNT([Key]) AS Trip_Count,
										SUM(Distance_Km) AS Total_Distance,
										SUM(fare_amount) AS Total_Revenue
									FROM Uber
									WHERE Anomaly = 0
									GROUP BY
										DATEPART(YEAR, [DATE]),
										DATEPART(MONTH, [DATE]),
										DATENAME(MONTH, [DATE]),
										DATEPART(HOUR, [TIME])
										--Order by DATEPART(Year, [DATE]),
										--		DATEPART(Month, [DATE]),
										--		DATEPART(HOUR, [TIME]) 
																),

									-- CTE 2: Rank hours by trip count within each year
								Ranked_Hours AS (
									SELECT *,
										ROW_NUMBER() OVER (PARTITION BY [Year] ORDER BY Trip_Count DESC) AS rn
									FROM Hourly_Summary
										)

																-- Final Output: Top 5 hours by trip count per year
									SELECT 
										[Year],
										[Monthly],
										[Month_Name],
										Hour_Of_Day,
										Trip_Count,
										Total_Distance,
										Total_Revenue
									FROM Ranked_Hours
									WHERE rn <= 5
									ORDER BY [Year], rn;




====================================================================================================================================================
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
												Task 2: Trip Distance Behavior Over Time 🚗


Analyze how trip distances changed over the years. Did people start taking longer or shorter trips over time?

&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
====================================================================================================================================================

-- Creatining a Function of distanceCategory for easier query build

CREATE FUNCTION dbo.GetDistanceCategory (@DistanceKm FLOAT)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @Category VARCHAR(20);

    SET @Category = 
        CASE
            WHEN @DistanceKm < 5 THEN 'Very_Short'
            WHEN @DistanceKm BETWEEN 5 AND 10 THEN 'Short'
            WHEN @DistanceKm BETWEEN 10 AND 20 THEN 'Long'
            WHEN @DistanceKm BETWEEN 20 AND 30 THEN 'Very_Long'
            WHEN @DistanceKm > 30 THEN 'Outer-city'
            ELSE 'Invalid'
        END;

    RETURN @Category;
END;







====================================================================================================================================================
												Main 
-- CTE 3: Distance_Category

/* error
								WITH CTE_Distance_Category AS (
								--CREATE VIEW Distance_Category AS
									SELECT 
											COUNT([Key]) AS [Trip_Count],
											DATEPART(Year, [DATE]) AS [Year],
											DATEPART(Month, [DATE]) AS [Monthly],
											 DATEPART(HOUR, [TIME]) AS Hour_Of_Day,
											 SUM(Distance_Km) AS Total_Distance_Km , 
										CASE
											WHEN Distance_Km < 5 THEN 'Very_Short'
											WHEN DIstance_Km  Between 5 AND 10  THEN 'Short'
											WHEN DIstance_Km  Between 10 AND 20  THEN 'Long'
											WHEN Distance_Km > 20 THEN 'Very_Long'
											ELSE 'Invalid'
										END AS Distance_Category
									FROM Uber
								GROUP BY DATEPART(Year, [DATE]),
											DATEPART(Month, [DATE]),
											DATEPART(HOUR, [TIME])

								--ORDER BY	DATEPART(Year, [DATE]),
								--			DATEPART(Month, [DATE]),
								--			DATEPART(HOUR, [TIME])
								)
								SELECT 
									Sum(Trip_Count) AS Trip_Count, -- we sum Here because we already did Count in Sub-query And i dont want to add this column in GROUP BY(Work around),
									[Year], 
									SUM(Total_Distance_Km) AS Total_Distance_Km, 
									Distance_Category 
								FROM 
									CTE_Distance_Category
								GROUP BY 
									 [Year],  
									Distance_Category
								ORDER BY [Year]
*/

/*
You can use the column directly in the CASE statement—what you wrote is valid.

However, the problem in your query is not the CASE. It’s with mixing aggregate functions (COUNT, SUM) with non-aggregated columns (Distance_Km) in CASE.

Why the Error Happens
When you use GROUP BY, every column in SELECT must either:

Be in the GROUP BY, OR

Be inside an aggregate function.

Your CASE currently references Distance_Km directly.
Since you grouped by year, month, hour only, Distance_Km is not grouped or aggregated,

------------------------------------------- easy to under stance -------------------------------------
Distance_Km is not in GROUP BY, and your CASE uses it directly.

It is not functionally dependent on any grouped column like [DATE].

SQL Server doesn’t know which Distance_Km value to use for each group because there are multiple rows per group with different distances.

*/

====================================================================================================================================================
====================================================================================================================================================


/* 
   Objective:
   ----------
   1) Categorize trips based on distance into buckets: Very_Short, Short, Long, Very_Long.
   2) Aggregate total trips and total distance per year for each distance category.

   Dataset:
   --------
   Table: Uber
   Columns:
     - [DATE]         : Ride date
     - [TIME]         : Ride time
     - [Key]          : Unique ride ID
     - Distance_Km    : Distance for each ride
*/


								-- CTE: Categorize trips by distance
									WITH CTE_Distance_Category AS (
										SELECT 
											DATEPART(YEAR, [DATE]) AS [Year],
											DATEPART(MONTH, [DATE]) AS [Monthly],
											DATEPART(HOUR, [TIME]) AS Hour_Of_Day,
											dbo.GetDistanceCategory(Distance_Km) AS Distance_Category,
											COUNT([Key]) AS Trip_Count,
											SUM(Distance_Km) AS Total_Distance_Km
										FROM Uber
										WHERE Anomaly = 0
										GROUP BY 
											DATEPART(YEAR, [DATE]),
											DATEPART(MONTH, [DATE]),
											DATEPART(HOUR, [TIME]),
											dbo.GetDistanceCategory(Distance_Km)
									)

									-- Final Aggregation: Summarize by Year & Distance Category
									SELECT 
										[Year], 
										Distance_Category,
										SUM(Trip_Count) AS Trip_Count,
										SUM(Total_Distance_Km) AS Total_Distance_Km
									FROM CTE_Distance_Category
									GROUP BY 
										[Year], Distance_Category
									ORDER BY 
										[Year], Distance_Category;




/*
Note - 
distance_km can i use it directly in group by without in select ?
Yes, you can. SQL Server allows this, but it’s unusual because the grouped column still affects the grouping.
*/
------------------------------------------------------------------------or-----(DIFFERENT RESULT)------------------------------


								WITH CTE_Distance_Category AS (
									SELECT *,
									dbo.GetDistanceCategory(Distance_Km) AS Distance_Category,
									FROM Uber
									WHERE Anomaly = 0
								)
								SELECT 
									COUNT([Key]) AS Trip_Count,
									DATEPART(Year, [DATE]) AS [Year],
									DATEPART(Month, [DATE]) AS [Monthly],
									DATEPART(HOUR, [TIME]) AS Hour_Of_Day,
									SUM(Distance_Km) AS Total_Distance_Km,
									Distance_Category
								FROM CTE_Distance_Category
								GROUP BY
									DATEPART(Year, [DATE]),
									DATEPART(Month, [DATE]),
									DATEPART(HOUR, [TIME]),
									Distance_Category
								ORDER BY DATEPART(Year, [DATE]),
									DATEPART(Month, [DATE]),
									DATEPART(HOUR, [TIME]) ;




====================================================================================================================================================

        --summarize your distance categories per year to see the trend of short vs long trips over time.


/*  
Objective:
----------
Calculate the percentage distribution of trips across different distance categories for each year.

Details:
1. Step 1 (CTE - CTE_Distance_Category):
   - Add a derived column "Distance_Category":
        * Very_Short → Distance < 5 km
        * Short      → 5–10 km
        * Long       → 10–20 km
        * Very_Long  → > 20-30km
        * Outer-city  → > 30 km
        * Invalid    → For null/unexpected values

2. Step 2 (Final SELECT):
   - For each Year & Distance_Category:
        * Total_Trip → Number of trips
        * Pct_of_Trip → % share of trips in that category for the year
          Formula: (Trips in category ÷ Total trips for year) × 100

Use Case:
---------
This query helps in:
- Understanding yearly trip distribution by distance.
- Identifying dominance of short vs long rides over time.
- Feeding insights into strategy for pricing/demand forecasting.
*/

										WITH CTE_Distance_Category AS (
										--CREATE VIEW Distance_Category AS
											SELECT 
												[Key],
												DATEPART(YEAR, [DATE]) AS [Year],
												DATEPART(MONTH, [DATE]) AS [Monthly],
												DATEPART(HOUR, [TIME]) AS Hour_Of_Day,
												Distance_Km,
												CASE
											WHEN Distance_Km < 5 THEN 'Very_Short'
											WHEN Distance_Km BETWEEN 5 AND 10 THEN 'Short'
											WHEN Distance_Km BETWEEN 10 AND 20 THEN 'Long'
											WHEN Distance_Km BETWEEN 20 AND 30 THEN 'Very_Long'
											WHEN Distance_Km > 30 THEN 'Outer-city'
													ELSE 'Invalid'
												END AS Distance_Category
											FROM Uber
											WHERE Anomaly = 0
										)
										SELECT 
											[Year],
											Distance_Category,
											COUNT([Key]) AS Total_Trip,
											CAST(
												COUNT([Key]) * 100.0 / 
												SUM(COUNT([Key])) OVER (PARTITION BY [Year]) 
												AS DECIMAL(5,2)
											) AS Pct_of_Trip
										FROM CTE_Distance_Category
										GROUP BY [Year], Distance_Category
										ORDER BY [Year], Distance_Category;








====================================================================================================================================================
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
												Task 3: Fair Valuation 

&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
====================================================================================================================================================


-- Calculate average fare per km for all trips (excluding zero or near-zero distances)
SELECT 
    AVG(fare_amount / NULLIF(distance_km, 0)) AS avg_fare_per_km
FROM Uber
WHERE distance_km > 0
	AND Anomaly = 0;

-- Identify trips where fare per km is anomalously low or high 
-- using thresholds (e.g. 50% below or 3 times above average)
WITH FareStats AS (
    SELECT 
        AVG(fare_amount / NULLIF(distance_km, 0)) AS avg_fare_per_km
    FROM Uber
    WHERE distance_km > 0
		AND Anomaly = 0
)
SELECT 
    *,
    fare_amount / NULLIF(distance_km, 0) AS fare_per_km,
    CASE 
        WHEN fare_amount / NULLIF(distance_km, 0) < 0.5 * (SELECT avg_fare_per_km FROM FareStats) THEN 'Low Fare Anomaly'
        WHEN fare_amount / NULLIF(distance_km, 0) > 3 * (SELECT avg_fare_per_km FROM FareStats) THEN 'High Fare Anomaly'
        ELSE 'Normal'
    END AS Anomaly_Type
FROM Uber
WHERE distance_km > 0;

















====================================================================================================================================================
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
												Task 3: Occupancy Trend Over the Years


Goal for Task 3

Trip count per passenger_count per year

% of trips that are single-passenger vs multi-passenger

Optional: Cross-check with trip distance to see if long trips tend to have more passengers.

&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
====================================================================================================================================================
SELECT * FROM Uber

Use Uber


/*  
Objective:
----------
Analyze how trips are distributed between single-passenger and multi-passenger rides each year.

Details:
1. Step 1 (CTE - CTE_Passenger_count):
   - Extract Year, Month, and Hour.
   - Classify rides into:
        * single-passenger → Passenger_count = 1
        * multi-passenger  → Passenger_count >= 2
        * Invalid          → Unexpected/null values
   - Keep Distance_Km column for possible future analysis (e.g., avg distance by ride type).

2. Step 2 (Final SELECT):
   - For each Year & Passenger_Ridetype:
        * Trip_Count → total number of trips
        * Pct_Trips  → % share of that ride type within the year
          Formula: (Trips of ride type ÷ Total trips for year) × 100

Use Case:
---------
- Identify the dominance of single vs multi-passenger rides.
- Observe changes in travel behavior year-over-year.
- Useful for strategy: carpooling services, promotions, or fleet allocation.
*/

								WITH CTE_Passenger_count AS (
									SELECT 
										[Key],
										DATEPART(YEAR, [DATE]) AS [Year],
										DATEPART(MONTH, [DATE]) AS [Monthly],
										DATEPART(HOUR, [TIME]) AS Hour_Of_Day,
										Passenger_count,
										CASE
											WHEN Passenger_count = 1 THEN 'single-passenger'
											WHEN Passenger_count >= 2 THEN 'multi-passenger'
											ELSE 'Invalid'
										END AS Passenger_Ridetype,
										Distance_Km
									FROM Uber
									WHERE Anomaly = 0
								)
								SELECT
									[Year],
									Passenger_Ridetype,
									COUNT([Key]) AS Trip_Count,
									CAST(
										COUNT([Key]) * 100.0 /
										SUM(COUNT([Key])) OVER (PARTITION BY [Year]) 
										AS DECIMAL(5,2)
									) AS Pct_Trips
								FROM CTE_Passenger_count
								GROUP BY [Year], Passenger_Ridetype
								ORDER BY [Year], Passenger_Ridetype;




====================================================================================================================================================
	====================================================================================================================================================
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
												Task 4: Hourly & Weekly Demand Pattern Shift


🎯 Task 4 Goal
Identify peak hours and weekly patterns, and see how they shifted year-over-year.

You can answer questions like:

When do people use Uber the most?

Do peak hours differ between weekdays vs weekends?

Are late-night trips increasing over the years?

&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
====================================================================================================================================================	

								WITH CTE_Week_Summary AS (
								--CREATE VIEW WeekendvsWeekday AS
									SELECT
		
										DATEPART(Year, [DATE]) AS [Year],
										DATEPART(Month, [DATE]) AS [Monthly],
										[DATE],
										DATENAME(WEEKDAY, [DATE]) AS [Days_NAME],
										CASE 
												WHEN DATENAME(WEEKDAY, [DATE]) IN ('Saturday','Sunday') THEN 'Weekend' 
												ELSE 'Weekday' END AS Day_Type,
										COUNT([Key]) AS Trip_count,
										SUM(Distance_Km) AS Total_Distance,
										SUM(fare_amount) AS Total_Revenue
									FROM Uber
									WHERE Anomaly = 0
									GROUP BY
										DATEPART(Year, [DATE]),
										DATEPART(Month, [DATE]),
										[DATE]
       
									--Order by DATEPART(Year, [DATE]),
									--		DATEPART(Month, [DATE]),
									--		DATEPART(WEEKDAY, [DATE])         */
								)
								SELECT 
										[YEAR],
										DAY_Type,
										Sum(Total_Distance) AS Total_Distance,
										Sum(Trip_Count) AS Trip_Count, -- we sum Here because we already did Count in Sub-query And i dont want to add this column in GROUP BY(Work around)
										Sum(Total_Revenue) AS Total_Revenue --i dont want to add this column in GROUP BY(Work around)
								FROM CTE_Week_Summary
								GROUP BY [Year],DAY_Type
								Order BY [Year]


	====================================================================================================================================================
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
												Task 5: Popular Route Stability Over Time


🎯 Task 5 Goal
Identify the most frequently traveled routes and see if they are stable across years.

This can reveal:

Which areas generate consistent demand

Whether new “hot routes” emerge over time

Potential for route-based optimization



&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
====================================================================================================================================================	


/*  
Objective:
----------
Identify the top 10 most frequently traveled routes for each year.

Details:
1. Step 1 (CTE - Route_Summary):
   - Create a Route_ID by rounding Pickup & Dropoff coordinates to 2 decimal places 
     (clusters nearby trips as the same route).
   - Aggregate for each Year + Route_ID:
        * Trip_Count     → total trips
        * Total_Distance → sum of Distance_Km
        * Total_Revenue  → sum of fare_amount

2. Step 2 (Ranking):
   - Use ROW_NUMBER() to rank routes within each year by Trip_Count (descending).
   - Select only top 10 routes per year.

Use Case:
---------
- Understand high-demand travel corridors.
- Useful for pricing strategies, surge planning, and fleet allocation.
- Can highlight changing popular routes across years.
*/

									--CREATE VIEW vw_top_routes_per_year AS
									WITH Route_Summary AS (
										SELECT
											DATEPART(YEAR, [DATE]) AS [Year],
											-- Create Route Identifier by rounding coordinates to 2 decimals
											CONCAT(
												ROUND(Pickup_latitude, 2), ',', ROUND(Pickup_longitude, 2),
												' -> ',
												ROUND(Dropoff_latitude, 2), ',', ROUND(Dropoff_longitude, 2)
											) AS Route_ID,
											COUNT([Key]) AS Trip_Count,
											SUM(Distance_Km) AS Total_Distance,
											SUM(fare_amount) AS Total_Revenue
										FROM Uber
										WHERE Anomaly = 0
										GROUP BY
											DATEPART(YEAR, [DATE]),
											ROUND(Pickup_latitude, 2),
											ROUND(Pickup_longitude, 2),
											ROUND(Dropoff_latitude, 2),
											ROUND(Dropoff_longitude, 2)
									)
									-- Rank routes by Trip_Count per Year
									SELECT *
									FROM (
										SELECT 
											*,
											ROW_NUMBER() OVER(PARTITION BY [Year] ORDER BY Trip_Count DESC) AS Route_Rank
										FROM Route_Summary
									) Ranked
									WHERE Route_Rank <= 10
									ORDER BY [Year], Route_Rank;




====================================================================================================================================================

								-- Avg Revenue Per Hr 
====================================================================================================================================================

/*  
Objective:
----------
Calculate the Average Revenue Per Day from Uber trip data.

Steps:
1. Use a Common Table Expression (CTE) to group trip data by each date.
2. For each day, sum up the Fare_Amount to get the daily total revenue.
3. Finally, calculate the average of these daily totals to find the Average Revenue Per Day.

Use Case:
---------
This query helps analyze average earning trends per day and can be extended 
to monthly or yearly averages by modifying the grouping.
*/

									WITH Avg_Revenue_Per_day AS (
										SELECT 
											[DATE],
											SUM(Fare_Amount) AS Fare_Amount
										FROM Uber
										WHERE Anomaly = 0
										GROUP BY [DATE]
									)
									SELECT 
										AVG(Fare_Amount) AS Avg_Revenue_Per_day
									FROM Avg_Revenue_Per_day;


====================================================================================================================================================

SELECT * FROM Uber

====================================================================================================================================================


/*  
Objective:
----------
Summarize Uber trip data by each date and hour to analyze trip counts, 
total fare amount, and day-wise distribution.

Steps:
1. Group the data by Date and Hour.
2. Calculate:
   - Trip_Count: Total number of trips in that hour.
   - Fare_Amount: Total revenue for that hour.
   - Day_Name: Day of the week for analysis.

Use Case:
---------
This query can be used for hourly trip demand analysis or 
to find peak revenue hours and weekday vs weekend patterns.
*/

									WITH Avg_Summer AS (
										SELECT
											COUNT([Key]) AS Trip_Count,
											[DATE],
											SUM(Fare_amount) AS Fare_Amount,
											DATEPART(HOUR, [TIME]) AS [Hour],
											DATENAME(WEEKDAY, [DATE]) AS Day_Name
										FROM Uber 
										WHERE Anomaly = 0
										GROUP BY [DATE], DATEPART(HOUR, [TIME])
									)
									SELECT *
									FROM Avg_Summer;
									--ORDER BY [DATE],
												--DATEPART(Hour, [TIME])





====================================================================================================================================================

									--           AFTER CREATEING View_Table [Analysis]

====================================================================================================================================================

SELECT * FROM vw_trip_summary_yearly;

SELECT * FROM vw_Ride_Duration;

SELECT * FROM vw_Distance_Category;

SELECT * FROM vw_Passenger_count;

SELECT * FROM vw_top_routes_per_year;

====================================================================================================================================================



====================================================================================================================================================
/* 
   Objective:
   ----------
   Calculate the percentage distribution of trips across different distance categories 
   (Very_Short, Long, Very_Long) for each day type (Weekdays, Weekend). 

   Dataset:
   --------
   1) vw_Ride_Duration      -> Contains ride-level information with 'day_type' (Weekdays/Weekend)
   2) vw_Distance_Category  -> Contains distance categories mapped to each trip (Very_Short, Long, etc.)

   Join Condition:
   ---------------
   Both tables share the same 'Key' column that links each ride to its distance category.
   
   Logic:
   ------
   1) COUNT(d.[Key])         -> Counts trips per (day_type, distance_category) group.
   2) SUM(COUNT(...)) OVER   -> Calculates total trips per day_type as a window function.
   3) COUNT * 100 / SUM(...) -> Converts trip counts into percentages for each group.
   
   Steps:
   ------
   - Join both tables on the common 'Key'
   - Group by day_type and distance_category
   - Calculate percentage distribution for each combination
*/

								SELECT 
									d.day_type,                     -- Weekdays or Weekend
									dist.distance_category,         -- Distance category: Very_Short, Long, Very_Long
									COUNT(d.[Key]) * 100.0 / 
										SUM(COUNT(d.[Key])) OVER (PARTITION BY d.day_type) AS Percentage
										-- Percentage formula: (trips in category / total trips for that day_type) * 100
								FROM vw_Ride_Duration d
								WHERE Pasen.Anomaly = 0
								JOIN vw_Distance_Category dist
									ON d.[Key] = dist.[Key]
								JOIN vw_Passenger_count	Pasen
									ON d.[Key] = Pasen.[Key]
								GROUP BY 
									d.day_type, 
									dist.distance_category
								ORDER BY 
									d.day_type, 
									Percentage DESC;                -- Sort by day_type and highest percentage first

====================================================================================================================================================

-- ===============================================
-- Find Top Routes by Revenue (excluding outlier)
-- ===============================================
-- Explanation:
-- The first route in our dataset has coordinates "0.0 → 0.0",
-- which is clearly an invalid outlier. Since it always comes up
-- as the top row in results (due to large trip aggregation),
-- we use OFFSET to skip it.
--
-- OFFSET n ROWS => Skips 'n' rows
-- FETCH NEXT m ROWS ONLY => Returns 'm' rows after skipping
--
-- In this query:
--   OFFSET 1 ROW -> skip the first row (outlier route)
--   FETCH NEXT 10 ROWS ONLY -> get the next top 10 valid routes
-- ===============================================

										WITH Top_Route AS (
											SELECT 
												R.Route_Id,
												COUNT(R.[KEY]) AS Total_Trip,
												SUM(R.Fare_amount) AS Revenue
											FROM vw_top_routes_per_year R
											JOIN vw_Passenger_count	Pasen
											ON R.[Key] = Pasen.[Key]
											WHERE Pasen.Anomaly = 0 
											GROUP BY Route_ID
										)
										SELECT 
											Route_Id,
											Total_Trip,
											Revenue
										FROM Top_Route
										ORDER BY Revenue DESC
										OFFSET 1 ROW        -- Skip the first row (the 0.0 -> 0.0 outlier route)
										FETCH NEXT 10 ROWS ONLY; -- Fetch the next 10 highest-revenue routes

====================================================================================================================================================
USE UBER

SELECT * FROM vw_trip_summary_yearly



SELECT 
	[KEY],
	CONCAT(
			ROUND(Pickup_latitude, 4), ',', ROUND(Pickup_longitude, 4)
					) AS Pickup,
	CONCAT(
			ROUND(Dropoff_latitude, 4), ',', ROUND(Dropoff_longitude, 4)
			) AS Dropoff,
	Distance_km,
	Fare_amount
FROM UBER
WHERE Distance_km < 5
	AND Anomaly = 0


SELECT 
	[KEY],
	CONCAT(
			ROUND(Pickup_latitude, 4), ',', ROUND(Pickup_longitude, 4)
					) AS Pickup,
	CONCAT(
			ROUND(Dropoff_latitude, 4), ',', ROUND(Dropoff_longitude, 4)
			) AS Dropoff,
	Distance_km,
	Fare_amount
FROM UBER
WHERE Distance_km BETWEEN 5 AND 10
	AND Anomaly = 0



