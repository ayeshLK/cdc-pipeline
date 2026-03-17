-- AUTO-GENERATED FILE.

-- This file is an auto-generated file by Ballerina persistence layer for model.
-- Please verify the generated scripts and execute them against the target DB server.

DROP TABLE IF EXISTS `merchant_sales_summary`;

CREATE TABLE `merchant_sales_summary` (
	`id` INT AUTO_INCREMENT,
	`time_stamp` TIMESTAMP NOT NULL,
	`merchant_id` INT NOT NULL,
	`category` VARCHAR(100) NOT NULL,
	`total_revenue` DECIMAL(15,2) NOT NULL,
	`items_sold` INT NOT NULL,
	`order_count` INT NOT NULL,
	`last_updated` TIMESTAMP,
	PRIMARY KEY(`id`)
);


