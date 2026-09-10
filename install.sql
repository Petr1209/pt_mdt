-- ==========================================================
-- PT_MDT - Database Schema for MariaDB / MySQL
-- Author: pt_scripts (it-petrfila)
-- Repository: https://github.com/it-petrfila/pt_mdt
-- ==========================================================

CREATE TABLE IF NOT EXISTS `pt_mdt_incidents` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(255) NOT NULL,
    `description` LONGTEXT DEFAULT NULL,
    `creator_identifier` VARCHAR(64) NOT NULL,
    `creator_name` VARCHAR(128) NOT NULL,
    `suspects` LONGTEXT DEFAULT '[]',
    `officers` LONGTEXT DEFAULT '[]',
    `civilians` LONGTEXT DEFAULT '[]',
    `evidence` LONGTEXT DEFAULT '[]',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_creator` (`creator_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pt_mdt_warrants` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `suspect_identifier` VARCHAR(64) NOT NULL,
    `suspect_name` VARCHAR(128) NOT NULL,
    `reason` TEXT NOT NULL,
    `creator_identifier` VARCHAR(64) NOT NULL,
    `creator_name` VARCHAR(128) NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_suspect` (`suspect_identifier`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pt_mdt_bolos` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `type` VARCHAR(20) NOT NULL DEFAULT 'person',
    `title` VARCHAR(255) NOT NULL,
    `plate` VARCHAR(16) DEFAULT NULL,
    `suspect_name` VARCHAR(128) DEFAULT NULL,
    `description` TEXT NOT NULL,
    `creator_name` VARCHAR(128) NOT NULL,
    `status` VARCHAR(20) NOT NULL DEFAULT 'active',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_bolo_status` (`status`),
    INDEX `idx_bolo_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pt_mdt_bulletins` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `title` VARCHAR(255) NOT NULL,
    `message` TEXT NOT NULL,
    `author` VARCHAR(128) NOT NULL,
    `pinned` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pt_mdt_citizen_data` (
    `identifier` VARCHAR(64) NOT NULL,
    `avatar_url` TEXT DEFAULT NULL,
    `notes` TEXT DEFAULT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pt_mdt_vehicle_data` (
    `plate` VARCHAR(16) NOT NULL,
    `stolen` TINYINT(1) NOT NULL DEFAULT 0,
    `notes` TEXT DEFAULT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `pt_mdt_convictions` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL,
    `incident_id` INT(11) DEFAULT NULL,
    `charge_name` VARCHAR(255) NOT NULL,
    `fine` INT(11) NOT NULL DEFAULT 0,
    `prison` INT(11) NOT NULL DEFAULT 0,
    `officer_name` VARCHAR(128) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_convict_identifier` (`identifier`),
    INDEX `idx_convict_incident` (`incident_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
