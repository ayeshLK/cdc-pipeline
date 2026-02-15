CREATE TABLE analytics_db.merchant_sales_summary (
    id INT NOT NULL auto_increment PRIMARY KEY,
    time_stamp TIMESTAMP NOT NULL,
    merchant_id BIGINT NOT NULL,
    category VARCHAR(100) NOT NULL,
    total_revenue DECIMAL(15,2) NOT NULL,
    items_sold BIGINT NOT NULL,
    order_count BIGINT NOT NULL,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
