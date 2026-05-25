SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

DROP SCHEMA IF EXISTS `northwind` ;
CREATE SCHEMA IF NOT EXISTS `northwind` DEFAULT CHARACTER SET latin1 ;
USE `northwind` ;

CREATE TABLE IF NOT EXISTS `northwind`.`customers` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `company` VARCHAR(50) NULL DEFAULT NULL,
  `last_name` VARCHAR(50) NULL DEFAULT NULL,
  `first_name` VARCHAR(50) NULL DEFAULT NULL,
  `email_address` VARCHAR(50) NULL DEFAULT NULL,
  `job_title` VARCHAR(50) NULL DEFAULT NULL,
  `business_phone` VARCHAR(25) NULL DEFAULT NULL,
  `home_phone` VARCHAR(25) NULL DEFAULT NULL,
  `mobile_phone` VARCHAR(25) NULL DEFAULT NULL,
  `fax_number` VARCHAR(25) NULL DEFAULT NULL,
  `address` LONGTEXT NULL DEFAULT NULL,
  `city` VARCHAR(50) NULL DEFAULT NULL,
  `state_province` VARCHAR(50) NULL DEFAULT NULL,
  `zip_postal_code` VARCHAR(15) NULL DEFAULT NULL,
  `country_region` VARCHAR(50) NULL DEFAULT NULL,
  `web_page` LONGTEXT NULL DEFAULT NULL,
  `notes` LONGTEXT NULL DEFAULT NULL,
  `attachments` LONGBLOB NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  INDEX `city` (`city` ASC),
  INDEX `company` (`company` ASC),
  INDEX `first_name` (`first_name` ASC),
  INDEX `last_name` (`last_name` ASC),
  INDEX `zip_postal_code` (`zip_postal_code` ASC),
  INDEX `state_province` (`state_province` ASC))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`employees` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `company` VARCHAR(50) NULL DEFAULT NULL,
  `last_name` VARCHAR(50) NULL DEFAULT NULL,
  `first_name` VARCHAR(50) NULL DEFAULT NULL,
  `email_address` VARCHAR(50) NULL DEFAULT NULL,
  `job_title` VARCHAR(50) NULL DEFAULT NULL,
  `business_phone` VARCHAR(25) NULL DEFAULT NULL,
  `home_phone` VARCHAR(25) NULL DEFAULT NULL,
  `mobile_phone` VARCHAR(25) NULL DEFAULT NULL,
  `fax_number` VARCHAR(25) NULL DEFAULT NULL,
  `address` LONGTEXT NULL DEFAULT NULL,
  `city` VARCHAR(50) NULL DEFAULT NULL,
  `state_province` VARCHAR(50) NULL DEFAULT NULL,
  `zip_postal_code` VARCHAR(15) NULL DEFAULT NULL,
  `country_region` VARCHAR(50) NULL DEFAULT NULL,
  `web_page` LONGTEXT NULL DEFAULT NULL,
  `notes` LONGTEXT NULL DEFAULT NULL,
  `attachments` LONGBLOB NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`privileges` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `privilege_name` VARCHAR(50) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`employee_privileges` (
  `employee_id` INT(11) NOT NULL,
  `privilege_id` INT(11) NOT NULL,
  PRIMARY KEY (`employee_id`, `privilege_id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`inventory_transaction_types` (
  `id` TINYINT(4) NOT NULL,
  `type_name` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`shippers` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `company` VARCHAR(50) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`orders_tax_status` (
  `id` TINYINT(4) NOT NULL,
  `tax_status_name` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`orders_status` (
  `id` TINYINT(4) NOT NULL,
  `status_name` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`orders` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `employee_id` INT(11) NULL DEFAULT NULL,
  `customer_id` INT(11) NULL DEFAULT NULL,
  `order_date` DATETIME NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`products` (
  `supplier_ids` LONGTEXT NULL DEFAULT NULL,
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `product_code` VARCHAR(25) NULL DEFAULT NULL,
  `product_name` VARCHAR(50) NULL DEFAULT NULL,
  `description` LONGTEXT NULL DEFAULT NULL,
  `standard_cost` DECIMAL(19,4) NULL DEFAULT '0.0000',
  `list_price` DECIMAL(19,4) NOT NULL DEFAULT '0.0000',
  `reorder_level` INT(11) NULL DEFAULT NULL,
  `target_level` INT(11) NULL DEFAULT NULL,
  `quantity_per_unit` VARCHAR(50) NULL DEFAULT NULL,
  `discontinued` TINYINT(1) NOT NULL DEFAULT '0',
  `minimum_reorder_quantity` INT(11) NULL DEFAULT NULL,
  `category` VARCHAR(50) NULL DEFAULT NULL,
  `attachments` LONGBLOB NULL DEFAULT NULL,
  `stock` DECIMAL(18,4) DEFAULT '0.0000', 
  PRIMARY KEY (`id`),
  INDEX `product_code` (`product_code` ASC))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`purchase_order_status` (
  `id` INT(11) NOT NULL,
  `status` VARCHAR(50) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`suppliers` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `company` VARCHAR(50) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`purchase_orders` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `supplier_id` INT(11) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`inventory_transactions` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `transaction_type` TINYINT(4) NOT NULL,
  `product_id` INT(11) NOT NULL,
  `quantity` INT(11) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`invoices` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `order_id` INT(11) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`order_details_status` (
  `id` INT(11) NOT NULL,
  `status_name` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`order_details` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `order_id` INT(11) NOT NULL,
  `product_id` INT(11) NULL DEFAULT NULL,
  `quantity` DECIMAL(18,4) NOT NULL DEFAULT '0.0000',
  `unit_price` DECIMAL(19,4) NULL DEFAULT '0.0000',
  `discount` DOUBLE NOT NULL DEFAULT '0',
  `status_id` INT(11) NULL DEFAULT NULL,
  `date_allocated` DATETIME NULL DEFAULT NULL,
  `purchase_order_id` INT(11) NULL DEFAULT NULL,
  `inventory_id` INT(11) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`purchase_order_details` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `purchase_order_id` INT(11) NOT NULL,
  `product_id` INT(11) NULL DEFAULT NULL,
  `quantity` DECIMAL(18,4) NOT NULL,
  `unit_cost` DECIMAL(19,4) NOT NULL,
  `date_received` DATETIME NULL DEFAULT NULL,
  `posted_to_inventory` TINYINT(1) NOT NULL DEFAULT '0',
  `inventory_id` INT(11) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`sales_reports` (
  `group_by` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`group_by`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

CREATE TABLE IF NOT EXISTS `northwind`.`strings` (
  `string_id` INT(11) NOT NULL AUTO_INCREMENT,
  `string_data` VARCHAR(255) NULL DEFAULT NULL,
  PRIMARY KEY (`string_id`))
ENGINE = InnoDB DEFAULT CHARACTER SET = utf8;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
