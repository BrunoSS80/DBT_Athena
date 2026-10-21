WITH validPayments AS (
    SELECT *
    FROM {{ ref('stg_payments') }}
    WHERE status = 'success'
),

validOrders AS (
    SELECT *
    FROM {{ ref('stg_orders') }}
    WHERE status IN ('completed', 'shipped', 'placed')
),

validCustomers AS (
    SELECT customer_id, CONCAT(first_name, ' ', last_name) AS name
    FROM {{ ref('stg_customers') }}
)

SELECT 
    cust.customer_id, 
    cust.name,
    SUM(vldPay.amount) AS amount
FROM validCustomers AS cust
JOIN validOrders AS vldOrd
ON cust.customer_id = vldOrd.customer_id
JOIN validPayments AS vldPay
ON vldOrd.order_id = vldPay.order_id
GROUP BY cust.customer_id, cust.name
ORDER BY amount DESC;