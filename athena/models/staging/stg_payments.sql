SELECT 
    id,
    orderid AS order_id,
    paymentmethod AS payment_method,
    status,
    amount,
    created
FROM {{ source('raw-data', 'payments_data') }}