-- ==================================================================================

										🚖 Uber Trip Data Analysis Using SQL Server
											

								-- 📌 Description: [Phase 5: Data Analyze, Create Viewpoint for PowerBi ']
								-- ==================================================================================
		
	


/*
================================================================================
  File Name   : Trip_Imbalance_View.sql
  Author      : Santhosh
  Description : This view identifies directional imbalances in Uber trip flows 
                between pickup and dropoff zones, helping spot areas with more 
                departures than arrivals and vice versa.
  Created On  : [Enter Date]
  Dataset     : Uber Fares Dataset from Kaggle
               https://www.kaggle.com/datasets/yasserh/uber-fares-dataset
================================================================================
*/ use uber

====================================================================================================================================================
====================================================================================================================================================
1]

/*  
Objective:
----------
Create a view that summarizes Uber trip data on a yearly basis.

Details:
1. Group data by Year.
2. Calculate:
   - Total_Revenue: Total earnings in a year.
   - Avg_Revenue: Average revenue per trip.
   - Total_Distance: Total kilometers traveled.
   - Avg_Distance: Average trip distance.
   - Trip_Count: Total number of trips.
   - Revenue_per_KM: Revenue generated per kilometer.
   - Revenue_per_Trip: Revenue generated per trip.

Use Case:
---------
This view will be helpful for yearly performance analysis, 
revenue trend monitoring, and average distance/revenue comparison.
*/

									CREATE VIEW vw_trip_summary_yearly AS
									SELECT 
										DATEPART(YEAR, [DATE]) AS [Year],
										SUM(fare_amount) AS Total_Revenue,
										AVG(fare_amount) AS Avg_Revenue,
										SUM(Distance_Km) AS Total_Distance,
										AVG(Distance_Km) AS Avg_Distance,
										COUNT([Key]) AS Trip_Count,
										SUM(fare_amount) / NULLIF(SUM(Distance_Km), 0) AS Revenue_per_KM,
										SUM(fare_amount) / COUNT([Key]) AS Revenue_per_Trip
									FROM Uber
									GROUP BY DATEPART(YEAR, [DATE])
									ORDER BY DATEPART(YEAR, [DATE]);

-- Note: 2015 has only 6 months of data available in this dataset.


--------------------------------------------------------------------------------------------------------------------
/*
		Question - 1

if i take a avg of a distance from the main table from column (distance) it comes to 20.48 
something but i did a summary table by year where i also did avg by year so when i took the avg of that cloumn its 21,93 
why is it not matching? give me a short note so tha i can copy and paste please

The overall average distance from the main table (20.5) and the average of yearly averages (21.93) don’t match because of weighting. 
The overall average considers every trip equally, while the average of yearly averages gives each year equal weight, regardless of how many trips occurred that year. 
This difference makes the values diverge unless each year has the same number of trips. To get an accurate overall average from a summary table, use a weighted mean based on trip counts.

*/

/*
			QUESTION -2

how to calculate mean for main table ?

To calculate the mean (average) for the main table in SQL Server, you just use the AVG() aggregate function directly on the column.

For your Uber table, it would look like this:

-----------------------------

							SELECT 
								AVG(Distance) AS OverallMeanDistance
							FROM Uber;
-----------------------------

What happens here:

						AVG(Distance) = (Sum of all trip distances) ÷ (Number of trips).

Every row (trip) contributes equally.

This gives the true overall mean for the entire dataset.


*/

/*

✅ Correct way (weighted mean from summary table)

Since your summary already has Trip_count, you can calculate the true overall mean as a weighted average:

-----------------------------

				SELECT SUM(Avg_Distance * Trip_count) / SUM(Trip_count) AS Overall_Mean_Distance
				FROM vw_trip_summary_yearly;

-----------------------------

*/

---------------------------------------------------------------------------------------

====================================================================================================================================================
====================================================================================================================================================


2]

