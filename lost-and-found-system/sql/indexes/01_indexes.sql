-- ============================================================
-- CENTRALIZED CAMPUS LOST AND FOUND SYSTEM
-- Phase 1C: Comprehensive Index Definitions
-- ============================================================
-- Author: Single Owner (No Co-authors)
-- Purpose: Performance optimization for all query patterns
-- ============================================================

USE `campus_lost_found`;

-- ============================================================
-- ADDITIONAL INDEXES FOR USERS TABLE
-- ============================================================
-- Composite index for role-based department queries
CREATE INDEX IF NOT EXISTS `idx_users_role_department` 
ON users (`role`, `department`);

-- Index for last sign-in tracking (analytics)
CREATE INDEX IF NOT EXISTS `idx_users_lastSignInAt` 
ON users (`lastSignInAt`);

-- ============================================================
-- ADDITIONAL INDEXES FOR ITEMS TABLE
-- ============================================================
-- Composite index for status + date filtering (common query pattern)
CREATE INDEX IF NOT EXISTS `idx_items_status_date` 
ON items (`status`, `date_reported`);

-- Composite index for location + category searches
CREATE INDEX IF NOT EXISTS `idx_items_location_category` 
ON items (`location_found`, `category`);

-- Index for brand searches
CREATE INDEX IF NOT EXISTS `idx_items_brand` 
ON items (`brand`);

-- Index for color searches
CREATE INDEX IF NOT EXISTS `idx_items_color` 
ON items (`color`);

-- ============================================================
-- ADDITIONAL INDEXES FOR CLAIMS TABLE
-- ============================================================
-- Composite index for admin review workflow
CREATE INDEX IF NOT EXISTS `idx_claims_status_created` 
ON claims (`verification_status`, `claim_date`);

-- Index for claimant lookup by user
CREATE INDEX IF NOT EXISTS `idx_claims_user_date` 
ON claims (`user_id`, `claim_date`);

-- ============================================================
-- ADDITIONAL INDEXES FOR REPORTS TABLE
-- ============================================================
-- Composite index for user report history
CREATE INDEX IF NOT EXISTS `idx_reports_user_type` 
ON reports (`user_id`, `report_type`);

-- Index for date-based analytics
CREATE INDEX IF NOT EXISTS `idx_reports_created_at` 
ON reports (`created_at`);

-- ============================================================
-- ADDITIONAL INDEXES FOR AUDIT_LOG TABLE
-- ============================================================
-- Composite index for action + timestamp filtering
CREATE INDEX IF NOT EXISTS `idx_audit_action_timestamp` 
ON audit_log (`action`, `timestamp`);

-- Composite index for user-related actions
CREATE INDEX IF NOT EXISTS `idx_audit_user_timestamp` 
ON audit_log (`user_id`, `timestamp`);

-- Index for IP-based security audits
CREATE INDEX IF NOT EXISTS `idx_audit_ip_address` 
ON audit_log (`ip_address`);

-- ============================================================
-- ADDITIONAL INDEXES FOR NOTIFICATIONS TABLE
-- ============================================================
-- Composite index for unread notifications per user
CREATE INDEX IF NOT EXISTS `idx_notifications_user_unread` 
ON notifications (`user_id`, `is_read`, `created_at`);

-- Index for notification type filtering
CREATE INDEX IF NOT EXISTS `idx_notifications_type_created` 
ON notifications (`type`, `created_at`);

-- ============================================================
-- ADDITIONAL INDEXES FOR CATEGORIES TABLE
-- ============================================================
-- Self-referential index already exists, adding name lookup
CREATE INDEX IF NOT EXISTS `idx_categories_name` 
ON categories (`name`);

-- ============================================================
-- FULLTEXT SEARCH OPTIMIZATION
-- ============================================================
-- Note: Fulltext index on items.description already created in schema
-- Adding fulltext on combined fields for better search
ALTER TABLE items 
ADD COLUMN `search_vector` TEXT GENERATED ALWAYS AS (
    CONCAT_WS(' ', category, color, brand, location_found, description)
) STORED;

CREATE FULLTEXT INDEX IF NOT EXISTS `ft_idx_items_search_vector` 
ON items (`search_vector`);

-- ============================================================
-- END OF INDEX DEFINITIONS
-- ============================================================
