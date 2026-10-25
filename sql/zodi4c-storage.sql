-- ============================================================
-- zodi4c-storage - Database schema
-- Engine: MySQL / MariaDB (InnoDB, utf8mb4)
-- ============================================================

-- Stores one row per storage.
CREATE TABLE IF NOT EXISTS `zodi4c_storages` (
    `id`         INT AUTO_INCREMENT PRIMARY KEY,
    `owner`      VARCHAR(50)  COLLATE utf8mb4_unicode_ci NOT NULL, -- Owner citizenid
    `name`       VARCHAR(100) NOT NULL,                            -- Storage name
    `image`      LONGTEXT,                                         -- Image URL or data URI
    `slots`      INT          DEFAULT 50,                          -- Slot capacity
    `weight`     INT          DEFAULT 100000,                      -- Weight capacity in grams
    `password`   VARCHAR(255) DEFAULT NULL,                        -- Optional password
    `created_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX `idx_owner`      (`owner`),
    INDEX `idx_created_at` (`created_at`)
);

-- ============================================================
-- Stores the players that have joined a storage.
-- The owner is not listed here; only invited members are.
-- ============================================================
CREATE TABLE IF NOT EXISTS `zodi4c_storage_members` (
    `storage_id` INT         NOT NULL,                              -- Storage reference
    `citizenid`  VARCHAR(50) COLLATE utf8mb4_unicode_ci NOT NULL,   -- Member citizenid
    `name`       VARCHAR(100) NOT NULL,                             -- Cached character name
    `joined_at`  TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (`storage_id`, `citizenid`),                        -- One row per member
    INDEX `idx_member_citizen` (`citizenid`),

    FOREIGN KEY (`storage_id`) REFERENCES `zodi4c_storages`(`id`)
        ON DELETE CASCADE
);

-- ============================================================
-- Optional helper views
-- ============================================================

-- Every storage with its owner and password state.
-- Usage: SELECT * FROM zodi4c_storage_overview;
CREATE OR REPLACE VIEW `zodi4c_storage_overview` AS
    SELECT
        s.id,
        s.name          AS storage_name,
        s.owner         AS owner_citizenid,
        s.slots,
        ROUND(s.weight / 1000, 1) AS weight_kg,
        s.created_at,
        s.updated_at,
        (s.password IS NOT NULL AND s.password != '') AS has_password
    FROM `zodi4c_storages` s
    ORDER BY s.created_at DESC;

-- Which player belongs to which storage (owners included).
-- Usage: SELECT * FROM zodi4c_storage_memberships WHERE citizenid = 'abc123';
CREATE OR REPLACE VIEW `zodi4c_storage_memberships` AS
    SELECT
        s.id            AS storage_id,
        s.name          AS storage_name,
        s.owner         AS citizenid,
        'owner'         AS role,
        s.created_at    AS joined_at
    FROM `zodi4c_storages` s

    UNION ALL

    SELECT
        m.storage_id,
        s.name          AS storage_name,
        m.citizenid,
        'member'        AS role,
        m.joined_at
    FROM `zodi4c_storage_members` m
    INNER JOIN `zodi4c_storages` s ON s.id = m.storage_id
    ORDER BY storage_id, role;

-- Administrative view: which items are stored where.
-- Usage: SELECT * FROM zodi4c_storage_inventory_details;
CREATE OR REPLACE VIEW `zodi4c_storage_inventory_details` AS
    SELECT
        s.id AS storage_id,
        s.name AS storage_name,
        s.owner AS owner_citizenid,
        CONCAT('zodi4c_storage_', s.id) AS ox_inventory_name,
        inv.data AS items_json
    FROM `zodi4c_storages` s
    LEFT JOIN `ox_inventory` inv ON inv.name = CONCAT('zodi4c_storage_', s.id);

-- ============================================================
-- Activity log: who took or stored what, and when.
-- ============================================================
CREATE TABLE IF NOT EXISTS `zodi4c_storage_logs` (
    `id`         INT AUTO_INCREMENT PRIMARY KEY,
    `storage_id` INT          NOT NULL,                            -- Storage reference
    `citizenid`  VARCHAR(50) COLLATE utf8mb4_unicode_ci NOT NULL, -- Actor citizenid
    `name`       VARCHAR(100) NOT NULL,                            -- Actor character name
    `action`     VARCHAR(50)  NOT NULL,                            -- take | put | access
    `details`    TEXT,                                             -- Item name, amount, etc.
    `created_at` TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,

    INDEX `idx_storage_log` (`storage_id`),
    INDEX `idx_log_time`    (`created_at`),

    FOREIGN KEY (`storage_id`) REFERENCES `zodi4c_storages`(`id`)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
