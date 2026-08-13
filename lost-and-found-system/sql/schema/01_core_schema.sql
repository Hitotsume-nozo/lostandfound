-- ============================================================
-- CENTRALIZED CAMPUS LOST AND FOUND SYSTEM
-- Phase 1A: Core Schema Definition
-- ============================================================
-- Database Engine: MySQL 8.0+
-- Author: Single Owner (No Co-authors)
-- License: All Rights Reserved
-- ============================================================

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- ============================================================
-- DATABASE CREATION
-- ============================================================
DROP DATABASE IF EXISTS `campus_lost_found`;
CREATE DATABASE `campus_lost_found` 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE `campus_lost_found`;

-- ============================================================
-- TABLE: users
-- Purpose: Core identity and role-based access control
-- AI Headroom: preferences_json for ML-driven recommendations
-- ============================================================
CREATE TABLE `users` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `unionId` VARCHAR(255) NOT NULL UNIQUE COMMENT 'External auth provider ID',
    `first_name` VARCHAR(50),
    `last_name` VARCHAR(50),
    `name` VARCHAR(255) NOT NULL,
    `email` VARCHAR(320) NOT NULL UNIQUE,
    `avatar` TEXT COMMENT 'Profile image URL',
    `role` ENUM('user', 'admin', 'moderator') NOT NULL DEFAULT 'user',
    `phone` VARCHAR(15),
    `department` VARCHAR(60),
    `preferences_json` JSON COMMENT 'AI headroom: user preferences for recommendations',
    `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    `updatedAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
    `lastSignInAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    INDEX `idx_users_email` (`email`),
    INDEX `idx_users_role` (`role`),
    INDEX `idx_users_department` (`department`),
    INDEX `idx_users_unionId` (`unionId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE: items
