USE `northwind`;

-- 1. Trigger untuk mengurangi stok saat pesanan masuk dari pelanggan
DELIMITER //
CREATE TRIGGER `trg_kurangi_stok`
AFTER INSERT ON `order_details`
FOR EACH ROW
BEGIN
    UPDATE `products`
    SET `stock` = `stock` - NEW.quantity
    WHERE `id` = NEW.product_id;
END //
DELIMITER ;

-- 2. Trigger untuk menambah stok saat barang dari pemasok tiba
DELIMITER //
CREATE TRIGGER `trg_tambah_stok`
AFTER INSERT ON `purchase_order_details`
FOR EACH ROW
BEGIN
    UPDATE `products`
    SET `stock` = `stock` + NEW.quantity
    WHERE `id` = NEW.product_id;
END //
DELIMITER ;

-- Test 1
INSERT INTO `products` (`id`, `product_name`, `list_price`, `stock`) VALUES (1, 'Sirup Minuman', 15000, 50);
INSERT INTO `orders` (`id`, `order_date`) VALUES (1, NOW());
INSERT INTO `purchase_orders` (`id`) VALUES (1);
SELECT id, product_name, stock FROM `products` WHERE id = 1;

-- Test 2: Pelanggan memesan
INSERT INTO `order_details` (`order_id`, `product_id`, `quantity`, `unit_price`) VALUES (1, 1, 10, 15000);
SELECT id, product_name, stock FROM `products` WHERE id = 1;

-- Test 3: Stock ditambah
INSERT INTO `purchase_order_details` (`purchase_order_id`, `product_id`, `quantity`, `unit_cost`) VALUES (1, 1, 30, 10000);
SELECT id, product_name, stock FROM `products` WHERE id = 1;




