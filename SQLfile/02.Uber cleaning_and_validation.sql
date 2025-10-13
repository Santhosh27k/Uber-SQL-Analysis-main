					
	--============================================================================================================================================================
----------------------------------------------------------------------------------------------------------------------------------------------------------

										🚖 Uber Trip Data Analysis Using SQL Server
													
													🧑‍💻 Author: Santhosh

													 📅 Year: 2025

								-- 📌 Description: [Put a brief here like 'Phase 2:  Data_cleaning_and_validation  ']
----------------------------------------------------------------------------------------------------------------------------------------------------------






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



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 4: Preview the Data
--If you want to import directly from Excel without converting:
--==========================================================================================================================================================

SELECT * 
FROM Uber;

--==========================================================================================================================================================
'''
Verify the successful import of data into the Uber table.

What to Check ?:

Data appears correctly in all columns (e.g., fare_amount, pickup_datetime, passenger_count, coordinates).

No header row included as data.

No obvious anomalies (e.g., missing values, misaligned data).
'''
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------





-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 5: Identify Duplicate Records
--==========================================================================================================================================================

WITH Duplicate AS (
    SELECT
        OrderID,
        ROW_NUMBER() OVER (
            PARTITION BY OrderID, [Key], Fare_amount, Pickup_Datetime, 
                         Pickup_Longitude, Pickup_Latitude, 
                         Dropoff_Longitude, Dropoff_latitude, 
                         Passenger_count
            ORDER BY OrderID
        ) AS Rownumber
    FROM Uber
)
SELECT * 
FROM Duplicate
WHERE Rownumber > 1;

--==========================================================================================================================================================
'''
Identify duplicate rows in the Uber table. This is useful for detecting redundant data that can affect analysis accuracy.

How It Works:

ROW_NUMBER() assigns a unique row number to each record in a group of potential duplicates.

The PARTITION BY clause defines what fields should be considered for duplication.

Rows with Rownumber > 1 are true duplicates beyond the first instance.

**Use Case:

Helps in data cleaning by identifying redundant records.

Can be modified to delete duplicates if needed.

'''

Why include [Key]?

In this dataset, [Key] is a unique identifier or hash for each trip.

Including [Key] in the PARTITION BY ensures we only flag true duplicate rows where even the supposedly unique key is repeated — a strong sign of redundant data.

If [Key] is not included, even slightly different trips (with different hashes) may be wrongly marked as duplicates.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

✅ Result:

No duplicate records were found in the dataset.
This confirms the dataset is already clean in terms of duplicate rows.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 6: Data Cleaning – Check for Missing Values
--==========================================================================================================================================================

-- Check for missing Order IDs
SELECT * 
FROM Uber 
WHERE OrderID IS NULL;

-- Check for missing trip keys
SELECT * 
FROM Uber 
WHERE [Key] IS NULL;

-- Check for missing fare amounts
SELECT * 
FROM Uber 
WHERE fare_amount IS NULL;

--==========================================================================================================================================================
'''
Purpose:

To identify and handle any records with missing critical information, such as:

OrderID: could be important for identifying each transaction.

[Key]: unique trip identifier (used for tracking and joins).

fare_amount: essential for fare-based analytics and insights.
'''
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


✅ Result:

No NULL values were found in the above columns.
This confirms that the dataset does not have any missing values in these key fields.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 7:  Extracting Date, Time, and Timezone from Pickup_datetime

--==========================================================================================================================================================

'''
The original Pickup_datetime column contains full timestamp info like:

"2014-07-01 00:03:00 UTC"

This step separates it into three meaningful parts: Date, Time, and Timezone.
'''
--==========================================================================================================================================================


--🗓️ Add DATE Column (as string)


ALTER TABLE Uber
ADD [DATE] NCHAR(15);  -- Keeping it as string for easier conversion

===========================================================================

UPDATE Uber
SET [DATE] = SUBSTRING(Pickup_datetime, 1, 10);

--📌 Note: Date is extracted from the first 10 characters (YYYY-MM-DD).

--==========================================================================================================================================================

--🕒 Add Time Column