-- Purpose: Lost and found item registry with lifecycle tracking
-- AI Headroom: embedding_vector for similarity search, metadata_json for ML features
-- ============================================================
CREATE TABLE `items` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `category` VARCHAR(30) NOT NULL,
    `description` TEXT NOT NULL,
    `color` VARCHAR(20),
    `brand` VARCHAR(40),
    `location_found` VARCHAR(80) NOT NULL,
    `date_reported` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `status` ENUM('Lost', 'Found', 'Claimed', 'Returned', 'Expired') NOT NULL DEFAULT 'Found',
    `reported_by` BIGINT UNSIGNED NOT NULL,
    `image` TEXT COMMENT 'Item image URL',
    `embedding_vector` VECTOR(384) COMMENT 'AI headroom: text embedding for similarity search',
    `metadata_json` JSON COMMENT 'AI headroom: additional ML features (confidence scores, etc.)',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
    
    CONSTRAINT `fk_items_reported_by` 
        FOREIGN KEY (`reported_by`) REFERENCES `users`(`id`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    
    INDEX `idx_items_category` (`category`),
    INDEX `idx_items_status` (`status`),
    INDEX `idx_items_location` (`location_found`),
    INDEX `idx_items_date_reported` (`date_reported`),
    INDEX `idx_items_reported_by` (`reported_by`),
    INDEX `idx_items_category_status` (`category`, `status`),
    FULLTEXT INDEX `ft_idx_items_description` (`description`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE: claims
-- Purpose: Ownership verification pipeline with status tracking
-- AI Headroom: metadata_json for fraud detection features
-- ============================================================
CREATE TABLE `claims` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `item_id` BIGINT UNSIGNED NOT NULL,
    `claim_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `proof_description` TEXT NOT NULL,
    `verification_status` ENUM('Pending', 'Approved', 'Rejected', 'Under Review') NOT NULL DEFAULT 'Pending',
    `admin_notes` TEXT COMMENT 'Admin review notes',
    `metadata_json` JSON COMMENT 'AI headroom: fraud detection features, confidence scores',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
    
    CONSTRAINT `fk_claims_user` 
        FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_claims_item` 
        FOREIGN KEY (`item_id`) REFERENCES `items`(`id`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    
    INDEX `idx_claims_user_id` (`user_id`),
    INDEX `idx_claims_item_id` (`item_id`),
    INDEX `idx_claims_verification_status` (`verification_status`),
    INDEX `idx_claims_claim_date` (`claim_date`),
    INDEX `idx_claims_user_status` (`user_id`, `verification_status`),
    INDEX `idx_claims_item_status` (`item_id`, `verification_status`),
    UNIQUE INDEX `uq_claims_user_item_pending` (`user_id`, `item_id`, `verification_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE: reports
-- Purpose: Historical event log for all lost/found reports
-- Note: Immutable snapshot separate from active items table
-- ============================================================
CREATE TABLE `reports` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `report_type` ENUM('Lost', 'Found') NOT NULL,
    `item_desc` TEXT,
    `location` VARCHAR(80),
    `date_event` TIMESTAMP,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT `fk_reports_user` 
        FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    
    INDEX `idx_reports_user_id` (`user_id`),
    INDEX `idx_reports_report_type` (`report_type`),
    INDEX `idx_reports_date_event` (`date_event`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE: audit_log
-- Purpose: Immutable record of all critical system actions
-- ============================================================
CREATE TABLE `audit_log` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `action` VARCHAR(50) NOT NULL,
    `claim_id` BIGINT UNSIGNED,
    `item_id` BIGINT UNSIGNED,
    `admin_id` BIGINT UNSIGNED,
    `user_id` BIGINT UNSIGNED,
    `details` TEXT,
    `ip_address` VARCHAR(45) COMMENT 'For security auditing',
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT `fk_audit_claim` 
        FOREIGN KEY (`claim_id`) REFERENCES `claims`(`id`)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_audit_item` 
        FOREIGN KEY (`item_id`) REFERENCES `items`(`id`)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_audit_admin` 
        FOREIGN KEY (`admin_id`) REFERENCES `users`(`id`)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_audit_user` 
        FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
        ON DELETE SET NULL ON UPDATE CASCADE,
    
    INDEX `idx_audit_action` (`action`),
    INDEX `idx_audit_timestamp` (`timestamp`),
    INDEX `idx_audit_item_id` (`item_id`),
    INDEX `idx_audit_claim_id` (`claim_id`),
    INDEX `idx_audit_admin_id` (`admin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE: notifications
-- Purpose: User notification system for claim updates
-- AI Headroom: metadata_json for ML-driven notification timing
-- ============================================================
CREATE TABLE `notifications` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` BIGINT UNSIGNED NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `message` TEXT NOT NULL,
    `type` ENUM('claim_status', 'item_found', 'system', 'reminder') NOT NULL,
    `is_read` TINYINT(1) DEFAULT 0 NOT NULL,
    `related_claim_id` BIGINT UNSIGNED,
    `related_item_id` BIGINT UNSIGNED,
    `metadata_json` JSON COMMENT 'AI headroom: optimal delivery time, priority score',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT `fk_notifications_user` 
        FOREIGN KEY (`user_id`) REFERENCES `users`(`id`)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_notifications_claim` 
        FOREIGN KEY (`related_claim_id`) REFERENCES `claims`(`id`)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_notifications_item` 
        FOREIGN KEY (`related_item_id`) REFERENCES `items`(`id`)
        ON DELETE SET NULL ON UPDATE CASCADE,
    
    INDEX `idx_notifications_user_id` (`user_id`),
    INDEX `idx_notifications_is_read` (`is_read`),
    INDEX `idx_notifications_type` (`type`),
    INDEX `idx_notifications_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- TABLE: categories
-- Purpose: Standardized item categories with hierarchy support
-- AI Headroom: metadata_json for category similarity mapping
-- ============================================================
CREATE TABLE `categories` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(50) NOT NULL UNIQUE,
    `parent_id` INT UNSIGNED NULL,
    `description` VARCHAR(255),
    `metadata_json` JSON COMMENT 'AI headroom: category embeddings, related categories',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT `fk_categories_parent` 
        FOREIGN KEY (`parent_id`) REFERENCES `categories`(`id`)
        ON DELETE SET NULL ON UPDATE CASCADE,
    
    INDEX `idx_categories_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- SCHEMA FINALIZATION
-- ============================================================
SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

-- ============================================================
-- END OF PHASE 1A SCHEMA
-- ============================================================
