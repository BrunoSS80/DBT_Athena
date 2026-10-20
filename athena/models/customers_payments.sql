WITH validPayments AS (
    SELECT id, orderid, paymentmethod, status, amount, created
    FROM {{ source('raw-data', 'payments_data') }}
    WHERE status = 'success'
),

validOrders AS (
    SELECT id, user_id, order_date, status
    FROM {{ source('raw-data', 'orders_data') }}
    WHERE status IN ('completed', 'shipped', 'placed')
),

validCustomers AS (
    SELECT id, CONCAT(first_name, ' ', last_name) AS name
    FROM {{ source('raw-data', 'customers_data') }}
)

    SELECT cust.id, cust.name,
            SUM(vldPay.amount) AS amount
    FROM validCustomers AS cust
    JOIN validOrders AS vldOrd
    ON cust.id = vldOrd.user_id
    JOIN validPayments AS vldPay
    ON vldOrd.id = vldPay.orderid
    GROUP BY cust.id, cust.name
    ORDER BY amount DESC
