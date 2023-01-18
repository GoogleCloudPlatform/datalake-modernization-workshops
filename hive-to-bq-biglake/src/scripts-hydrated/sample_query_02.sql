-- HIVE script with a dummy query 02
USE google;
SELECT CAST(delivery_time AS DATE) AS delivery_date,distribution_center_id,product_id, quantity_to_delivery,SUM(quantity_to_delivery) OVER (PARTITION BY distribution_center_id, product_id ORDER BY delivery_time)   FROM product_deliveries_hive WHERE quantity_to_delivery > 0;