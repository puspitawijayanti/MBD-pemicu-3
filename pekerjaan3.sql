USE `northwind`;

-- Function untuk menghasilkan laporan penjualan otomatis
DELIMITER //
CREATE FUNCTION `fn_laporan_penjualan`(periode VARCHAR(20))
RETURNS DECIMAL(19,4)

DETERMINISTIC
BEGIN
    DECLARE total_penjualan DECIMAL(19,4);

    -- 1. Laporan Harian
    IF periode = 'harian' THEN
        SELECT 
            SUM((od.quantity * od.unit_price) - od.discount)
        INTO total_penjualan
        FROM `orders` o
        JOIN `order_details` od 
            ON o.id = od.order_id
        WHERE DATE(o.order_date) = CURDATE();

    -- 2. Laporan Mingguan
    ELSEIF periode = 'mingguan' THEN
        SELECT 
            SUM((od.quantity * od.unit_price) - od.discount)
        INTO total_penjualan
        FROM `orders` o
        JOIN `order_details` od 
            ON o.id = od.order_id
        WHERE YEARWEEK(o.order_date, 1) = YEARWEEK(CURDATE(), 1);

    -- 3. Laporan Bulanan
    ELSEIF periode = 'bulanan' THEN
        SELECT 
            SUM((od.quantity * od.unit_price) - od.discount)
        INTO total_penjualan
        FROM `orders` o
        JOIN `order_details` od 
            ON o.id = od.order_id
        WHERE MONTH(o.order_date) = MONTH(CURDATE())
        AND YEAR(o.order_date) = YEAR(CURDATE());

    END IF;
    RETURN IFNULL(total_penjualan, 0);
END //
DELIMITER ;

-- Test Function
-- Test 1: Tambah data order baru
INSERT INTO `orders` (`id`, `order_date`) 
VALUES (2, NOW());

-- Test 2: Tambah detail penjualan
INSERT INTO `order_details`
(`order_id`, `product_id`, `quantity`, `unit_price`, `discount`)
VALUES
(2, 1, 5, 15000, 1000);

-- Test 3: Laporan Harian
SELECT 
    'Laporan Harian' AS jenis_laporan,
    fn_laporan_penjualan('harian') AS total_penjualan;

-- Test 4: Laporan Mingguan
SELECT 
    'Laporan Mingguan' AS jenis_laporan,
    fn_laporan_penjualan('mingguan') AS total_penjualan;

-- Test 5: Laporan Bulanan
SELECT 
    'Laporan Bulanan' AS jenis_laporan,
    fn_laporan_penjualan('bulanan') AS total_penjualan;
