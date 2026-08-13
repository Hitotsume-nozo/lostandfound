-- ============================================================
-- CENTRALIZED CAMPUS LOST AND FOUND SYSTEM
-- Stage 1: Database Triggers for Automation
-- ============================================================
-- Author: Single Owner (No Co-authors)
-- Database Engine: MySQL 8.0+
-- ============================================================

USE `campus_lost_found`;

DELIMITER //

-- ============================================================
-- TRIGGER: trg_before_item_insert
-- Purpose: Validate and normalize item data before insertion
-- ============================================================
DROP TRIGGER IF EXISTS `trg_before_item_insert`//
CREATE TRIGGER `trg_before_item_insert`
BEFORE INSERT ON items
FOR EACH ROW
BEGIN
    -- Normalize category to title case
    SET NEW.category = INITCAP(NEW.category);
    
    -- Ensure description is not empty
    IF TRIM(NEW.description) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Item description cannot be empty';
    END IF;
    
    -- Validate status
    IF NEW.status NOT IN ('Lost', 'Found', 'Claimed', 'Returned', 'Expired') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid item status';
    END IF;
END//

-- ============================================================
-- TRIGGER: trg_after_claim_update
-- Purpose: Automatically update item status when claim is approved/rejected
-- Replaces the need for manual status updates
-- ============================================================
DROP TRIGGER IF EXISTS `trg_after_claim_update`//
CREATE TRIGGER `trg_after_claim_update`
AFTER UPDATE ON claims
FOR EACH ROW
BEGIN
    DECLARE v_action VARCHAR(50);
    
    -- Only process if verification_status changed
    IF NEW.verification_status != OLD.verification_status THEN
        
        -- Handle approval
        IF NEW.verification_status = 'Approved' THEN
            UPDATE items
            SET status = 'Returned',
                updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.item_id;
            
            SET v_action = 'AUTO_RETURNED';
            
            INSERT INTO audit_log (
                action, item_id, claim_id, user_id, details
            ) VALUES (
                v_action, NEW.item_id, NEW.id, NEW.user_id,
                'Item automatically marked as Returned via trigger on claim approval'
            );
        
        -- Handle rejection
        ELSEIF NEW.verification_status = 'Rejected' THEN
            -- Only set back to Found if no other pending claims exist
            IF NOT EXISTS (
                SELECT 1 FROM claims 
                WHERE item_id = NEW.item_id 
                  AND verification_status = 'Pending'
            ) THEN
                UPDATE items
                SET status = 'Found',
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = NEW.item_id;
                
                SET v_action = 'STATUS_RESET_TO_FOUND';
                
                INSERT INTO audit_log (
                    action, item_id, claim_id, details
                ) VALUES (
                    v_action, NEW.item_id, NEW.id,
                    'Item status reset to Found after claim rejection'
                );
            END IF;
        END IF;
    END IF;
END//

-- ============================================================
-- TRIGGER: trg_before_claim_insert
-- Purpose: Business rule validation before claim insertion
-- ============================================================
DROP TRIGGER IF EXISTS `trg_before_claim_insert`//
CREATE TRIGGER `trg_before_claim_insert`
BEFORE INSERT ON claims
FOR EACH ROW
BEGIN
    DECLARE v_item_status VARCHAR(20);
    DECLARE v_pending_count INT;
    
    -- Get current item status
    SELECT status INTO v_item_status
    FROM items WHERE id = NEW.item_id;
    
    -- Validate item is available for claiming
    IF v_item_status IN ('Returned', 'Expired') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot claim: Item is no longer available';
    END IF;
    
    -- Check for existing pending claims by same user
    SELECT COUNT(*) INTO v_pending_count
    FROM claims
    WHERE item_id = NEW.item_id
      AND user_id = NEW.user_id
      AND verification_status = 'Pending';
    
    IF v_pending_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'You already have a pending claim for this item';
    END IF;
END//

