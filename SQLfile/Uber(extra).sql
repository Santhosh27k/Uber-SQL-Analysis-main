-- Step 1: Create a new database
CREATE DATABASE "UBER";

USE Uber;

EXEC sp_rename 'Uber.ORderID' , 'OrderID' ,'COLUMN';


SELECT * 
FROM Uber


-- STEP 2- Duplicate Search -

-- 1.Using RowNumber --

WITH Duplicate AS
(
SELECT
    OrderID,
    ROW_NUMBER() OVER(
        PARTITION BY OrderID,[Key],Fare_amount,Pickup_Datetime,Pickup_Longitude,Pickup_Latitude,Dropoff_Longitude,Dropoff_latitude,Passenger_count
        ORDER BY OrderID
    ) AS Rownumber
FROM Uber
)
SELECT * FROM Duplicate
WHERE Rownumber > 1;


-- 2. Group BY using [Duplicate]

Select 
  OrderID,[Key],Fare_amount,Pickup_Datetime,Pickup_Longitude,Pickup_Latitude,Dropoff_Longitude,Dropoff_latitude,Passenger_count,
COUNT(*) AS iCount
FROM Uber
GROUP BY OrderID,[Key],Fare_amount,Pickup_Datetime,Pickup_Longitude,Pickup_Latitude,Dropoff_Longitude,Dropoff_latitude,Passenger_count
HAVING COUNT(*) > 1;


--Step 3 - Cleaning 


Where OrderID Is Null;

SELECT * From Uber 
Where [Key] Is Null

SELECT * From Uber 
Where fare_amount Is Null;


-- step 3 ------------------------------------Aggregment

SELECT * 
From Uber;

Exec Sp_Help Uber;

--Date into Sepreate column 

SELECT SUBSTRING(Pickup_datetime, 1, 10) AS DATE 
FROM uber;

----------ALTER ADD [DATE CLOUMN]

ALTER TABLE Uber
ADD [DATE] Nchar(15) -- [Reason i am keeping it a string because its diffculture to tranfer data from string column to date/time column]

UPDATE Uber
SET [DATE] = SUBSTRING(Pickup_datetime,1,10);

--Time into Sepreate column 

SELECT SUBSTRING(Pickup_datetime, 12,8) AS TIME 
FROM uber;

-------ALter Time into seperate column

ALTER TABLE Uber
ADD [time] Nchar(15) -- [Reason i am keeping it a string because its diffculture to tranfer data from string column to date/time column]

UPDATE Uber
SET [Time] = SUBSTRING(Pickup_datetime,12,8);

-- use of charindex to find the Sart point of UTC

SELECT CHARINDEX('UTC', Pickup_datetime) AS Start 
FROM Uber;

----timezone into column

----
SELECT SUBSTRING(Pickup_datetime ,21,3) AS Timeline 
FROM Uber;

ALTER TABLE Uber
ADD TimeZone Nchar(15);

UPDATE Uber
SET TimeZone = SUBSTRING(Pickup_datetime,21,3);

----------------------------------------------------------------
-- round off fare_amount

SELECT ROUND(Fare_amount, 2) AS amount FROM uber 


--- LOOKING FOR any negative fare charge

SELECT SIGN(Fare_Amount) AS SIGN FROM Uber
WHERE SIGN(Fare_Amount) < -1;

----------------------------





------------------------------------------

SELECT * 
FROM UBER;

--------------
-- Making Passeger count default to 1 is there no count

UPDATE Uber
SET passenger_count = 1
WHERE passenger_count < 1 

SELECT *  FROM Uber
WHERE passenger_count < 1
 
 SELECT *  FROM Uber
WHERE fare_amount <= 0

 SELECT *  FROM Uber
WHERE pickup_latitude Not Between -90 and 90
		OR dropoff_latitude Not Between -90 and 90;

 SELECT *  FROM Uber
WHERE pickup_longitude Not Between -180 and 180
		or dropoff_longitude Not Between -180 and 180;


---------------------ALTERING TABLE 

USE UBER

ALTER TABLE Uber Drop Column Pickup_DateTime;

SELECT * 
From Uber;

SELECT ROUND(Fare_amount ,2) AS Fair_Amount FROM Uber


SELECT CAST(ROUND(Fare_amount, 2) AS DECIMAL(10,2)) AS rounded_price
FROM Uber;


ALTER TABLE UBER
ALTER COLUMN fare_amount DECIMAL(10,2);


SELECT * FROM Uber
WHERE 
    pickup_latitude IS  NULL OR
    dropoff_latitude IS  NULL OR 
    pickup_longitude IS  NULL OR
    dropoff_longitude IS  NULL
    OR pickup_latitude not BETWEEN -90 AND 90
    OR dropoff_latitude not BETWEEN -90 AND 90
    OR pickup_longitude not BETWEEN -180 AND 180
    OR dropoff_longitude not BETWEEN -180 AND 180;

