							-- ==================================================================================

										🚖 Uber Trip Data Analysis Using SQL Server
											
												 🧑‍💻 Author: Santhosh

													 📅 Year: 2025

								-- 📌 Description: [Put a brief here like 'Phase 4: Data Analyze ']
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
=======================================================
📌 Phase 1: Zone-to-Zone Trip Matrix – Uber Dataset
🎯 Goal: Analyze valid trips between pickup and dropoff zones
=======================================================

✅ Filters:
- Only records with valid (non-null) pickup and dropoff zones
- Excludes all anomalies (Anomaly = 0)

📊 Output:
- Pickup zone
- Dropoff zone
- Total number of valid trips between the zones
*/

SELECT 
    pickup_zone, 
    dropoff_zone, 
    COUNT([key]) AS total_trips
FROM Uber
WHERE 
    pickup_zone IS NOT NULL AND 
    dropoff_zone IS NOT NULL AND
    Anomaly = 0
GROUP BY 
    pickup_zone, 
    dropoff_zone
ORDER BY 
    total_trips DESC;


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--==========================================================================================================================================================
--==========================================================================================================================================================

												&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
														Zone-to-Zone Trip Analysis 
												&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&


/*
======================================================================
📌 Phase 2.1: Zone-to-Zone Trip Imbalance Analysis – Uber Dataset
🎯 Goal: Compare trip counts between zone pairs (A → B vs B → A)
======================================================================

✅ Query Details:
- Filters out anomalous trips (Anomaly = 0)
- Aggregates trip counts between pickup and drop-off zones
- Joins on reversed pairs to compare A→B and B→A volumes
- Calculates absolute difference (imbalance) between the two

🧾 Output Columns:
- Zone_A: Pickup zone
- Zone_B: Dropoff zone
- Trips_A_to_B: Count of trips from A to B
- Trips_B_to_A: Count of trips from B to A
- Imbalance: |A→B - B→A|

⚠️ Note:
The **imbalance analysis is optional and statistically insignificant** in this dataset.  
This is because the **highest trip volumes occur within the same zones** (e.g., NW → NW, NE → NE),  
which inherently have no directional imbalance. Therefore, interpreting A-B vs B-A mismatches  
may not offer meaningful insights for majority of the traffic patterns in this case.
*/

-- Step 1: Create CTE for total trip per pickup → drop-off zone
WITH ZoneFlow AS (
    SELECT pickup_zone, dropoff_zone, COUNT(*) AS TripCount
    FROM Uber
    WHERE Anomaly = 0
    GROUP BY pickup_zone, dropoff_zone
)
-- Step 2: Join reversed zone-pairs to measure directional imbalance
SELECT 
    A.pickup_zone AS Zone_A,
    A.dropoff_zone AS Zone_B,
    A.TripCount AS Trips_A_to_B,
    B.TripCount AS Trips_B_to_A,
    ABS(A.TripCount - B.TripCount) AS Imbalance
FROM ZoneFlow A
JOIN ZoneFlow B 
    ON A.pickup_zone = B.dropoff_zone 
    AND A.dropoff_zone = B.pickup_zone
-- WHERE A.pickup_zone < A.dropoff_zone  -- Optional: prevents self-pair and duplicate rows
ORDER BY Imbalance DESC;

--==========================================================================================================================================================
--==========================================================================================================================================================


/*
======================================================================
📌 Phase 2.2: Zone-to-Zone **Passenger Flow Imbalance** – Uber Dataset
🎯 Goal: Compare total passengers between zone pairs (A → B vs B → A)
======================================================================

✅ Query Details:
- Filters out anomalous trips (Anomaly = 0)
- Aggregates **passenger counts** between pickup and drop-off zones
- Joins on reversed pairs to compare A→B and B→A flow
- Calculates absolute difference (imbalance) in passenger volume

🧾 Output Columns:
- Zone_A: Pickup zone
- Zone_B: Dropoff zone
- Passengers_A_to_B: Total passengers from A to B
- Passengers_B_to_A: Total passengers from B to A
- Imbalance: |A→B - B→A|

⚠️ Note:
The **passenger imbalance analysis is optional and statistically insignificant**  
within this dataset. This is because the **largest passenger volumes occur within  
the same zones** (e.g., NW → NW, NE → NE), which naturally show zero directional  
imbalance. Thus, relying on imbalance values may not yield strong operational insights  
for the most dominant flows.
======================================================================
*/

-- Step 1: Create CTE for total passengers per pickup → drop-off zone
WITH tripPassenger AS (
    SELECT 
        pickup_zone, 
        dropoff_zone, 
        SUM(passenger_count) AS TotalPassenger 
    FROM Uber
    WHERE Anomaly = 0
    GROUP BY pickup_zone, dropoff_zone
)

