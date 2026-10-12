-- Personal Expense Tracker: full SQL script
-- Author: Ahmed Arhsad | PostgreSQL 16
-- Run in pgAdmin Query Tool or psql, connected to the `expense_tracker` database.
-- (The notebook in /notebooks runs the same queries and shows the results.)

-- Staging table: everything as TEXT; dates are converted explicitly later.
DROP TABLE IF EXISTS expense_raw CASCADE;
CREATE TABLE expense_raw (
    expense_date TEXT,
    item         TEXT,
    amount       TEXT,
    category     TEXT,
    expense_time TEXT,
    expense_day  TEXT
);

-- Load from psql (client-side, avoids server file-permission errors):
-- \copy expense_raw FROM 'data/myExpenses1.csv' WITH (FORMAT csv, HEADER true)

-- 2.1 Clean text columns in staging table
UPDATE expense_raw
SET item = CASE
        WHEN item ILIKE '%riksow%'  THEN 'rikshaw'
        WHEN item ILIKE '%chiness%' THEN 'chinese bhel'
        WHEN item ILIKE '%snaks%'   THEN 'chai with snacks'
        WHEN item ILIKE '%choclate%' THEN 'chocolate'
        ELSE LOWER(TRIM(item))
    END,
    category = LOWER(TRIM(category));

-- 2.2 Create typed table with explicit date conversion
DROP TABLE IF EXISTS expense;

CREATE TABLE expense AS
SELECT TO_DATE(expense_date, 'DD/MM/YYYY') AS expense_date,
       item,
       amount::NUMERIC(10,2)               AS amount,
       category                            AS company,
       expense_time,
       expense_day
FROM expense_raw;

-- Preview
SELECT * FROM expense ORDER BY expense_date, expense_time LIMIT 10;

-- 3.1 Row count and date range
SELECT COUNT(*)                                   AS total_rows,
       MIN(expense_date)                          AS first_day,
       MAX(expense_date)                          AS last_day,
       MAX(expense_date) - MIN(expense_date) + 1  AS days_covered
FROM expense;

-- 3.2 NULL check and weekday cross-check
SELECT COUNT(*) FILTER (WHERE amount IS NULL)  AS null_amounts,
       COUNT(*) FILTER (
           WHERE LEFT(LOWER(TRIM(expense_day)), 3) <> LOWER(TO_CHAR(expense_date, 'Dy'))
       )                                       AS weekday_mismatches
FROM expense;

-- 3.3 Distinct items (confirms the cleaning worked)
SELECT item, COUNT(*) AS rows
FROM expense
GROUP BY item
ORDER BY item;

-- 4.1 Spend by item
SELECT item,
       COUNT(*)                                             AS purchases,
       SUM(amount)                                          AS total_spent,
       ROUND(AVG(amount), 2)                                AS avg_per_purchase,
       ROUND(100.0 * SUM(amount) / SUM(SUM(amount)) OVER (), 1) AS pct_of_total
FROM expense
GROUP BY item
ORDER BY total_spent DESC;

-- 4.2 Spend by company
SELECT company,
       COUNT(*)                                                 AS purchases,
       SUM(amount)                                              AS total_spent,
       ROUND(AVG(amount), 2)                                    AS avg_per_purchase,
       ROUND(100.0 * SUM(amount) / SUM(SUM(amount)) OVER (), 1) AS pct_of_total
FROM expense
GROUP BY company
ORDER BY total_spent DESC;

-- 4.3 Monthly totals
SELECT SUM(amount)            AS monthly_total,
       COUNT(*)               AS transactions,
       ROUND(AVG(amount), 2)  AS avg_transaction,
       ROUND(SUM(amount) / COUNT(DISTINCT expense_date), 2) AS avg_per_day
FROM expense;

-- 5.1 Top 5 days by total spend
SELECT expense_date,
       TO_CHAR(expense_date, 'Dy') AS weekday,
       SUM(amount)                 AS daily_total,
       COUNT(*)                    AS transactions
FROM expense
GROUP BY expense_date
ORDER BY daily_total DESC
LIMIT 5;

-- 5.2 Drill-down on the top day
WITH top_day AS (
    SELECT expense_date
    FROM expense
    GROUP BY expense_date
    ORDER BY SUM(amount) DESC
    LIMIT 1
)
SELECT e.expense_date, e.expense_time, e.item, e.amount, e.company
FROM expense e
JOIN top_day t USING (expense_date)
ORDER BY e.amount DESC;

-- 6.1 Average daily spend, weekday vs weekend
WITH daily AS (
    SELECT expense_date,
           SUM(amount) AS daily_total,
           CASE WHEN EXTRACT(ISODOW FROM expense_date) IN (6, 7)
                THEN 'Weekend' ELSE 'Weekday' END AS day_type
    FROM expense
    GROUP BY expense_date
)
SELECT day_type,
       COUNT(*)                   AS num_days,
       ROUND(AVG(daily_total), 2) AS avg_daily_spend,
       SUM(daily_total)           AS total_spend
FROM daily
GROUP BY day_type
ORDER BY avg_daily_spend DESC;

-- 7.1 Cumulative spend by day
SELECT expense_date,
       SUM(amount)                                      AS daily_total,
       SUM(SUM(amount)) OVER (ORDER BY expense_date)    AS running_total
FROM expense
GROUP BY expense_date
ORDER BY expense_date;

-- 7.2 Item mix by company
SELECT item,
       COUNT(*) FILTER (WHERE company = 'alone')  AS times_alone,
       COUNT(*) FILTER (WHERE company = 'friend') AS times_with_friend,
       COALESCE(SUM(amount) FILTER (WHERE company = 'alone'), 0)  AS spent_alone,
       COALESCE(SUM(amount) FILTER (WHERE company = 'friend'), 0) AS spent_with_friend
FROM expense
GROUP BY item
ORDER BY times_alone + times_with_friend DESC;

-- 7.3 Chai stats
SELECT COUNT(*)                       AS chai_purchases,
       SUM(amount)                    AS chai_total,
       ROUND(AVG(amount), 2)          AS avg_price,
       COUNT(DISTINCT expense_date)   AS days_with_chai
FROM expense
WHERE item ILIKE 'chai%';
