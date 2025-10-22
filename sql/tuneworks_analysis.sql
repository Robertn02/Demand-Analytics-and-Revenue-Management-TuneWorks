/* =========================================================
   TUNEWORKS – PHASED ANALYSIS SCRIPT
   DB: Postgres-style syntax
   ========================================================= */

/* -----------------------------
   0) QUICK PEEKS (HEADS + COUNTS)
   ----------------------------- */

-- Heads (sample 10)
SELECT * FROM agents                LIMIT 10;
SELECT * FROM customers             LIMIT 10;
SELECT * FROM engagements           LIMIT 10;
SELECT * FROM entertainer_members   LIMIT 10;
SELECT * FROM entertainer_styles    LIMIT 10;
SELECT * FROM entertainers          LIMIT 10;
SELECT * FROM members               LIMIT 10;
SELECT * FROM musical_preferences   LIMIT 10;
SELECT * FROM musical_styles        LIMIT 10;
SELECT * FROM ztbldays              LIMIT 10;
SELECT * FROM ztblmonths            LIMIT 10;
SELECT * FROM ztblweeks             LIMIT 10;
/* NOTE: your list showed ztblskilabels; fix the typo if table name differs */
SELECT * FROM ztblskiplabels         LIMIT 10;

-- Row counts
SELECT 'agents' AS tbl, COUNT(*) FROM agents
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'engagements', COUNT(*) FROM engagements
UNION ALL SELECT 'entertainer_members', COUNT(*) FROM entertainer_members
UNION ALL SELECT 'entertainer_styles', COUNT(*) FROM entertainer_styles
UNION ALL SELECT 'entertainers', COUNT(*) FROM entertainers
UNION ALL SELECT 'members', COUNT(*) FROM members
UNION ALL SELECT 'musical_preferences', COUNT(*) FROM musical_preferences
UNION ALL SELECT 'musical_styles', COUNT(*) FROM musical_styles
UNION ALL SELECT 'ztbldays', COUNT(*) FROM ztbldays
UNION ALL SELECT 'ztblmonths', COUNT(*) FROM ztblmonths
UNION ALL SELECT 'ztblweeks', COUNT(*) FROM ztblweeks
UNION ALL SELECT 'ztblskilabels', COUNT(*) FROM ztblskiplabels;


/* -----------------------------
   1) DATA QA – NULLS / RANGES
   ----------------------------- */

-- Engagements: nulls on key fields (adjust column names if needed)
SELECT 
  COUNT(*)                                  AS total_rows,
  COUNT(*) FILTER (WHERE engagementnumber IS NULL) AS engagementnumber_nulls,
  COUNT(*) FILTER (WHERE entertainerid   IS NULL)  AS entertainerid_nulls,
  COUNT(*) FILTER (WHERE customerid      IS NULL)  AS customerid_nulls,
  COUNT(*) FILTER (WHERE agentid         IS NULL)  AS agentid_nulls,
  COUNT(*) FILTER (WHERE startdate       IS NULL)  AS startdate_nulls,
  COUNT(*) FILTER (WHERE enddate         IS NULL)  AS enddate_nulls,
  COUNT(*) FILTER (WHERE contractprice   IS NULL)  AS contractprice_nulls
FROM engagements;

-- Agents: nulls on personnel fields
SELECT
  COUNT(*) AS total_rows,
  COUNT(*) FILTER (WHERE agtfirstname IS NULL) AS null_firstname,
  COUNT(*) FILTER (WHERE agtlastname  IS NULL) AS null_lastname,
  COUNT(*) FILTER (WHERE agtphonenumber IS NULL) AS null_phone,
  COUNT(*) FILTER (WHERE datehired     IS NULL) AS null_datehired,
  COUNT(*) FILTER (WHERE salary        IS NULL) AS null_salary,
  COUNT(*) FILTER (WHERE commissionrate IS NULL) AS null_commissionrate
FROM agents;

-- Date sanity (no negative durations; start before end)
SELECT engagementnumber, startdate, enddate
FROM engagements
WHERE enddate < startdate;

-- Event window covered
SELECT MIN(startdate) AS min_start, MAX(enddate) AS max_end FROM engagements;


/* -----------------------------
   2) DATA QA – DUPLICATES
   ----------------------------- */

-- If engagementnumber is the PK, dupes should be zero
SELECT engagementnumber, COUNT(*) AS cnt
FROM engagements
GROUP BY engagementnumber
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- If no single PK exists, use a business key check (example)
-- (Adjust columns to your uniqueness rule)
SELECT entertainerid, customerid, startdate, COUNT(*) AS cnt
FROM engagements
GROUP BY entertainerid, customerid, startdate
HAVING COUNT(*) > 1
ORDER BY cnt DESC;


