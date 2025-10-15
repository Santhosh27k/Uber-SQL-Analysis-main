🚖 Uber Trip Data Analysis — Power BI Dashboard


📘 Overview


This Power BI Dashboard presents a comprehensive analysis of Uber trip data, focusing on trends in revenue, demand, distance, passenger patterns, and hourly performance.
It connects live to SQL Server (DirectQuery) where cleaned and prepared data is stored.

The dashboard is divided into three analytical pages, each designed for different insights:
1️⃣ Overview & Trend Summary
2️⃣ Trip Behavior
3️⃣ Temporal Demand & Revenue Pattern

-----------------------------------------------------------------------------------------------------------------

🧩 Data Details

Data Source: Uber Fares Dataset — Kaggle

Database: UberTripsDB (SQL Server)
Connection Mode: DirectQuery

SQL Views Used:

vw_TripCountByDayOfWeek

vw_PassengerCount

vw_TripImbalance

Top_Zone_by_Hour

-------------------------------------------------------------------------------------------------------------------------------------

📊 Dashboard Pages


🟦 1. Overview & Trend Summary

Purpose: Provide a high-level summary of Uber’s performance metrics and annual trends.

Key Metrics:

Total Revenue: $2.27M

Total Trip Count: 192.7K

Revenue per Trip: $11.32

Average Trip Distance: 3.36 km

Visuals:

Line Chart: Total Revenue vs Trip Count by Year

Line Chart: Average Trip Distance by Year

KPIs: Revenue, Trip Count, Revenue per Trip

💡 Insight:
Steady growth in both revenue and trip count until 2014; slight dip in 2015 due to partial data (6 months).

--------------------------------------------------------------------------------------------------------------------------------------------------

🟨 2. Trip Behavior

Purpose: Analyze how trip characteristics (distance and passenger type) impact fares and demand.

Visuals:

Bar Chart: Trip Count by Distance Category

Combo Chart: Average Fare vs Average Distance by Category

Table: Weekday vs Weekend distribution by Distance Category

Donut Chart: Passenger Ride Type (Single vs Multi-passenger)

Distance Categories:

Category	Range (km)
Very Short	< 5
Short	5–10
Long	10–20
Very Long	20–30
Outer City	> 30

💡 Insights:

~82% of all trips are Very Short (<5 km).

Single-passenger trips dominate with 69% share.

Outer-city rides are rare but have the highest average fare.

------------------------------------------------------------------------------------------------------------------------------

🟩 3. Temporal Demand & Revenue Pattern

Purpose: Explore time-based trends in daily and hourly revenue.

Key Metrics:

Average Daily Revenue: $919.98

Average Daily Trips: 81.24

Avg Revenue per Hour: $38.33

Average Hourly Trips: 3.38

Visuals:

Heatmaps: Hour-of-day vs Day-of-week for revenue patterns.

Color-coded Legend:

🟢 High (≥130% of avg revenue)

🟠 Above Average (115–130%)

🔴 Low (≤60%)

⚪ Normal Range

💡 Insights:

Highest revenue between 5–9 PM on Friday and Saturday.

Morning hours (6–9 AM) show secondary demand peaks.

Consistent off-peak lows observed between 1–4 AM.

---------------------------------------------------------------------------------------------------------------------------

🟦 4. Route Analysis

Purpose: Analyze top-performing routes and compare weekday vs weekend revenue trends.


Visuals:

Top Route by Trip Count

Top Route by Revenue

Top 10 Routes by Total Trips (bar chart)

Top 10 Routes by Revenue (line chart by day type)

Year slicer for trend filtering



Key Highlights:

Top Route (by Trips): 40.75, -73.99 → 40.76, -73.98

Top Route (by Revenue): 40.75, -73.99 → 40.76, -73.98

Trip Count: 1.13K

Revenue: $8.21K



💡 Insights:

Strong weekday dominance across top routes.

Revenue concentration around central zones (~40.75°–40.77° lat, ~–73.98° long).

Weekday routes generate 25–30% higher fares than weekend trips.

📎 Note: 2015 includes only 6 months of data — partial year trends.




-------------------------------------------------------------------------------------------------------------------------

🧠 Design Highlights------------

Dynamic Filters: Year selector for all pages.

Interactive Buttons: Navigate across pages (using Page Navigation).

Color-coded KPIs: Immediate comparison of performance metrics.

Clean Layout: Consistent theme with distinct zone-based visual hierarchy.

------------------------------------------------------------------------------------------------------------------------

⚙️ How to Use------------------------

Open Uber_Analysis_Dashboard.pbix in Power BI Desktop.

Update the SQL connection (under Transform Data → Data Source Settings).

Refresh the report — all visuals will update automatically.

-----------------------------------------------------------------------------------------------------------

📈 Analytical Focus----------------------------------

Yearly growth and revenue trend analysis

Distance category segmentation

Passenger type distribution

Hourly and weekday demand patterns

Data-driven revenue performance insights

Route optimization and imbalance detection

-----------------------------------------------------------------------------------------------------

🧾 Notes

2015 data includes only six months — partial year trends.

All visuals use DirectQuery for live updates from SQL Server.

------------------------------------------------------------------------------------------------

🔗 Data Flow Diagram
--------------------

Uber CSV → SQL Server (UberTripsDB)
         ↓
     SQL Views (vw_TripImbalance, etc.)
         ↓
   Power BI (DirectQuery)
         ↓
 Interactive Dashboard

-------------------------------------------------------------------------------------


👤 Author---------------------

Project: Uber Trip Data Analysis
Author:  Santhosh S
Github : https://github.com/Santhosh27k/Uber-SQL-Analysis-main
LindIn : www.linkedin.com/in/santhosh-s-219287228
Year:    2025
Tools:   Microsoft SQL Server, Power BI