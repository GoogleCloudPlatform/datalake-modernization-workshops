-- HIVE script with a dummy query 01
USE google;
select sum(quantity_to_delivery) from product_deliveries_hive group by product_id;