/* -----------------------------
   3) DATA QA – FORMAT / STANDARDIZATION
   ----------------------------- */

-- Distinct case patterns (spot inconsistent capitalization)
SELECT DISTINCT INITCAP(TRIM(styleName)) AS norm_stylename
FROM musical_styles
ORDER BY 1;

-- Trailing/leading spaces: any column example
SELECT agtlastname
FROM agents
WHERE agtlastname <> TRIM(agtlastname);

-- Phone check: length after removing non-digits
-- Expecting 10–15 digits; adjust as needed
SELECT agtphonenumber
FROM agents
WHERE LENGTH(REGEXP_REPLACE(agtphonenumber, '\D', '', 'g')) NOT BETWEEN 10 AND 15;


/* -----------------------------
   4) CORE ANALYSIS – AGENTS
   ----------------------------- */

-- Agents ranked by total “revenue handle” (sum of contractprice on their engagements)
-- Note: This is NOT platform net revenue unless platform fee is a column.
WITH ag AS (
  SELECT 
    a.agentid,
    a.agtfirstname || ' ' || a.agtlastname AS agent_name,
    a.commissionrate,
    a.salary
  FROM agents a
),
eg AS (
  SELECT agentid, engagementnumber, contractprice
  FROM engagements
  WHERE contractprice IS NOT NULL
)
SELECT 
  ag.agentid,
  ag.agent_name,
  COUNT(eg.engagementnumber)            AS engagements_handled,
  SUM(eg.contractprice)                 AS total_contractprice,
  ag.commissionrate,
  ag.salary,
  SUM(eg.contractprice) * COALESCE(ag.commissionrate,0) + COALESCE(ag.salary,0) AS comp_cost_estimate
FROM ag
LEFT JOIN eg ON ag.agentid = eg.agentid
GROUP BY ag.agentid, ag.agent_name, ag.commissionrate, ag.salary
ORDER BY total_contractprice DESC;


-- Six-month ROI view (semi-annual)
WITH last_date AS (
  SELECT MAX(startdate) AS mx FROM engagements
),
six_months_engagements AS (
  SELECT e.agentid, e.contractprice
  FROM engagements e, last_date ld
  WHERE e.startdate >= ld.mx - INTERVAL '6 months'
),
revenue_per_agent AS (
  SELECT agentid, SUM(contractprice) AS total_contractprice
  FROM six_months_engagements
  GROUP BY agentid
),
agent_financials AS (
  SELECT 
    a.agentid,
    (a.salary / 2.0) AS semi_annual_salary,
    COALESCE(SUM(sme.contractprice),0) * COALESCE(a.commissionrate,0) AS commission_earned
  FROM agents a
  LEFT JOIN six_months_engagements sme ON a.agentid = sme.agentid
  GROUP BY a.agentid, a.salary, a.commissionrate
)
SELECT 
  r.agentid,
  af.semi_annual_salary,
  af.commission_earned,
  r.total_contractprice,
  r.total_contractprice / NULLIF((af.semi_annual_salary + af.commission_earned),0) AS roi
FROM revenue_per_agent r
JOIN agent_financials af ON r.agentid = af.agentid
ORDER BY roi DESC NULLS LAST;


/* -----------------------------
   5) CORE ANALYSIS – MUSICAL STYLES
   ----------------------------- */

-- Style revenue + engagement count
SELECT 
  ms.stylename,
  COUNT(DISTINCT e.engagementnumber) AS num_engagements,
  AVG(e.contractprice)               AS avg_contractprice,
  SUM(e.contractprice)               AS total_revenue
FROM engagements e
JOIN entertainer_styles es ON e.entertainerid = es.entertainerid
JOIN musical_styles ms     ON es.styleid = ms.styleid
GROUP BY ms.stylename
ORDER BY avg_contractprice DESC;

-- Top 3 styles by total revenue (CTE used later)
WITH style_rev AS (
  SELECT 
    ms.styleid,
    ms.stylename,
    SUM(e.contractprice) AS total_revenue
  FROM engagements e
  JOIN entertainer_styles es ON e.entertainerid = es.entertainerid
  JOIN musical_styles ms     ON es.styleid = ms.styleid
  GROUP BY ms.styleid, ms.stylename
)
SELECT * FROM style_rev ORDER BY total_revenue DESC LIMIT 3;


/* -----------------------------
   6) MONTHLY TRENDING (USING CALENDAR DIM)
   ----------------------------- */

-- Revenue/Bookings by ztblMonths (assumes MonthStart/MonthEnd, MonthYear, YearNumber, MonthNumber exist)
SELECT
  zm.monthyear,
  SUM(e.contractprice)                                AS monthly_revenue,
  COUNT(DISTINCT e.customerid)                        AS unique_customers,
  COUNT(*)                                            AS total_bookings