-- Step 2: Join reversed zone-pairs to measure directional imbalance
SELECT 
    A.pickup_zone AS Zone_A, 
    A.dropoff_zone AS Zone_B, 
    A.TotalPassenger AS Passengers_A_to_B,
    B.TotalPassenger AS Passengers_B_to_A,
    ABS(A.TotalPassenger - B.TotalPassenger) AS Imbalance
FROM tripPassenger A
JOIN tripPassenger B
    ON A.pickup_zone = B.dropoff_zone 
    AND A.dropoff_zone = B.pickup_zone

-- Optional: remove self-zones or duplicate directions
-- WHERE A.pickup_zone < A.dropoff_zone  

ORDER BY Imbalance DESC;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


												&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
														trip_distribution Analysis 
												&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
=============================================================================
📌 Phase 3.1: Trip Volume by Hour – Uber Dataset  
🎯 Goal: Identify which hours of the day see the highest trip activity  
=============================================================================

✅ Query Details:
- Filters out anomalous trips (Anomaly = 0)
- Extracts **hour component** from the `time` column using `DATEPART(HOUR, time)`
- Aggregates total trip count by hour of the day (0 to 23)

🧾 Output Columns:
- TIME: Hour of day (0–23)
- Totaltrip: Number of valid trips that started in that hour

=======================================================================
*/

SELECT DISTINCT 
    DATEPART(HOUR, time) AS [TIME],
    COUNT([KEY]) AS Totaltrip  
FROM Uber
WHERE Anomaly = 0
GROUP BY DATEPART(HOUR, time)
ORDER BY DATEPART(HOUR, time) ASC;

--==========================================================================================================================================================


/*
=============================================================================
📌 Phase 3.2: Hourly Trip Volume by Pickup Zone  
🎯 Goal: Analyze trip distribution by hour, broken down by pickup zone  
=============================================================================

✅ Query Details:
- Filters out anomalous trips (Anomaly = 0)
- Groups data by both hour of day and pickup zone
- Helps identify which pickup zones are busiest at different times

🧾 Output Columns:
- TIME: Hour of day (0–23)
- pickup_zone: Zone where the trip began
- Totaltrip: Number of valid trips from that zone during that hour

=======================================================================
*/

SELECT DISTINCT 
    DATEPART(HOUR, time) AS [TIME],
    COUNT([KEY]) AS Totaltrip,
    pickup_zone
FROM Uber
WHERE Anomaly = 0
GROUP BY DATEPART(HOUR, time), pickup_zone
ORDER BY DATEPART(HOUR, time) ASC;

--==========================================================================================================================================================


/*
=============================================================================
📌 Phase 3.3: Hourly Trip Volume by Drop-off Zone  
🎯 Goal: Analyze trip distribution by hour, broken down by drop-off zone  
=============================================================================

✅ Query Details:
- Filters out anomalous trips (Anomaly = 0)
- Groups data by both hour of day and drop-off zone
- Helps identify which zones receive the most passengers at various hours

🧾 Output Columns:
- TIME: Hour of day (0–23)
- dropoff_zone: Zone where the trip ended
- Totaltrip: Number of valid trips ending at that zone during that hour

=======================================================================
*/

SELECT DISTINCT 
    DATEPART(HOUR, time) AS [TIME],
    COUNT([KEY]) AS Totaltrip,
    dropoff_zone
FROM Uber
WHERE Anomaly = 0
GROUP BY DATEPART(HOUR, time), dropoff_zone
ORDER BY DATEPART(HOUR, time) ASC;


--==========================================================================================================================================================

/*
=============================================================================
📌 Phase 3.4: Hourly Peak Zone Identification  
🎯 Goal: Identify the most frequent pickup and dropoff zones for each hour  
=============================================================================

✅ Query Details:
- Filters out anomalous trips (`Anomaly = 0`)
- Groups trips by hour (`DATEPART(HOUR, time)`) and zone (pickup or dropoff)
- Uses `ROW_NUMBER()` to rank zones based on trip volume for each hour
- Retrieves only the top zone per hour

🧾 Output Columns:
- Hr: Hour of day (0–23)
- pickup_zone / dropoff_zone: Most frequent zone for that hour
- Totaltrip: Number of valid trips from/to that zone in that hour

⚠️ Note:
This analysis helps identify **hourly traffic concentration** by zone, which is valuable for:
- Resource allocation and dispatch planning  
- Understanding commuter behavior and travel hotspots  
- Designing hourly pricing or promotion strategies
*/
-----------------------------------------------------------------------------

