WITH year_month AS(
    SELECT 
        order_id, 
        MONTH(order_date) AS month,
        YEAR(order_date) AS year, 
        status
    FROM {{ ref('stg_orders')}}
)

SELECT 
    month, 
    year,
    COUNT(month) AS countSales
FROM year_month
GROUP BY month, year
ORDER BY countSales DESC;