FROM engagements e
JOIN ztblmonths zm
  ON e.startdate BETWEEN zm.monthstart AND zm.monthend
GROUP BY zm.yearnumber, zm.monthnumber, zm.monthyear
ORDER BY zm.yearnumber, zm.monthnumber;


/* -----------------------------
   7) CUSTOMERS – VALUE & BEHAVIOR
   ----------------------------- */

-- Customer revenue + hours + AOV and $/hr
-- Assumes starttime/ stoptime exist as time; if not, replace duration logic.
SELECT 
  c.customerid,
  c.custfirstname || ' ' || c.custlastname AS customer_name,
  COUNT(e.engagementnumber)                AS engagement_count,
  ROUND(SUM(EXTRACT(EPOCH FROM ((e.enddate + e.stoptime) - (e.startdate + e.starttime))) / 3600.0), 2) AS total_hours,
  SUM(e.contractprice)                     AS total_contractprice,
  ROUND(SUM(e.contractprice) / NULLIF(COUNT(e.engagementnumber),0), 2) AS avg_spend_per_engagement,
  ROUND(SUM(e.contractprice) / NULLIF(SUM(EXTRACT(EPOCH FROM ((e.enddate + e.stoptime) - (e.startdate + e.starttime))) / 3600.0),0), 2) AS avg_spend_per_hour
FROM customers c
JOIN engagements e ON c.customerid = e.customerid
GROUP BY c.customerid, customer_name
ORDER BY avg_spend_per_engagement DESC NULLS LAST;

-- Inactive customers (never booked)
SELECT c.customerid, c.custfirstname, c.custlastname
FROM customers c
LEFT JOIN engagements e ON c.customerid = e.customerid
WHERE e.customerid IS NULL
ORDER BY c.custfirstname, c.custlastname;

-- Top single-booking value per customer (max booking value)
SELECT
  c.customerid,
  c.custfirstname || ' ' || c.custlastname AS customer_name,
  MAX(e.contractprice) AS max_booking_value
FROM customers c
JOIN engagements e ON c.customerid = e.customerid
GROUP BY c.customerid, customer_name
ORDER BY max_booking_value DESC
LIMIT 10;


/* -----------------------------
   8) PREFERENCES vs ACTUAL BOOKINGS
   ----------------------------- */

-- Top 3 styles by total revenue (for reuse)
WITH style_rev AS (
  SELECT 
    ms.styleid,
    ms.stylename,
    SUM(e.contractprice) AS total_revenue
  FROM engagements e
  JOIN entertainer_styles es ON e.entertainerid = es.entertainerid
  JOIN musical_styles ms     ON es.styleid = ms.styleid
  GROUP BY ms.styleid, ms.stylename
),
Top3Styles AS (
  SELECT styleid FROM style_rev ORDER BY total_revenue DESC LIMIT 3
)
-- Customers who have NOT booked any event in top 3 styles
SELECT DISTINCT
  c.customerid,
  c.custfirstname,
  c.custlastname,
  CASE WHEN EXISTS (
         SELECT 1
         FROM musical_preferences mp
         WHERE mp.customerid = c.customerid
           AND mp.styleid IN (SELECT styleid FROM Top3Styles)
       ) THEN 'Yes' ELSE 'No' END AS has_top3_preference
FROM customers c
WHERE c.customerid NOT IN (
  SELECT DISTINCT e.customerid
  FROM engagements e
  JOIN entertainer_styles es ON e.entertainerid = es.entertainerid
  WHERE es.styleid IN (SELECT styleid FROM Top3Styles)
)
ORDER BY has_top3_preference DESC, c.custfirstname, c.custlastname;

-- Customers whose preferences don't match their bookings
SELECT
  c.customerid,
  c.custfirstname || ' ' || c.custlastname AS customer_name,
  ms.stylename
FROM customers c
JOIN musical_preferences mp ON c.customerid = mp.customerid
JOIN musical_styles ms      ON mp.styleid   = ms.styleid
WHERE NOT EXISTS (
  SELECT 1
  FROM engagements e
  JOIN entertainer_styles es ON e.entertainerid = es.entertainerid
  WHERE e.customerid = c.customerid
    AND es.styleid   = mp.styleid
);


/* -----------------------------
   9) ENTERTAINERS – REVENUE TABLE
   ----------------------------- */
SELECT 
  e.entstagename,
  COUNT(eg.engagementnumber) AS total_bookings,
  SUM(eg.contractprice)      AS total_revenue,
  AVG(eg.contractprice)      AS avg_contract_value
FROM entertainers e
JOIN engagements eg ON e.entertainerid = eg.entertainerid
GROUP BY e.entstagename
ORDER BY total_revenue DESC;