-- 🔹 3.4.1: Top Dropoff Zone by Hour
WITH RankedTrips AS (
    SELECT 
        DATEPART(HOUR, time) AS Hr,
        dropoff_zone,
        COUNT([KEY]) AS Totaltrip,
        ROW_NUMBER() OVER(PARTITION BY DATEPART(HOUR, time) ORDER BY COUNT([KEY]) DESC) AS rk
    FROM Uber
    WHERE Anomaly = 0
    GROUP BY DATEPART(HOUR, time), dropoff_zone
)
SELECT Hr, dropoff_zone, Totaltrip
FROM RankedTrips
WHERE rk = 1;

--==========================================================================================================================================================


/* 🔹 3.4.2 - Highest Pickup Zone per Hour
---------------------------------------------------------------
- Groups all trips by HOUR and pickup_zone
- Uses ROW_NUMBER() to rank pickup zones by volume within each hour
- Filters to only the top zone per hour
*/


-- 🔹 3.4.2: Top Pickup Zone by Hour
WITH RankedTrips AS (
    SELECT 
        DATEPART(HOUR, time) AS Hr,
        pickup_zone,
        COUNT([KEY]) AS Totaltrip,
        ROW_NUMBER() OVER(PARTITION BY DATEPART(HOUR, time) ORDER BY COUNT([KEY]) DESC) AS rk
    FROM Uber
    WHERE Anomaly = 0
    GROUP BY DATEPART(HOUR, time), pickup_zone
)
SELECT Hr, pickup_zone, Totaltrip
FROM RankedTrips
WHERE rk = 1;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


												&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
											Trip counts vary by weekday for each pickup zone Analysis 
												&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
=============================================================================
📌 Phase 4: Weekly Trip Pattern by Pickup Zone  
🎯 Goal: Analyze day-wise trip distribution for each pickup zone  
=============================================================================

✅ Query Details:
- Filters out anomalous trips (`Anomaly = 0`)
- Groups data by pickup zone and day of the week
- Uses `ROW_NUMBER()` to order weekdays consistently (Monday to Sunday)
- Reveals how trip volumes vary across days within each pickup zone

🧾 Output Columns:
- pickup_zone: Starting location of the trip
- DayOfWeek: Day name (Monday–Sunday)
- TotalTrip: Number of valid trips on that day from that pickup zone
- ROWNUMBER: Sequential rank of weekdays (1 = Monday, ..., 7 = Sunday)

⚠️ Note:
This query is helpful for visualizing **weekly demand cycles**, which can support:
- Staffing and shift planning
- Surge pricing windows
- Zone-specific trend predictions
*/
-----------------------------------------------------------------------------

WITH BaseData AS (
    SELECT 
        pickup_zone,
        DATENAME(WEEKDAY, CAST([DATE] AS DATE)) AS DayOfWeek,
        COUNT([KEY]) AS TotalTrip
    FROM Uber
    WHERE Anomaly = 0
    GROUP BY 
        pickup_zone, 
        DATENAME(WEEKDAY, CAST([DATE] AS DATE))
)
SELECT 
    *,
    ROW_NUMBER() OVER (
        PARTITION BY pickup_zone 
        ORDER BY 
            CASE DayOfWeek
                WHEN 'Monday' THEN 1
                WHEN 'Tuesday' THEN 2
                WHEN 'Wednesday' THEN 3
                WHEN 'Thursday' THEN 4
                WHEN 'Friday' THEN 5
                WHEN 'Saturday' THEN 6
                WHEN 'Sunday' THEN 7
            END
    ) AS ROWNUMBER
FROM BaseData
ORDER BY 
    CASE DayOfWeek
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END;

--==========================================================================================================================================================

/*

====================================================================
📌 Phase 4.2: Weekday vs Weekend Trip Volume by Pickup Zone  
🎯 Goal: Compare trip volume on weekdays vs weekends across pickup zones  
====================================================================

✅ Query Details:
- Filters out anomalous trips (Anomaly = 0)
- Categorizes each day as 'Weekday' or 'Weekend' using DATENAME
- Groups by pickup zone and the derived DayType
- Helps analyze behavioral differences between weekdays and weekends

🧾 Output Columns:
- pickup_zone: Starting location of the trip
- DayType: Either 'Weekday' or 'Weekend'
- TotalTrip: Count of valid trips for the given day type and zone
*/
------------------------------------------------------------

SELECT 
    pickup_zone,
    CASE 
        WHEN DATENAME(WEEKDAY, CAST([DATE] AS DATE)) IN ('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END AS DayType,
    COUNT([KEY]) AS TotalTrip
FROM Uber
WHERE Anomaly = 0
GROUP BY 
    pickup_zone,
    CASE 
        WHEN DATENAME(WEEKDAY, CAST([DATE] AS DATE)) IN ('Saturday', 'Sunday') THEN 'Weekend'
        ELSE 'Weekday'
    END
ORDER BY 
    pickup_zone, DayType;

--==========================================================================================================================================================