ALTER TABLE Uber
ADD [Time] NCHAR(15);  -- Stored as string

===========================================================================

UPDATE Uber
SET [Time] = SUBSTRING(Pickup_datetime, 12, 8);

--📌 Note: Time is extracted from characters 12 to 19 (HH:MM:SS).

--==========================================================================================================================================================

--🕰️ Add TimeZone Column
--Check where 'UTC' starts:

SELECT CHARINDEX('UTC', Pickup_datetime) AS Start 
FROM Uber;
Then extract and insert TimeZone:

===========================================================================

ALTER TABLE Uber
ADD TimeZone NCHAR(15);

===========================================================================

UPDATE Uber
SET TimeZone = SUBSTRING(Pickup_datetime, 21, 3);


--📌 Note: UTC starts at character position 21. Extracting 3 characters gives you the time zone string.

--==========================================================================================================================================================

✅ Result:
Now your dataset has the following newly added fields:

[DATE]: e.g., '2014-07-01'

[Time]: e.g., '00:03:00'

TimeZone: 'UTC'

This enables easier date-wise, time-wise, and timezone-based analysis in later steps.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 8: Drop Unnecessary Column

--Remove Pickup_datetime Column After Splitting
--==========================================================================================================================================================

ALTER TABLE Uber 
DROP COLUMN Pickup_datetime;

--==========================================================================================================================================================

--📌 Explanation:

'''After extracting Date, Time, and TimeZone into separate columns, the original Pickup_datetime column is no longer needed.

Dropping this column reduces redundancy and improves table clarity.
'''

✅ Outcome:

Clean, organized table with distinct time-related components.

Minimizes confusion during analysis or reporting.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------






-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 9:  Fare Amount Cleanup & Validation

--==========================================================================================================================================================

--Round off Fare to 2 Decimal Places

SELECT ROUND(Fare_amount, 2) AS amount 
FROM Uber;

--📌 Note: This is to display the fare_amount rounded to 2 decimal places for cleaner reporting.

===========================================================================

--Check for Negative Fare Charges

SELECT SIGN(Fare_Amount) AS SIGN 
FROM Uber
WHERE SIGN(Fare_Amount) < -1;

--==========================================================================================================================================================
/*
--📌 Note:
'''
We are using the SIGN() function to detect any invalid negative fare amounts.

SIGN() returns -1 for negative, 0 for zero, and 1 for positive values.

In our case, any value less than -1 is considered invalid.
'''
*/
--✅  Result: No negative fare values were found.

===========================================================================

--Alter Column to Fix Decimal Precision
--If required, you can change the column data type to store fares with fixed precision:


ALTER TABLE Uber
ALTER COLUMN Fare_Amount DECIMAL(10, 2);  -- max 10 digits, 2 after decimal

/*
--📌 Why?

'''Initially, the Fare_Amount column might be of FLOAT or DECIMAL(15, x), which is excessive.

Setting it to DECIMAL(10,2) makes it more suitable for financial values and saves space.'''
*/
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 10: Passenger Count Cleanup

--==========================================================================================================================================================

UPDATE Uber
SET passenger_count = 1
WHERE passenger_count < 1;

--==========================================================================================================================================================

--📌 Explanation:

--Some records might have passenger_count as 0 or negative, which is not realistic.

--We assume these are missing values and default them to 1, as it is the most common and neutral assumption.


✅ RESULT:

Ensures no trip has an invalid or missing passenger count.

Data becomes more reliable for analysis like trip density, efficiency, and segmentation.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 11: Validating and Cleaning Geolocation Data

--==========================================================================================================================================================

--Identify Invalid Latitude and Longitude Values

SELECT * FROM Uber
WHERE pickup_latitude NOT BETWEEN -90 AND 90
   OR dropoff_latitude NOT BETWEEN -90 AND 90;

SELECT * FROM Uber
WHERE pickup_longitude NOT BETWEEN -180 AND 180
   OR dropoff_longitude NOT BETWEEN -180 AND 180;

 /*
 --📌 Explanation:

'''Latitude must be between -90 and 90.

Longitude must be between -180 and 180.

Any values outside this range are geographically impossible and likely data entry errors.
'''
*/
===========================================================================

