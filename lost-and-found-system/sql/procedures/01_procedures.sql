-- ============================================================
-- CENTRALIZED CAMPUS LOST AND FOUND SYSTEM
-- Stage 1: Stored Procedures for Business Logic
-- ============================================================
-- Author: Single Owner (No Co-authors)
-- Database Engine: MySQL 8.0+
-- ============================================================

USE `campus_lost_found`;

DELIMITER //

-- ============================================================
-- PROCEDURE: sp_report_item
-- Purpose: Atomic item reporting with audit trail
-- Handles both Lost and Found item reports
-- ============================================================
DROP PROCEDURE IF EXISTS `sp_report_item`//
CREATE PROCEDURE `sp_report_item`(
    IN p_user_id BIGINT UNSIGNED,
    IN p_category VARCHAR(30),
    IN p_description TEXT,
    IN p_color VARCHAR(20),
    IN p_brand VARCHAR(40),
    IN p_location VARCHAR(80),
    IN p_status ENUM('Lost', 'Found'),
    IN p_date TIMESTAMP,
    IN p_image TEXT,
    OUT p_item_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_item_id BIGINT UNSIGNED;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- 1. Insert the item record
    INSERT INTO items (
        category, description, color, brand,
        location_found, date_reported, status,
        reported_by, image
    ) VALUES (
        p_category, p_description, p_color, p_brand,
        p_location, p_date, p_status, p_user_id, p_image
    );
    
    SET v_item_id = LAST_INSERT_ID();
    SET p_item_id = v_item_id;
    
    -- 2. Create audit trail entry
    INSERT INTO audit_log (action, item_id, user_id, details)
    VALUES (
        'ITEM_REPORTED', v_item_id, p_user_id,
        CONCAT(p_status, ' item reported: ', LEFT(p_description, 50))
    );
    
    -- 3. Log the report event (historical snapshot)
    INSERT INTO reports (
        user_id, report_type, item_desc, location, date_event
    ) VALUES (
        p_user_id, p_status, p_description, p_location, p_date
    );
    
    COMMIT;
END//

-- ============================================================
-- PROCEDURE: sp_submit_claim
-- Purpose: Submit a claim with business rule validation
-- Prevents duplicate claims and invalid state transitions
-- ============================================================
DROP PROCEDURE IF EXISTS `sp_submit_claim`//
CREATE PROCEDURE `sp_submit_claim`(
    IN p_user_id BIGINT UNSIGNED,
    IN p_item_id BIGINT UNSIGNED,
    IN p_proof_description TEXT,
    OUT p_claim_id BIGINT UNSIGNED
)
BEGIN
    DECLARE v_item_status VARCHAR(20);
    DECLARE v_existing_claim_id BIGINT UNSIGNED;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- 1. Validate item existence and get status
    SELECT status INTO v_item_status
    FROM items 
    WHERE id = p_item_id
    FOR UPDATE;
    
    IF v_item_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Item not found';
    END IF;
    
    -- 2. Check item availability
    IF v_item_status IN ('Returned', 'Expired') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Item unavailable for claiming';
    END IF;
    
    IF v_item_status = 'Claimed' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Item already claimed by another user';
    END IF;
    
    -- 3. Prevent duplicate pending claims by same user
    SELECT id INTO v_existing_claim_id
    FROM claims
    WHERE item_id = p_item_id 
      AND user_id = p_user_id
      AND verification_status = 'Pending'
    LIMIT 1;
    
    IF v_existing_claim_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'You already have a pending claim for this item';
    END IF;
    
    -- 4. Process the claim
    INSERT INTO claims (
        user_id, item_id, proof_description, verification_status
    ) VALUES (
        p_user_id, p_item_id, p_proof_description, 'Pending'
    );
    
    SET p_claim_id = LAST_INSERT_ID();
    
    -- 5. Update item lifecycle to Claimed
    UPDATE items 
    SET status = 'Claimed' 
    WHERE id = p_item_id;
    
    -- 6. Log the action
    INSERT INTO audit_log (action, item_id, claim_id, user_id, details)
    VALUES (
        'CLAIM_SUBMITTED', p_item_id, p_claim_id, p_user_id,
        'Claim submitted for item'
    );
    
    -- 7. Create notification for admin
    INSERT INTO notifications (
        user_id, title, message, type, related_claim_id, related_item_id
    )
    SELECT 
        id,
        'New Claim Submitted',
        CONCAT('A new claim requires review for item #', p_item_id),
        'claim_status',
        p_claim_id,
        p_item_id
    FROM users
    WHERE role = 'admin'
    LIMIT 1;
    
    COMMIT;
END//

-- ============================================================
-- PROCEDURE: sp_review_claim
-- Purpose: Admin review and approval/rejection of claims
-- Triggers automatic status update on approval
-- ============================================================
DROP PROCEDURE IF EXISTS `sp_review_claim`//
CREATE PROCEDURE `sp_review_claim`(
    IN p_claim_id BIGINT UNSIGNED,
    IN p_admin_id BIGINT UNSIGNED,
    IN p_verification_status ENUM('Approved', 'Rejected'),
    IN p_admin_notes TEXT,
    OUT p_success TINYINT
)
BEGIN
    DECLARE v_item_id BIGINT UNSIGNED;
    DECLARE v_user_id BIGINT UNSIGNED;
    DECLARE v_old_status VARCHAR(20);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_success = 0;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- 1. Get claim details
    SELECT item_id, user_id, verification_status
    INTO v_item_id, v_user_id, v_old_status
    FROM claims
    WHERE id = p_claim_id
    FOR UPDATE;
    
    IF v_item_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Claim not found';
    END IF;
    
    IF v_old_status != 'Pending' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Claim has already been reviewed';
    END IF;
    
    -- 2. Update claim status
    UPDATE claims
    SET verification_status = p_verification_status,
        admin_notes = p_admin_notes,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_claim_id;
    
    -- 3. If approved, update item status
    IF p_verification_status = 'Approved' THEN
        UPDATE items
        SET status = 'Returned',
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_item_id;
        
        -- 4. Notify claimant of approval
        INSERT INTO notifications (
            user_id, title, message, type, 
            related_claim_id, related_item_id
        ) VALUES (
            v_user_id,
            'Claim Approved',
            'Your claim has been approved. Please collect your item.',
            'claim_status',
            p_claim_id,
            v_item_id
        );
    ELSE
        -- 5. If rejected, set item back to Found
        UPDATE items
        SET status = 'Found',
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_item_id;
        
        -- 6. Notify claimant of rejection
        INSERT INTO notifications (
            user_id, title, message, type,
            related_claim_id, related_item_id
        ) VALUES (
            v_user_id,
            'Claim Rejected',
            'Your claim has been rejected. Please contact support for more information.',
            'claim_status',
            p_claim_id,
            v_item_id
        );
    END IF;
    
    -- 7. Log the action
    INSERT INTO audit_log (
        action, claim_id, item_id, admin_id, user_id, details
    ) VALUES (
        'CLAIM_REVIEWED', p_claim_id, v_item_id, p_admin_id, v_user_id,
        CONCAT('Claim ', p_verification_status, '. Notes: ', IFNULL(p_admin_notes, 'None'))
    );
    
    SET p_success = 1;
    COMMIT;
END//

-- ============================================================
-- PROCEDURE: sp_search_items
-- Purpose: Advanced item search with filters and fulltext
-- Returns paginated results
-- ============================================================
DROP PROCEDURE IF EXISTS `sp_search_items`//
CREATE PROCEDURE `sp_search_items`(
    IN p_search_term VARCHAR(255),
    IN p_category VARCHAR(30),
    IN p_color VARCHAR(20),
    IN p_location VARCHAR(80),
    IN p_status VARCHAR(20),
    IN p_date_from DATE,
    IN p_date_to DATE,
    IN p_limit INT,
    IN p_offset INT
)
BEGIN
    SELECT 
        i.id,
        i.category,
        i.color,
        LEFT(i.description, 150) AS description,
        i.brand,
        i.location_found,
        i.date_reported,
        i.status,
        i.image,
        u.name AS reporter_name,
        u.department AS reporter_department
    FROM items i
    JOIN users u ON i.reported_by = u.id
    WHERE (p_search_term IS NULL OR 
           MATCH(i.search_vector) AGAINST(p_search_term IN NATURAL LANGUAGE MODE))
      AND (p_category IS NULL OR i.category = p_category)
      AND (p_color IS NULL OR i.color = p_color)
      AND (p_location IS NULL OR i.location_found LIKE CONCAT('%', p_location, '%'))
      AND (p_status IS NULL OR i.status = p_status)
      AND (p_date_from IS NULL OR i.date_reported >= p_date_from)
      AND (p_date_to IS NULL OR i.date_reported <= p_date_to)
      AND i.status IN ('Found', 'Lost')
    ORDER BY i.date_reported DESC
    LIMIT p_limit OFFSET p_offset;
END//

-- ============================================================
-- PROCEDURE: sp_get_user_dashboard_data
-- Purpose: Retrieve comprehensive user dashboard data
-- ============================================================
DROP PROCEDURE IF EXISTS `sp_get_user_dashboard_data`//
CREATE PROCEDURE `sp_get_user_dashboard_data`(
    IN p_user_id BIGINT UNSIGNED
)
BEGIN
    -- User's reported items
    SELECT 
        id, category, description, color, brand,
        location_found, date_reported, status, image
    FROM items
    WHERE reported_by = p_user_id
    ORDER BY date_reported DESC;
    
    -- User's claims
    SELECT 
        c.id AS claim_id,
        c.item_id,
        i.category AS item_category,
        i.description AS item_description,
        i.color AS item_color,
        c.claim_date,
        c.proof_description,
        c.verification_status,
        c.admin_notes
    FROM claims c
    JOIN items i ON c.item_id = i.id
    WHERE c.user_id = p_user_id
    ORDER BY c.claim_date DESC;
    
    -- User's unread notifications
    SELECT 
        id, title, message, type,
        related_claim_id, related_item_id, created_at
    FROM notifications
    WHERE user_id = p_user_id AND is_read = 0
    ORDER BY created_at DESC;
    
    -- User statistics
    SELECT 
        COUNT(DISTINCT CASE WHEN i.reported_by = p_user_id THEN i.id END) AS items_reported,
        COUNT(DISTINCT CASE WHEN i.reported_by = p_user_id AND i.status = 'Returned' THEN i.id END) AS items_returned,
        COUNT(DISTINCT c.id) AS claims_submitted,
        COUNT(DISTINCT CASE WHEN c.verification_status = 'Approved' THEN c.id END) AS claims_approved
    FROM items i
    LEFT JOIN claims c ON i.id = c.item_id AND c.user_id = p_user_id
    WHERE i.reported_by = p_user_id OR c.user_id = p_user_id;
END//

-- ============================================================
-- PROCEDURE: sp_mark_notification_read
-- Purpose: Mark notifications as read
-- ============================================================
DROP PROCEDURE IF EXISTS `sp_mark_notification_read`//
CREATE PROCEDURE `sp_mark_notification_read`(
    IN p_user_id BIGINT UNSIGNED,
    IN p_notification_id BIGINT UNSIGNED,
    OUT p_success TINYINT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_success = 0;
        RESIGNAL;
    END;
    
    UPDATE notifications
    SET is_read = 1
    WHERE id = p_notification_id AND user_id = p_user_id;
    
    IF ROW_COUNT() > 0 THEN
        SET p_success = 1;
    ELSE
        SET p_success = 0;
    END IF;
END//

-- ============================================================
-- PROCEDURE: sp_get_admin_dashboard_data
-- Purpose: Comprehensive admin dashboard with analytics
-- ============================================================
DROP PROCEDURE IF EXISTS `sp_get_admin_dashboard_data`//
CREATE PROCEDURE `sp_get_admin_dashboard_data`()
BEGIN
    -- Summary statistics
    SELECT * FROM admin_dashboard_view;
    
    -- Pending claims requiring review
    SELECT * FROM pending_claims_detailed_view;
    
    -- Recent activity (last 7 days)
    SELECT 
        al.action,
        al.details,
        al.timestamp,
        u.name AS user_name,
        i.category AS item_category
    FROM audit_log al
    LEFT JOIN users u ON al.user_id = u.id
    LEFT JOIN items i ON al.item_id = i.id
    WHERE al.timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ORDER BY al.timestamp DESC
    LIMIT 50;
    
    -- Category breakdown
    SELECT * FROM category_statistics_view;
END//

DELIMITER ;

-- ============================================================
-- END OF STORED PROCEDURES
-- ============================================================