-- ============================================================
-- TRIGGER: trg_after_notification_insert
-- Purpose: Auto-expire old notifications (keep last 30 days)
-- ============================================================
DROP TRIGGER IF EXISTS `trg_after_notification_insert`//
CREATE TRIGGER `trg_after_notification_insert`
AFTER INSERT ON notifications
FOR EACH ROW
BEGIN
    -- Archive old notifications (older than 30 days)
    DELETE FROM notifications
    WHERE user_id = NEW.user_id
      AND created_at < DATE_SUB(NOW(), INTERVAL 30 DAY)
      AND is_read = 1;
END//

-- ============================================================
-- TRIGGER: trg_before_user_insert
-- Purpose: Set default name if not provided
-- ============================================================
DROP TRIGGER IF EXISTS `trg_before_user_insert`//
CREATE TRIGGER `trg_before_user_insert`
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    -- If name is empty, construct from first_name and last_name
    IF NEW.name IS NULL OR TRIM(NEW.name) = '' THEN
        IF NEW.first_name IS NOT NULL AND NEW.last_name IS NOT NULL THEN
            SET NEW.name = CONCAT(NEW.first_name, ' ', NEW.last_name);
        ELSEIF NEW.first_name IS NOT NULL THEN
            SET NEW.name = NEW.first_name;
        ELSEIF NEW.last_name IS NOT NULL THEN
            SET NEW.name = NEW.last_name;
        ELSE
            SET NEW.name = CONCAT('User_', NEW.unionId);
        END IF;
    END IF;
END//

-- ============================================================
-- TRIGGER: trg_audit_user_changes
-- Purpose: Track significant user account changes
-- ============================================================
DROP TRIGGER IF EXISTS `trg_audit_user_changes`//
CREATE TRIGGER `trg_audit_user_changes`
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    -- Log role changes
    IF OLD.role != NEW.role THEN
        INSERT INTO audit_log (
            action, user_id, admin_id, details
        ) VALUES (
            'USER_ROLE_CHANGED', NEW.id, NULL,
            CONCAT('Role changed from ', OLD.role, ' to ', NEW.role)
        );
    END IF;
    
    -- Log department changes
    IF OLD.department != NEW.department AND NEW.department IS NOT NULL THEN
        INSERT INTO audit_log (
            action, user_id, details
        ) VALUES (
            'USER_DEPARTMENT_CHANGED', NEW.id,
            CONCAT('Department changed from ', IFNULL(OLD.department, 'None'), ' to ', NEW.department)
        );
    END IF;
END//

-- ============================================================
-- TRIGGER: trg_cleanup_expired_items
-- Purpose: Mark items as Expired after 90 days without claims
-- Note: This trigger fires on any item update to check expiration
-- ============================================================
DROP TRIGGER IF EXISTS `trg_check_item_expiration`//
CREATE TRIGGER `trg_check_item_expiration`
BEFORE UPDATE ON items
FOR EACH ROW
BEGIN
    IF NEW.status = 'Found' AND 
       NEW.date_reported < DATE_SUB(NOW(), INTERVAL 90 DAY) THEN
        -- Check if there are any claims
        IF NOT EXISTS (
            SELECT 1 FROM claims WHERE item_id = NEW.id
        ) THEN
            SET NEW.status = 'Expired';
        END IF;
    END IF;
END//

DELIMITER ;

-- ============================================================
-- EVENT: evt_daily_cleanup
-- Purpose: Daily cleanup of expired items and old audit logs
-- ============================================================
-- Enable event scheduler (requires SUPER privilege)
-- SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS `evt_daily_cleanup`//
CREATE EVENT `evt_daily_cleanup`
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP + INTERVAL 1 HOUR
DO
BEGIN
    -- Archive old audit logs (keep last 365 days)
    INSERT INTO audit_log_archive
    SELECT * FROM audit_log
    WHERE timestamp < DATE_SUB(NOW(), INTERVAL 365 DAY);
    
    DELETE FROM audit_log
    WHERE timestamp < DATE_SUB(NOW(), INTERVAL 365 DAY);
    
    -- Mark truly orphaned items as expired
    UPDATE items
    SET status = 'Expired'
    WHERE status = 'Found'
      AND date_reported < DATE_SUB(NOW(), INTERVAL 120 DAY)
      AND id NOT IN (SELECT item_id FROM claims);
END//

-- ============================================================
-- END OF TRIGGERS
-- ============================================================
