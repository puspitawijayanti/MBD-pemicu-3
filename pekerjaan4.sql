USE `nortwind`;

-- =========================
-- TABEL: diskon_log
-- =========================

CREATE TABLE IF NOT EXISTS diskon_log (
    id               INT            NOT NULL AUTO_INCREMENT,
    supplier_id      INT            NOT NULL,
    order_id         INT            NOT NULL,
    order_detail_id  INT            NOT NULL,
    product_id       INT            NOT NULL,
    diskon_lama      DECIMAL(4,2)   NOT NULL DEFAULT 0.00,
    diskon_baru      DECIMAL(4,2)   NOT NULL,
    unit_price       DECIMAL(19,4)  NOT NULL,
    quantity         INT            NOT NULL,
    waktu_diterapkan DATETIME       DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_supplier (supplier_id),
    INDEX idx_order    (order_id),
    INDEX idx_waktu    (waktu_diterapkan)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- ===========================================================
-- FUNCTION: fn_hitung_total_setelah_diskon
-- ===========================================================

DROP FUNCTION IF EXISTS fn_hitung_total_setelah_diskon;

DELIMITER $$

CREATE FUNCTION fn_hitung_total_setelah_diskon(p_order_id INT)
RETURNS DECIMAL(19,4)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(19,4) DEFAULT 0;

    SELECT SUM(od.unit_price * od.quantity * (1 - IFNULL(od.discount, 0)))
      INTO v_total
      FROM order_details od
     WHERE od.order_id = p_order_id;

    RETURN IFNULL(v_total, 0);
END $$

DELIMITER ;

-- ===========================================================
-- STORED PROCEDURE: sp_terapkan_diskon_massal
-- ===========================================================

DROP PROCEDURE IF EXISTS sp_terapkan_diskon_massal;

DELIMITER $$

CREATE PROCEDURE sp_terapkan_diskon_massal(
    IN  p_supplier_id     INT,
    IN  p_persen_diskon   DECIMAL(5,2),
    IN  p_tanggal_mulai   DATE,
    IN  p_tanggal_selesai DATE,
    IN  p_mode            VARCHAR(10)
)
BEGIN
    DECLARE v_order_detail_id   INT;
    DECLARE v_order_id          INT;
    DECLARE v_product_id        INT;
    DECLARE v_unit_price        DECIMAL(19,4);
    DECLARE v_quantity          INT;
    DECLARE v_diskon_lama       DECIMAL(4,2);
    DECLARE v_diskon_baru       DECIMAL(4,2);
    DECLARE v_selesai           BOOLEAN       DEFAULT FALSE;
    DECLARE v_jumlah_diupdate   INT           DEFAULT 0;
    DECLARE v_total_penghematan DECIMAL(19,4) DEFAULT 0;
    DECLARE v_nama_supplier     VARCHAR(100)  DEFAULT NULL;
    DECLARE v_tgl_mulai         DATE;
    DECLARE v_tgl_selesai       DATE;
    DECLARE v_diskon_desimal    DECIMAL(4,2);

    -- Kursor: ambil semua order_details produk dari supplier target dalam rentang tanggal
    DECLARE cur_detail CURSOR FOR
        SELECT  od.id,
                od.order_id,
                od.product_id,
                od.unit_price,
                od.quantity,
                -- Discount disimpan sebagai fraksi desimal (contoh: 0.10 = 10%)
                IFNULL(od.discount, 0)
          FROM  order_details od
          JOIN  products      p  ON p.id  = od.product_id
          JOIN  orders        o  ON o.id  = od.order_id
         WHERE  p.supplier_id = p_supplier_id
           AND  DATE(o.order_date) >= v_tgl_mulai
           AND  DATE(o.order_date) <= v_tgl_selesai;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_selesai = TRUE;

    -- VALIDASI INPUT

    -- 1. Cek supplier
    SELECT company
      INTO v_nama_supplier
      FROM suppliers
     WHERE id = p_supplier_id
     LIMIT 1;

    IF v_nama_supplier IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERROR: Supplier tidak ditemukan.';
    END IF;

    -- 2. Validasi diskon (1% - 100%)
    IF p_persen_diskon <= 0 OR p_persen_diskon > 100 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERROR: Persentase diskon harus antara 1 dan 100.';
    END IF;

    -- 3. Normalisasi tanggal
    SET v_tgl_mulai   = IFNULL(p_tanggal_mulai,   '1900-01-01');
    SET v_tgl_selesai = IFNULL(p_tanggal_selesai, CURDATE());

    IF v_tgl_mulai > v_tgl_selesai THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERROR: Tanggal mulai tidak boleh melebihi tanggal selesai.';
    END IF;

    -- 4. Normalisasi mode
    SET p_mode = UPPER(TRIM(p_mode));
    IF p_mode NOT IN ('APPLY', 'PREVIEW') THEN
        SET p_mode = 'PREVIEW';
    END IF;

    -- 5. Konversi persen ke desimal
    --    Contoh: 20% -> 0.20
    SET v_diskon_desimal = p_persen_diskon / 100;

    -- ----------------------------------------------------------
    -- MODE PREVIEW
    -- ----------------------------------------------------------
    IF p_mode = 'PREVIEW' THEN

        SELECT  s.company                                           AS pemasok,
                p.product_name                                      AS produk,
                o.id                                                AS order_id,
                DATE(o.order_date)                                  AS tanggal_order,
                od.unit_price                                       AS harga_satuan,
                od.quantity                                         AS kuantitas,
                ROUND(IFNULL(od.discount,0) * 100, 2)              AS diskon_lama_pct,
                ROUND(LEAST(IFNULL(od.discount,0)
                      + v_diskon_desimal, 1.00) * 100, 2)          AS diskon_baru_pct,
                ROUND(od.unit_price * od.quantity
                      * v_diskon_desimal, 4)                        AS estimasi_penghematan
          FROM  order_details od
          JOIN  products      p  ON p.id  = od.product_id
          JOIN  orders        o  ON o.id  = od.order_id
          JOIN  suppliers     s  ON s.id  = p.supplier_id
         WHERE  p.supplier_id = p_supplier_id
           AND  DATE(o.order_date) >= v_tgl_mulai
           AND  DATE(o.order_date) <= v_tgl_selesai
         ORDER  BY o.order_date, o.id, od.id;

        -- Ringkasan
        SELECT  CONCAT('[PREVIEW] Supplier: ', v_nama_supplier)     AS keterangan,
                CONCAT(p_persen_diskon, '%')                        AS diskon_akan_diterapkan,
                COUNT(od.id)                                        AS jumlah_baris_terdampak,
                ROUND(SUM(od.unit_price * od.quantity
                      * v_diskon_desimal), 4)                       AS estimasi_total_penghematan
          FROM  order_details od
          JOIN  products      p  ON p.id = od.product_id
          JOIN  orders        o  ON o.id = od.order_id
         WHERE  p.supplier_id = p_supplier_id
           AND  DATE(o.order_date) >= v_tgl_mulai
           AND  DATE(o.order_date) <= v_tgl_selesai;

    -- ----------------------------------------------------------
    -- MODE APPLY
    -- ----------------------------------------------------------
    ELSE

        START TRANSACTION;

        OPEN cur_detail;

        loop_diskon: LOOP
            FETCH cur_detail
             INTO v_order_detail_id,
                  v_order_id,
                  v_product_id,
                  v_unit_price,
                  v_quantity,
                  v_diskon_lama;

            IF v_selesai THEN
                LEAVE loop_diskon;
            END IF;

            -- Akumulasi diskon, tidak boleh > 100% (1.00)
            SET v_diskon_baru = LEAST(v_diskon_lama + v_diskon_desimal, 1.00);

            UPDATE order_details
               SET discount = v_diskon_baru
             WHERE id = v_order_detail_id;

            INSERT INTO diskon_log (
                supplier_id,
                order_id,
                order_detail_id,
                product_id,
                diskon_lama,
                diskon_baru,
                unit_price,
                quantity
            ) VALUES (
                p_supplier_id,
                v_order_id,
                v_order_detail_id,
                v_product_id,
                v_diskon_lama,
                v_diskon_baru,
                v_unit_price,
                v_quantity
            );

            SET v_jumlah_diupdate    = v_jumlah_diupdate + 1;
            SET v_total_penghematan  = v_total_penghematan
                                     + (v_unit_price * v_quantity * v_diskon_desimal);
        END LOOP loop_diskon;

        CLOSE cur_detail;

        COMMIT;

        SELECT  'BERHASIL DITERAPKAN'                AS status,
                v_nama_supplier                      AS pemasok,
                CONCAT(p_persen_diskon, '%')         AS diskon_diterapkan,
                v_tgl_mulai                          AS periode_mulai,
                v_tgl_selesai                        AS periode_selesai,
                v_jumlah_diupdate                    AS jumlah_baris_diupdate,
                ROUND(v_total_penghematan, 4)        AS total_penghematan,
                NOW()                                AS waktu_eksekusi;

    END IF;

END $$

DELIMITER ;

-- ===========================================================
-- STORED PROCEDURE: sp_batalkan_diskon_supplier
-- ===========================================================

DROP PROCEDURE IF EXISTS sp_batalkan_diskon_supplier;

DELIMITER $$

CREATE PROCEDURE sp_batalkan_diskon_supplier(
    IN p_supplier_id INT
)
BEGIN
    DECLARE v_nama_supplier    VARCHAR(100) DEFAULT NULL;
    DECLARE v_sesi_waktu       DATETIME;
    DECLARE v_jumlah_batal     INT DEFAULT 0;

    -- Cek supplier
    SELECT company INTO v_nama_supplier
      FROM suppliers WHERE id = p_supplier_id LIMIT 1;

    IF v_nama_supplier IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERROR: Supplier tidak ditemukan.';
    END IF;

    -- Ambil timestamp sesi diskon paling terakhir
    SELECT MAX(waktu_diterapkan) INTO v_sesi_waktu
      FROM diskon_log
     WHERE supplier_id = p_supplier_id;

    IF v_sesi_waktu IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'ERROR: Tidak ada catatan diskon untuk dibatalkan.';
    END IF;

    START TRANSACTION;

    -- Kembalikan nilai diskon ke sebelum sesi terakhir
    UPDATE order_details od
      JOIN diskon_log dl ON dl.order_detail_id = od.id
       SET od.discount = dl.diskon_lama
     WHERE dl.supplier_id = p_supplier_id
       AND dl.waktu_diterapkan = v_sesi_waktu;

    SET v_jumlah_batal = ROW_COUNT();

    -- Hapus log sesi terakhir
    DELETE FROM diskon_log
     WHERE supplier_id = p_supplier_id
       AND waktu_diterapkan = v_sesi_waktu;

    COMMIT;

    SELECT  'DISKON BERHASIL DIBATALKAN'    AS status,
            v_nama_supplier                 AS pemasok,
            v_jumlah_batal                  AS jumlah_baris_dikembalikan,
            NOW()                           AS waktu_rollback;

END $$

DELIMITER ;

-- ===========================================================
-- WRAPPER: sp_diskon_otomatis_semua_supplier
-- ===========================================================

DROP PROCEDURE IF EXISTS sp_diskon_otomatis_semua_supplier;

DELIMITER $$

CREATE PROCEDURE sp_diskon_otomatis_semua_supplier()
BEGIN
    DECLARE v_done    BOOLEAN DEFAULT FALSE;
    DECLARE v_sid     INT;

    DECLARE cur_sup CURSOR FOR
        SELECT DISTINCT p.supplier_id
          FROM products p
         WHERE p.discontinued = 0
           AND p.supplier_id IS NOT NULL;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    OPEN cur_sup;

    lp_sup: LOOP
        FETCH cur_sup INTO v_sid;
        IF v_done THEN LEAVE lp_sup; END IF;

        CALL sp_terapkan_diskon_massal(
            v_sid,
            5.00,
            DATE_SUB(CURDATE(), INTERVAL 7 DAY),
            CURDATE(),
            'APPLY'
        );
    END LOOP lp_sup;

    CLOSE cur_sup;
END $$

DELIMITER ;

-- ===========================================================
-- EVENT: evt_diskon_mingguan
-- ===========================================================

SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS evt_diskon_mingguan;

DELIMITER $$

CREATE EVENT evt_diskon_mingguan
    ON SCHEDULE EVERY 1 WEEK
    STARTS '2026-06-02 00:00:00'
    DO
        CALL sp_diskon_otomatis_semua_supplier() $$

DELIMITER ;

-- ===========================================================
-- BAGIAN 7: PENGUJIAN (TESTING)
-- ===========================================================

-- Data sudah tersedia:
--   Supplier 1 (Supplier Utama)
--   Product 1 (Sirup Minuman, supplier_id=1)
--   Order 1 (tgl hari ini)
--   Order Detail 1 (order_id=1, product_id=1, qty=10, discount=0.00)
--   Order 2 (tgl hari ini)
--   Order Detail 2 (order_id=2, product_id=1, qty=5, discount=0.10)

-- ---- 7a. Cek data produk dan supplier sebelum pengujian -----
SELECT  s.id          AS supplier_id,
        s.company     AS nama_supplier,
        p.id          AS product_id,
        p.product_name,
        p.list_price,
        p.stock
  FROM  suppliers s
  JOIN  products  p ON p.supplier_id = s.id
 ORDER  BY s.id, p.id;

-- ---- 7b. Cek nilai diskon awal pada order_details -----------
SELECT  od.id         AS order_detail_id,
        od.order_id,
        p.product_name,
        od.unit_price,
        od.quantity,
        od.discount   AS diskon_sebelum
  FROM  order_details od
  JOIN  products      p ON p.id = od.product_id
 WHERE  p.supplier_id = 1
 LIMIT  20;

-- ---- 7c. PREVIEW sebelum menerapkan diskon ------------------
CALL sp_terapkan_diskon_massal(
    1,              -- supplier_id = 1 (Supplier Utama, sudah ada)
    20.00,          -- diskon 20%
    '2026-01-01',   -- tanggal mulai
    '2026-12-31',   -- tanggal selesai
    'PREVIEW'       -- mode preview
);

-- ---- 7d. Terapkan diskon secara nyata (APPLY) --------------
CALL sp_terapkan_diskon_massal(
    1,
    20.00,
    '2026-01-01',
    '2026-12-31',
    'APPLY'
);

-- ---- 7e. Verifikasi perubahan diskon setelah APPLY ---------
SELECT  od.id         AS order_detail_id,
        od.order_id,
        p.product_name,
        od.unit_price,
        od.quantity,
        od.discount   AS diskon_sesudah
  FROM  order_details od
  JOIN  products      p ON p.id = od.product_id
 WHERE  p.supplier_id = 1
 LIMIT  20;

-- ---- 7f. Cek isi tabel audit diskon_log --------------------
SELECT  dl.id,
        s.company      AS pemasok,
        dl.order_id,
        p.product_name,
        dl.diskon_lama,
        dl.diskon_baru,
        ROUND(dl.unit_price * dl.quantity * (dl.diskon_baru - dl.diskon_lama), 4)
                       AS penghematan,
        dl.waktu_diterapkan
  FROM  diskon_log     dl
  JOIN  suppliers      s  ON s.id  = dl.supplier_id
  JOIN  products       p  ON p.id  = dl.product_id
 ORDER  BY dl.id DESC
 LIMIT  20;

-- ---- 7g. Laporan total penghematan per supplier ------------
SELECT  s.company                        AS pemasok,
        COUNT(dl.id)                     AS jumlah_item_didiskon,
        ROUND(SUM(
            dl.unit_price * dl.quantity
            * (dl.diskon_baru - dl.diskon_lama)
        ), 2)                            AS total_penghematan,
        MIN(dl.waktu_diterapkan)         AS pertama_kali,
        MAX(dl.waktu_diterapkan)         AS terakhir_kali
  FROM  diskon_log dl
  JOIN  suppliers  s ON s.id = dl.supplier_id
 GROUP  BY dl.supplier_id, s.company
 ORDER  BY total_penghematan DESC;

-- ---- 7h. Total bayar per order menggunakan function --------
SELECT  id AS order_id,
        fn_hitung_total_setelah_diskon(id) AS total_bayar_setelah_diskon
  FROM  orders
 ORDER  BY id
 LIMIT  10;

-- ---- 7i. Rollback diskon supplier 1 ------------------------
CALL sp_batalkan_diskon_supplier(1);

-- Verifikasi rollback: diskon kembali ke nilai semula
SELECT  od.id,
        od.discount AS diskon_setelah_rollback
  FROM  order_details od
  JOIN  products      p ON p.id = od.product_id
 WHERE  p.supplier_id = 1
 LIMIT  10;