DELETE FROM Uber
WHERE 
    pickup_latitude IS  NULL OR
    dropoff_latitude IS  NULL OR 
    pickup_longitude IS  NULL OR
    dropoff_longitude IS  NULL
    OR pickup_latitude not BETWEEN -90 AND 90
    OR dropoff_latitude not BETWEEN -90 AND 90
    OR pickup_longitude not BETWEEN -180 AND 180
    OR dropoff_longitude not BETWEEN -180 AND 180;


SELECT 
    *,
    6371 * ACOS(
        COS(RADIANS(pickup_latitude)) 
        * COS(RADIANS(dropoff_latitude)) 
        * COS(RADIANS(dropoff_longitude) - RADIANS(pickup_longitude)) 
        + SIN(RADIANS(pickup_latitude)) 
        * SIN(RADIANS(dropoff_latitude))
    ) AS trip_distance_km
FROM UBER;


WITH DistanceCalc AS (
    SELECT *,
        -- Calculate the inner value for ACOS
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
SELECT *,
    6371 * ACOS(
        CASE 
            WHEN acos_input > 1 THEN 1
            WHEN acos_input < -1 THEN -1
            ELSE acos_input
        END
    ) AS trip_distance_km
FROM DistanceCalc;


ALTER TABLE UBER
ADD Distance_km DECIMAL(10,2);

WITH DistanceCalc AS (
    SELECT 
        [key],  -- Assuming 'key' is a unique identifier
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

SELECT * 
From Uber;

USE Uber


SELECT Distance_Km FROM Uber
WHERE Distance_km > 1

-----------------------------------

--Createing zone through long -latitude ( taking the avg as the mid to deterime the direction)
/* Midpoints:
Pickup Midpoint:
Latitude = 39.9774, Longitude = -72.562

Drop-off Midpoint:
Latitude = 39.9810, Longitude = -72.572

 Observation:
The midpoints are very close — just ~0.0036° difference in latitude and ~0.01° in longitude. This is negligible, so:
*/


SELECT 
    AVG(pickup_latitude) AS mid_lat_pickup,
    AVG(pickup_longitude) AS mid_lon_pickup
FROM UBER
WHERE pickup_latitude BETWEEN -90 AND 90
  AND pickup_longitude BETWEEN -180 AND 180;

  SELECT 
    AVG(dropoff_latitude) AS mid_lat_dropoff,
    AVG(dropoff_longitude) AS mid_lon_dropoff
FROM UBER
WHERE dropoff_latitude BETWEEN -90 AND 90
  AND dropoff_longitude BETWEEN -180 AND 180;

  -----------------------------------
  ALTER TABLE UBER
ADD pickup_zone VARCHAR(10), dropoff_zone VARCHAR(10);


----------------------------

UPDATE UBER
SET pickup_zone = 
    CASE 
        WHEN pickup_latitude >= 40.7 AND pickup_longitude <= -73.95 THEN 'NW'
        WHEN pickup_latitude >= 40.7 AND pickup_longitude >  -73.95 THEN 'NE'
        WHEN pickup_latitude <  40.7 AND pickup_longitude <= -73.95 THEN 'SW'
        WHEN pickup_latitude <  40.7 AND pickup_longitude >  -73.95 THEN 'SE'
        ELSE 'Unknown'
    END,
    dropoff_zone = 
    CASE 
        WHEN dropoff_latitude >= 40.7 AND dropoff_longitude <= -73.95 THEN 'NW'
        WHEN dropoff_latitude >= 40.7 AND dropoff_longitude >  -73.95 THEN 'NE'
        WHEN dropoff_latitude <  40.7 AND dropoff_longitude <= -73.95 THEN 'SW'
        WHEN dropoff_latitude <  40.7 AND dropoff_longitude >  -73.95 THEN 'SE'
        ELSE 'Unknown'
    END;

EXEC sp_rename 'UBER.DATE', 'pickup_date', 'COLUMN';
EXEC sp_rename 'UBER.time', 'pickup_time', 'COLUMN';


/*Phase 1: Anomaly Detection Module

🎯 Goal: Identify trips with possible data issues or suspicious patterns

Set of Anomaly Conditions

passenger_count < 1

passenger_count > 7

fare_amount <= 0

Distance_km <= 0

*/


select * from Uber;

ALTER TABLE Uber ADD Anomaly Int;

UPDATE Uber
SET Anomaly = 
CASE	
		WHEN passenger_count < 1 THEN 1
		WHEN passenger_count > 7 THEN 2
		WHEN fare_amount <= 0	THEN 3
		WHEN Distance_km <= 0 THEN 4
	ELSE 0
	END;

	--------------------------------
/*	Anomaly Value	Meaning
0	Not anomalous
1	passenger_count < 1
2	passenger_count > 7
3	fare_amount <= 0
4	Distance_km <= 0

*/

SELECT COUNT(Anomaly) AS passenger_count_Anomaly FROM UBER 
WHERE Anomaly = 1

SELECT COUNT(Anomaly) AS passenger_morethan7_Anomaly FROM UBER 
WHERE Anomaly = 2

SELECT COUNT(Anomaly) AS fare_amount_Anomaly FROM UBER 
WHERE Anomaly = 3

SELECT COUNT(Anomaly) AS Distance_km_Anomaly FROM UBER 
WHERE Anomaly = 4

----------------------------------------------

USE UBER

SELECT ISNULL(Pickup_zone,'TOTAL') AS PICKUP, 
		ISNULL(dropoff_zone,'TOTAL')AS DROPOFF ,COUNT([KEY]) AS Totaltrip 
										FROM 
										(SELECT Pickup_zone, dropoff_zone , [KEY] FROM Uber
										WHERE Pickup_zone IS NOT NULL AND 
										dropoff_zone IS NOT NULL
										AND Anomaly = 0 ) AS SUBQUERY 
GROUP BY ROLLUP(Pickup_zone, dropoff_zone)

ORDER BY COUNT([KEY]) DESC

------------------------------------------------------------------------------------------
SELECT Pickup_zone, dropoff_zone, COUNT([KEY]) AS TOTALTRIPS FROM Uber
WHERE Pickup_zone IS NOT NULL AND 
		dropoff_zone IS NOT NULL AND
		Anomaly = 0
GROUP BY Pickup_zone, dropoff_zone
ORDER BY COUNT([KEY]) DESC

-----------------------------------------------------------------------------
WITH ZoneFlow AS (
    SELECT pickup_zone, dropoff_zone, COUNT(*) AS TripCount
    FROM Uber
    WHERE Anomaly = 0
    GROUP BY pickup_zone, dropoff_zone
)
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
WHERE A.pickup_zone < A.dropoff_zone  -- to avoid duplicates
ORDER BY Imbalance DESC;

------------------------------------------------------------------------------------------

WITH tripPassenger AS(
		SELECT pickup_zone, dropoff_zone, SUM(Passenger_count) AS TotalPassenger FROM UBER
		WHERE Anomaly = 0
		GROUP BY pickup_zone, dropoff_zone
		)
SELECT A.pickup_zone, A.dropoff_zone, 
		A.TotalPassenger AS Trips_A_to_B,
		B.TotalPassenger AS Trips_B_to_A,
		ABS (A.TotalPassenger - B.TotalPassenger) AS Imbalance
FROM tripPassenger A
JOIN tripPassenger B
ON A.pickup_zone = B.dropoff_zone 
    AND A.dropoff_zone = B.pickup_zone
WHERE A.pickup_zone <= A.dropoff_zone
      AND A.pickup_zone < B.pickup_zone
 -- to avoid duplicates
ORDER BY Imbalance DESC;

--------------------------------------------------------------------------


SELECT * FROM Uber;
------------------------------------------------------------

SELECT DISTINCT DATEPART(HOUR, time) AS [TIME] ,COUNT([KEY]) AS Totaltrip  FROM Uber
WHERE Anomaly = 0
GROUP BY DATEPART(HOUR, time)
ORDER BY DATEPART(HOUR, time) ASC


----------------------------------------------------------------------------------



---------------------------------------------------------------
SELECT DISTINCT DATEPART(HOUR, time) AS [TIME] ,COUNT([KEY]) AS Totaltrip , pickup_zone FROM Uber
WHERE Anomaly = 0
GROUP BY DATEPART(HOUR, time) ,pickup_zone
ORDER BY DATEPART(HOUR, time) ASC

SELECT DISTINCT DATEPART(HOUR, time) AS [TIME] ,COUNT([KEY]) AS Totaltrip , dropoff_zone FROM Uber
WHERE Anomaly = 0
GROUP BY DATEPART(HOUR, time) ,dropoff_zone
ORDER BY DATEPART(HOUR, time) ASC

-----------------------------------------------------------------------------------
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
WHERE rk = 1

------------------------------------------------------------------------------------
 
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
WHERE rk = 1

------------------------------------------------------------------------------------

SELECT * FROM Uber;

SELECT COUNT([KEY]) ,Dropoff_zone FROM Uber
WHERE Dropoff_zone = 'NW' AND 
Anomaly = 0
GROUP BY Dropoff_zone;

SELECT COUNT([KEY]), Pickup_zone  FROM Uber
WHERE Pickup_zone = 'NW' AND 
Anomaly = 0
GROUP BY Pickup_zone;