-- Check for NULL or Invalid Geolocation Data

SELECT * FROM Uber
WHERE 
    pickup_latitude IS NULL OR
    dropoff_latitude IS NULL OR 
    pickup_longitude IS NULL OR
    dropoff_longitude IS NULL
    OR pickup_latitude NOT BETWEEN -90 AND 90
    OR dropoff_latitude NOT BETWEEN -90 AND 90
    OR pickup_longitude NOT BETWEEN -180 AND 180
    OR dropoff_longitude NOT BETWEEN -180 AND 180;


'''📌 Purpose:

To identify all rows with missing or invalid geolocation data before deleting.'''

===========================================================================

--Delete Invalid Geolocation Records

DELETE FROM Uber
WHERE 
    pickup_latitude IS NULL OR
    dropoff_latitude IS NULL OR 
    pickup_longitude IS NULL OR
    dropoff_longitude IS NULL
    OR pickup_latitude NOT BETWEEN -90 AND 90
    OR dropoff_latitude NOT BETWEEN -90 AND 90
    OR pickup_longitude NOT BETWEEN -180 AND 180
    OR dropoff_longitude NOT BETWEEN -180 AND 180;


'''✅ Result:

Ensures that only valid and complete trips are retained for accurate analysis.'''
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 12: Calculating Trip Distance in Kilometers

--==========================================================================================================================================================

					--Add Distance_km Column

ALTER TABLE UBER
ADD Distance_km DECIMAL(10,2);

===========================================================================

			-- Update Distance_km Using the Haversine Formula

PRINT' Haversine Distance Calculation (Rounded to 2 Decimal Places)'
WITH DistanceCalc AS (
    SELECT 
        [key],  -- Unique identifier
        COS(RADIANS(pickup_latitude)) * COS(RADIANS(dropoff_latitude)) * 
        COS(RADIANS(dropoff_longitude) - RADIANS(pickup_longitude)) + 
        SIN(RADIANS(pickup_latitude)) * SIN(RADIANS(dropoff_latitude)) AS acos_input
    FROM UBER
    WHERE 
        pickup_latitude BETWEEN -90 AND 90
        AND dropoff_latitude BETWEEN -90 AND 90
        AND pickup_longitude BETWEEN -180 AND 180
        AND dropoff_longitude BETWEEN -180 AND 180
        AND pickup_latitude IS NOT NULL
        AND dropoff_latitude IS NOT NULL
        AND pickup_longitude IS NOT NULL
        AND dropoff_longitude IS NOT NULL
)
UPDATE U
SET Distance_km = ROUND(6371 * ACOS(
    CASE 
        WHEN D.acos_input > 1 THEN 1
        WHEN D.acos_input < -1 THEN -1
        ELSE D.acos_input
    END
), 2)
FROM UBER U
JOIN DistanceCalc D ON U.[key] = D.[key];

--==========================================================================================================================================================

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Step 13:Creating Zones from Latitude and Longitude (Using Midpoint Reference)

						
--==========================================================================================================================================================

-Createing zone through long -latitude ( taking the avg as the mid to deterime the direction)

--==========================================================================================================================================================


										-- Without Distance Condition

/* Midpoints: Without Distance Condition 
Pickup Midpoint:
Latitude = 39.9774, Longitude = -72.562

Drop-off Midpoint:
Latitude = 39.9810, Longitude = -72.572

 Observation:
The midpoints are very close — just ~0.0036° difference in latitude and ~0.01° in longitude. This is negligible, so:
*/

	===========================================================================

	SELECT 
    AVG(pickup_latitude) AS mid_lat_pickup,
    AVG(pickup_longitude) AS mid_lon_pickup
FROM UBER
WHERE pickup_latitude BETWEEN -90 AND 90
  AND pickup_longitude BETWEEN -180 AND 180;

  	===========================================================================

  SELECT 
    AVG(dropoff_latitude) AS mid_lat_dropoff,
    AVG(dropoff_longitude) AS mid_lon_dropoff