/*  
Objective:
----------
Create a view to store ride-level information with derived time-based fields 
like Year, Month, Day type (Weekend/Weekday), and Hour of the Day.

Details:
1. Extracts:
   - Year, Month, and Month_Name from the trip date.
   - Day_Name from the trip date to classify weekends vs weekdays.
   - Hour_Of_Day from the trip time for hourly analysis.
2. Adds a Day_Type column to categorize trips as 'Weekend' or 'Weekday'.

Use Case:
---------
This view can be used for:
- Time-based analysis (Yearly, Monthly, Hourly trends)
- Weekend vs Weekday demand comparison
- Data preparation for revenue or trip demand dashboards
*/

								CREATE VIEW vw_Ride_Duration AS
								SELECT
									[Key],
									[DATE],
									DATEPART(YEAR, [DATE]) AS [Year],
									DATEPART(MONTH, [DATE]) AS [Monthly],
									DATENAME(MONTH, [DATE]) AS [Month_Name],
									DATENAME(WEEKDAY, [DATE]) AS [Days_Name],
									CASE 
										WHEN DATENAME(WEEKDAY, [DATE]) IN ('Saturday', 'Sunday') THEN 'Weekend' 
										ELSE 'Weekday' 
									END AS Day_Type,
									DATEPART(HOUR, [TIME]) AS [Hour_Of_Day]
								FROM Uber;


USE Uber


--------------------------------------------------------------------------------------------------------------------

====================================================================================================================================================
====================================================================================================================================================


3]


/*  
Objective:
----------
Create a view that classifies each Uber trip into a distance category 
based on the total distance traveled.

Details:
1. Extracts:
   - Year: For time-based trend analysis.
   - Distance_Km: Actual trip distance.
   - Distance_Category: Categorized into:
        * Very_Short → Distance < 5 km
        * Short      → 5–10 km
        * Long       → 10–20 km
        * Very_Long  → > 20-30km
        * Outer-city  → > 30 km
        * Invalid    → For null/unexpected values
   - fare_amount: For revenue analysis against distance.

Use Case:
---------
This view is useful for:
- Analyzing revenue per distance category
- Comparing trip counts across distance segments
- Building distance vs fare dashboards
*/

										--CREATE VIEW vw_Distance_Category AS
										ALTER VIEW vw_Distance_Category AS 
										SELECT 
											[Key],
											DATEPART(YEAR, [DATE]) AS [Year],
											Distance_Km,
											CASE
											WHEN Distance_Km < 5 THEN 'Very_Short'
											WHEN Distance_Km BETWEEN 5 AND 10 THEN 'Short'
											WHEN Distance_Km BETWEEN 10 AND 20 THEN 'Long'
											WHEN Distance_Km BETWEEN 20 AND 30 THEN 'Very_Long'
											WHEN Distance_Km > 30 THEN 'Outer-city'
												ELSE 'Invalid'
											END AS Distance_Category,
											fare_amount
										FROM Uber;
										

--------------------------------------------------------------------------------------------------------------------

====================================================================================================================================================
====================================================================================================================================================


4]

/*  
Objective:
----------
Create a view to categorize Uber trips based on the number of passengers.

Details:
1. Extracts:
   - Year: For time-based passenger trend analysis.
   - Passenger_count: Actual passenger count for each trip.
   - Passenger_Ridetype:
        * single-passenger → Passenger_count = 1
        * multi-passenger  → Passenger_count ≥ 2
        * Invalid          → For null or unexpected values

Use Case:
---------
This view helps in:
- Understanding trip patterns based on passenger types
- Comparing single vs multi-passenger trip demand
- Revenue analysis based on ride type
*/

								CREATE VIEW vw_Passenger_count AS
								SELECT 
									[Key],
									DATEPART(YEAR, [DATE]) AS [Year],
									Passenger_count,
									CASE
										WHEN Passenger_count = 1 THEN 'single-passenger'
										WHEN Passenger_count >= 2 THEN 'multi-passenger'
										ELSE 'Invalid'
									END AS Passenger_Ridetype
								FROM Uber;


--------------------------------------------------------------------------------------------------------------------

