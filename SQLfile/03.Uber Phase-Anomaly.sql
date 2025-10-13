-- ==================================================================================

										🚖 Uber Trip Data Analysis Using SQL Server
											
												 🧑‍💻 Author: Santhosh

													 📅 Year: 2025

								-- 📌 Description: ['Phase 4: Anomaly Detection Module ']
								-- ==================================================================================

----------------------------------------------------------------------------------------------------------------------------------------------------------
--==========================================================================================================================================================


--==========================================================================================================================================================
-------------------------------------
📌 Project Overview
-----------------------------------

This project focuses on analyzing Uber trip data using SQL Server to uncover key insights that can drive business decisions and operational improvements. The dataset contains trip-level records including timestamps, fare amounts, passenger counts, and pickup/dropoff coordinates.

The main objectives of this project are:

📊 Understand trip volume trends across days, weekends, and hours to identify peak demand periods.

🌐 Analyze trip patterns between pickup and dropoff zones to uncover directional imbalances in passenger movement.

👥 Assess passenger loads on different routes to identify high-volume zones.

🗓️ Detect weekday vs. weekend behavior to help plan resource allocation.

📌 Prepare clean, SQL-based insights to be visualized further using Power BI.

All analyses were performed using temporary tables and subqueries, without altering the original dataset. The final queries are structured and annotated to allow easy transition into dashboards or reporting tools.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--==========================================================================================================================================================



/*
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 14: Creating Anomaly Column
--==========================================================================================================================================================


🎯 Goal	 : To Add a Anomaly Column to Table
===============================================
*/

ALTER TABLE Uber 
ADD Anomaly INT;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------





/*
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 15: Creating Anomaly Detection Module					
--==========================================================================================================================================================


📌 Phase 1 : Anomaly Detection Module - Uber Dataset
🎯 Goal	 : Identify and isolate trips with invalid or suspicious data patterns
===============================================


✅ Conditions Tagged:
1 → Passenger count less than 1
2 → Passenger count more than 7
3 → Fare amount less than or equal to 0
4 → Distance less than or equal to 0
0 → Valid trip (no anomaly detected)



🧩 Strategy:
- Add an 'Anomaly' column to the Uber table
- Assign each record a tag based on priority of detected issue
*/

-- Step 1: Add the anomaly indicator column (if it doesn't exist)
ALTER TABLE Uber ADD Anomaly INT;

-- Step 2: Tag anomalies with codes
UPDATE Uber
SET Anomaly = 
    CASE	
        WHEN passenger_count < 1 THEN 1
        WHEN passenger_count > 7 THEN 2
        WHEN fare_amount <= 0 THEN 3
        WHEN Distance_km <= 0 THEN 4 
        ELSE 0  -- No anomaly
    END;
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--==========================================================================================================================================================

/*

📌 Phase 2 : Anomaly Detection Module - Uber Dataset
🎯 Goal	 : Identify and isolate trips with invalid or suspicious data patterns
===============================================

✅ Conditions Tagged:
			5 → Distance_km > 65
			
----------------------------------------------

WHY NOT CONSIDER DISTANCE GREATHER THAN 100 AS INTERCITY/OUTERCITY TRIP?
-- 
	Through Analysis the Fare_ amount and distance Travel didnt Match or any of Trip which Distance_km > 65
	
*/



UPDATE Uber
SET Anomaly = 5
WHERE Distance_km > 65



----------------------------------------------
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
WHERE Distance_km > 65
	-- AND Anomaly = 0

----------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--==========================================================================================================================================================

/*

📌 Phase 3 : Anomaly Detection Module - Uber Dataset
🎯 Goal	 : Identify and isolate trips with invalid or suspicious data patterns
===============================================

✅ Conditions Tagged:
			5 → Distance_km > 100


----------------------------------------------

Because we dont know the specific city 

-- it’s best to use broad but still reasonable global latitude and longitude ranges to detect obvious anomalies like zeros or impossible coordinates.

General Valid Latitude and Longitude Ranges
Latitude: valid values range from -90 to +90 degrees.

Longitude: valid values range from -180 to +180 degrees.

Coordinates outside these ranges are invalid and should be flagged as anomalies.

*/

--Distance anomaly can be Replaced with This

UPDATE Uber
SET Anomaly = 6
WHERE 
    Pickup_latitude NOT BETWEEN -90 AND 90
    OR Pickup_longitude NOT BETWEEN -180 AND 180
    OR Dropoff_latitude NOT BETWEEN -90 AND 90
    OR Dropoff_longitude NOT BETWEEN -180 AND 180
    OR Pickup_latitude = 0.0
    OR Pickup_longitude = 0.0
    OR Dropoff_latitude = 0.0
    OR Dropoff_longitude = 0.0;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  









/*
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 16: Verying Doubts
--==========================================================================================================================================================


📌 Phase 1 : 
🎯 Goal	 : Verifing the Distance_Km and Finding Sutiable Decimal Round-Off Number
===============================================

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

WITH Route_anomaly_verfiy AS ( 
				SELECT 
					CONCAT(
							ROUND(Pickup_latitude, 4), ',', ROUND(Pickup_longitude, 4)
						) AS Pickup,
					CONCAT(
							ROUND(Dropoff_latitude, 4), ',', ROUND(Dropoff_longitude, 4)
						) AS DropOff,
					Distance_Km,
					Anomaly,
					Fare_amount
				FROM Uber
)
SELECT * FROM Route_anomaly_verfiy
WHERE PICKUP LIKE DropOff

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

WITH Route_anomaly_verfiy AS ( 
				SELECT 
					CONCAT(
							ROUND(Pickup_latitude, 4), ',', ROUND(Pickup_longitude, 4)
						) AS Pickup,
					CONCAT(
							ROUND(Dropoff_latitude, 4), ',', ROUND(Dropoff_longitude, 4)
						) AS DropOff,
					Distance_Km,
					Anomaly,
					Fare_amount
				FROM Uber
)
SELECT * FROM Route_anomaly_verfiy
WHERE PICKUP NOT LIKE DropOff
		AND Distance_Km < 0


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
