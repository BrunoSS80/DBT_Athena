WITH year_month AS(
    SELECT id, MONTH(order_date) AS month,
    YEAR(order_date) AS year, status
    FROM {{ source('raw-data', 'orders_data')}}
)

SELECT month, year,
COUNT(month) AS countSales
FROM year_month
GROUP BY month, year
ORDER BY countSales DESC;