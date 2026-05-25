USE `northwind`;

DELIMITER //

CREATE PROCEDURE `sp_pesan_ulang_otomatis`()
BEGIN
    -- 1. Deklarasi variabel untuk menyimpan data sementara dari kursor
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_product_id INT;
    DECLARE v_supplier_id INT;
    DECLARE v_qty_to_order INT;
    DECLARE v_unit_cost DECIMAL(19,4);
    DECLARE v_po_id INT;

    -- 2. Deklarasi Kursor: Mencari produk yang stoknya <= reorder_level
    -- Memastikan produk belum discontinued (berhenti dijual)
    DECLARE cur_products CURSOR FOR
        SELECT 
            id, 
            CAST(supplier_ids AS UNSIGNED),
            minimum_reorder_quantity, 
            standard_cost
        FROM `products`
        WHERE `stock` <= `reorder_level` AND `discontinued` = 0;

    -- 3. Deklarasi Handler: Menghentikan loop jika semua baris sudah dibaca
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- 4. Buka Kursor
    OPEN cur_products;

    -- 5. Mulai Looping
    read_loop: LOOP
        -- Ambil data per baris dan masukkan ke variabel
        FETCH cur_products INTO v_product_id, v_supplier_id, v_qty_to_order, v_unit_cost;

        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Jika minimum_reorder_quantity kosong/NULL, tetapkan nilai default 10
        IF v_qty_to_order IS NULL THEN
            SET v_qty_to_order = 10;
        END IF;

        -- Buat Purchase Order baru untuk supplier terkait
        INSERT INTO `purchase_orders` (`supplier_id`)
        VALUES (v_supplier_id);

        -- Dapatkan ID dari Purchase Order yang baru saja digenerate (AUTO_INCREMENT)
        SET v_po_id = LAST_INSERT_ID();

        -- Masukkan detail produk yang dipesan ulang ke dalam Purchase Order Details
        INSERT INTO `purchase_order_details` (`purchase_order_id`, `product_id`, `quantity`, `unit_cost`)
        VALUES (v_po_id, v_product_id, v_qty_to_order, v_unit_cost);

    END LOOP;

    -- 6. Tutup Kursor
    CLOSE cur_products;
END //

DELIMITER ;

-- Test Prosedur
-- 1. Insert Supplier baru
INSERT INTO `suppliers` (`id`, `company`) VALUES (2, 'PT Pemasok Sukses');

-- 2. Insert Produk baru dengan kondisi stok (5) di bawah reorder_level (10)
INSERT INTO `products` (`id`, `product_name`, `list_price`, `stock`, `supplier_ids`, `reorder_level`, `minimum_reorder_quantity`, `standard_cost`, `discontinued`) 
VALUES (2, 'Biskuit Cokelat', 20000, 5, '2', 10, 50, 12000, 0);

-- 3. Cek kondisi tabel sebelum Procedure dipanggil
SELECT 'Sebelum SP' AS Status, id, product_name, stock, reorder_level FROM `products` WHERE id = 2;

-- 4. Panggil Procedure otomatisasinya
CALL sp_pesan_ulang_otomatis();

-- 5. Cek kondisi produk setelah Procedure dipanggil
SELECT 
    'Setelah SP' AS Status, 
    po.id AS purchase_order_id, 
    pod.product_id,
    pod.unit_cost AS harga,
    pod.quantity AS kuantitas_dipesan,
    p.stock AS stok_terbaru
FROM `purchase_orders` po
JOIN `purchase_order_details` pod ON po.id = pod.purchase_order_id
JOIN `products` p ON pod.product_id = p.id
WHERE p.id = 2;