SELECT 
    CASE 
        WHEN Distance_Category IN ('Very_Short', 'Short') THEN 'Short'
        WHEN Distance_Category IN ('Long', 'Very_Long') THEN 'Long'
    END AS Distance_Group,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS Distance_Percentage
FROM vw_Distance_Category
GROUP BY 
    CASE 
        WHEN Distance_Category IN ('Very_Short', 'Short') THEN 'Short'
        WHEN Distance_Category IN ('Long', 'Very_Long') THEN 'Long'
    END;

--------------------------------------------------------------------------------------------------------------------

====================================================================================================================================================
====================================================================================================================================================


5]

/*  
Objective:
----------
Create a view to identify top routes per year based on pickup and dropoff coordinates.

Details:
1. Extracts:
   - Year: For time-based route analysis.
   - Route_ID: Created by concatenating rounded pickup & dropoff coordinates 
     (rounded to 2 decimals to group nearby locations into the same route).
   - Distance_Km & fare_amount: For analyzing revenue and distance per route.

2. Grouping ensures:
   - Unique routes are identified per year.
   - Each route is represented by a simplified Route_ID.

Use Case:
---------
This view helps in:
- Identifying popular routes by frequency or revenue.
- Comparing average distance and fare across routes per year.
*/

/*
Perplexity Ai : Is there minium Decimal digit for longitude and latitude?

Answer :
There is no global minimum number of digits for longitude and latitude, but the number of decimal places determines location accuracy. 
For usable geographic coordinates, at least two decimal places are common, giving accuracy within a kilometer, and four decimal places allow accuracy within an individual street or building.

Decimal Places and Accuracy
					0 decimal places: Country or large region (~111 km).

					2 decimal places: City or village (~1.1 km).

					4 decimal places: Street or building (~11 m).

					6 decimal places: Survey accuracy (~0.11 m).


*/

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


								CREATE VIEW vw_top_routes_per_year AS
								SELECT
									[Key],
									[DATE],
									DATEPART(YEAR, [DATE]) AS [Year],
									CONCAT(
										ROUND(Pickup_latitude, 4), ',', ROUND(Pickup_longitude, 4),
										' -> ',
										ROUND(Dropoff_latitude, 4), ',', ROUND(Dropoff_longitude, 4)
									) AS Route_ID,
									Distance_Km,
									fare_amount
								FROM Uber
								GROUP BY
									DATEPART(YEAR, [DATE]),
									ROUND(Pickup_latitude, 4),
									ROUND(Pickup_longitude, 4),
									ROUND(Dropoff_latitude, 4),
									ROUND(Dropoff_longitude, 4),
									[Key],
									[DATE],
									Distance_Km,
									fare_amount;

--------------------------------------------------------------------------------------------------------------------
/*
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-To Many Distinct Route_ID Better To Make it AS Zone Round it of to 2 Decimal
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Note - To alter a column expression like Route_ID in your view so it rounds to 2 decimal places (instead of 4) in SQL Server, you must provide the entire view definition in your ALTER VIEW statement. You cannot alter just one column or just part of the definition.
*/
--------------------------------------------------------------------------------------------------------------------

ALTER VIEW vw_top_routes_per_year AS
								SELECT
									[Key],
									[DATE],
									DATEPART(YEAR, [DATE]) AS [Year],
									-- Create Route Identifier by rounding coordinates to 2 decimals
									CONCAT(
										ROUND(Pickup_latitude, 2), ',', ROUND(Pickup_longitude, 2),
										' -> ',
										ROUND(Dropoff_latitude, 2), ',', ROUND(Dropoff_longitude, 2)
									) AS Route_ID,
									Distance_Km,
									fare_amount
								FROM Uber
								GROUP BY
									DATEPART(YEAR, [DATE]),
									ROUND(Pickup_latitude, 2),
									ROUND(Pickup_longitude, 2),
									ROUND(Dropoff_latitude, 2),
									ROUND(Dropoff_longitude, 2),
									[Key],
									[DATE],
									Distance_Km,
									fare_amount;

--------------------------------------------------------------------------------------------------------------------


====================================================================================================================================================	

USE UBER


