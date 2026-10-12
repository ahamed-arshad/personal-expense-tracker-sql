# Personal Expense Tracker: SQL Analysis

A PostgreSQL analysis of 31 days of my own spending: cleaning messy text data, validating it, and answering practical questions about where the money goes.

**👉 [Open the full notebook (queries + results)](notebooks/analysis.ipynb)**

## Questions answered
- Which items take the largest share of my spending?
- How different is spending **alone vs. with friends**?
- Which were my 5 most expensive days, and what happened on the worst one?
- Do I spend more on **weekends** than weekdays?

## Key findings
*(Replace with your real numbers from the notebook.)*

| Finding | Result |
|---|---|
| Total spend (31 days) | ₹____ across __ transactions |
| Top item | ______ (__% of spend) |
| With friends vs alone | __% vs __% of spend |
| Weekend vs weekday avg/day | ₹__ vs ₹__ |

![Spend by item](images/spend_by_item.png)
![Daily spend](images/daily_spend.png)

## Example query
```sql
-- Average daily spend, weekday vs weekend
WITH daily AS (
    SELECT expense_date,
           SUM(amount) AS daily_total,
           CASE WHEN EXTRACT(ISODOW FROM expense_date) IN (6, 7)
                THEN 'Weekend' ELSE 'Weekday' END AS day_type
    FROM expense
    GROUP BY expense_date
)
SELECT day_type, COUNT(*) AS num_days, ROUND(AVG(daily_total), 2) AS avg_daily_spend
FROM daily
GROUP BY day_type;
```

## Data cleaning highlights
- Loaded the CSV as text first, then converted `DD/MM/YYYY` dates explicitly with `TO_DATE`.
- Fixed spelling variants and stray whitespace that would split `GROUP BY` results.
- Renamed the misleading `category` column to `company` (alone / friend).
- Cross-checked the logged weekday against the real date.

## SQL concepts used
`GROUP BY` · `CASE` · CTEs · window functions (`SUM() OVER`) · `FILTER` · scalar and correlated subqueries · date functions (`TO_DATE`, `EXTRACT`, `TO_CHAR`)

## Repo structure
```
├── data/myExpenses1.csv
├── sql/expense_tracker.sql      # full script for pgAdmin / psql
├── notebooks/analysis.ipynb     # queries + saved results
├── images/                      # charts used above
└── requirements.txt
```

## How to reproduce
1. Create a database: `CREATE DATABASE expense_tracker;`
2. `pip install -r requirements.txt`
3. Open `notebooks/analysis.ipynb`, run all cells, enter your Postgres password when asked.

## Author
Ahmed Arhsad