FROM UBER
WHERE dropoff_latitude BETWEEN -90 AND 90
  AND dropoff_longitude BETWEEN -180 AND 180;

 --==========================================================================================================================================================

												-- With Distance Condition

/* Midpoints: With Condtion Distance < 0
Pickup Midpoint:
Latitude =40.7073700462933, Longitude = -73.888188881396

Drop-off Midpoint:
Latitude = 40.7120230887492, Longitude = -73.8990858971966

*/

===========================================================================

	SELECT 
    AVG(pickup_latitude) AS mid_lat_pickup,
    AVG(pickup_longitude) AS mid_lon_pickup
FROM UBER
WHERE pickup_latitude BETWEEN -90 AND 90
  AND pickup_longitude BETWEEN -180 AND 180
  AND Distance_km > 0;

  	===========================================================================

  SELECT 
    AVG(dropoff_latitude) AS mid_lat_dropoff,
    AVG(dropoff_longitude) AS mid_lon_dropoff
FROM UBER
WHERE dropoff_latitude BETWEEN -90 AND 90
  AND dropoff_longitude BETWEEN -180 AND 180
  Distance_km > 0;

 
 /*
  	🧭 Reference Midpoint (for Both Pickup & Drop-off):
'''
It is best to consider both midpoints separately because pickup and drop-off locations represent distinct spatial zones or activity centers.
Use the pickup midpoint (Latitude 40.70737, Longitude -73.88819) to define the zone representing where trips start.
Use the drop-off midpoint (Latitude 40.71202, Longitude -73.89909) to define the zone representing where trips end.
This allows analyzing spatial patterns independently for pickups and drop-offs, which is more informative than merging them into one point.
Since these midpoints differ by about 500–900 meters, treating them separately gives a clearer picture of the zones involved.'''

*/

--==========================================================================================================================================================

--📘 Note - “Zone boundaries were determined by computing the midpoint of latitude and longitude from valid pickup and dropoff coordinates. 
		--This ensures directional segmentation is adapted to the actual dataset geography rather than using fixed cutoffs

	===========================================================================
--Add Zone Columns
				--Step 1: Add Pickup and Drop-off Zone Columns


ALTER TABLE Uber
ADD Pickup_Zone NCHAR(10),
    Dropoff_Zone NCHAR(10);


	===========================================================================
/*
	Classify Trips into Geographic Zones (NW / NE / SW / SE)
	We’ll use a midpoint of:


*/
	===========================================================================

PRINT 'Pickup Midpoint:
    Latitude = 40.7073700462933, Longitude = -73.888188881396
Drop-off Midpoint:
    Latitude = 40.7120230887492, Longitude = -73.8990858971966'
UPDATE UBER
SET pickup_zone = 
    CASE 
        WHEN pickup_latitude >= 40.7073700462933 AND pickup_longitude <= -73.888188881396 THEN 'NW'
        WHEN pickup_latitude >= 40.7073700462933 AND pickup_longitude >  -73.888188881396 THEN 'NE'
        WHEN pickup_latitude <  40.7073700462933 AND pickup_longitude <= -73.888188881396 THEN 'SW'
        WHEN pickup_latitude <  40.7073700462933 AND pickup_longitude >  -73.888188881396 THEN 'SE'
        ELSE 'Unknown'
    END,
    dropoff_zone = 
    CASE 
        WHEN dropoff_latitude >= 40.7120230887492 AND dropoff_longitude <= -73.8990858971966 THEN 'NW'
        WHEN dropoff_latitude >= 40.7120230887492 AND dropoff_longitude >  -73.8990858971966 THEN 'NE'
        WHEN dropoff_latitude <  40.7120230887492 AND dropoff_longitude <= -73.8990858971966 THEN 'SW'
        WHEN dropoff_latitude <  40.7120230887492 AND dropoff_longitude >  -73.8990858971966 THEN 'SE'
        ELSE 'Unknown'
    END;

	===========================================================================
	
	'''✅ Updated pickup_zone and dropoff_zone Logic:'''

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
