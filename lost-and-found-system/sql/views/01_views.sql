-- ============================================================
-- CENTRALIZED CAMPUS LOST AND FOUND SYSTEM
-- Phase 1B: Database Views for Data Abstraction
-- ============================================================
-- Author: Single Owner (No Co-authors)
-- ============================================================

USE `campus_lost_found`;

-- ============================================================
-- VIEW: public_search_view
-- Purpose: Mask sensitive PII from public search queries
-- Shows only non-identifying item information
-- ============================================================
CREATE OR REPLACE VIEW `public_search_view` AS
SELECT 
    i.id,
    i.category,
    i.color,
    LEFT(i.description, 100) AS description_preview,
    i.location_found,
    i.date_reported,
    i.status,
    i.brand,
    u.department AS reporter_department,
    TIMESTAMPDIFF(DAY, i.date_reported, NOW()) AS days_since_reported
FROM items i
JOIN users u ON i.reported_by = u.id
WHERE i.status IN ('Found', 'Lost')
WITH CHECK OPTION;

-- ============================================================
-- VIEW: user_claims_view
-- Purpose: Users can view their own claims with item details
-- Filters based on current session user (to be used with app logic)
-- ============================================================
CREATE OR REPLACE VIEW `user_claims_view` AS
SELECT 
    c.id AS claim_id,
    c.user_id,
    c.item_id,
    c.claim_date,
    c.proof_description,
    c.verification_status,
    c.admin_notes,
    c.created_at AS claim_created_at,
    c.updated_at AS claim_updated_at,
    i.category AS item_category,
    i.description AS item_description,
    i.color AS item_color,
    i.brand AS item_brand,
    i.location_found AS item_location,
    i.status AS item_status,
    i.image AS item_image
FROM claims c
JOIN items i ON c.item_id = i.id;

-- ============================================================
-- VIEW: admin_dashboard_view
-- Purpose: Comprehensive view for admin dashboard analytics
-- Includes aggregated statistics and pending actions
-- ============================================================
CREATE OR REPLACE VIEW `admin_dashboard_view` AS
SELECT 
    'summary' AS view_type,
    (SELECT COUNT(*) FROM users) AS total_users,
    (SELECT COUNT(*) FROM items) AS total_items,
    (SELECT COUNT(*) FROM items WHERE status = 'Found') AS items_available,
    (SELECT COUNT(*) FROM items WHERE status = 'Claimed') AS items_claimed,
    (SELECT COUNT(*) FROM items WHERE status = 'Returned') AS items_returned,
    (SELECT COUNT(*) FROM claims WHERE verification_status = 'Pending') AS pending_claims,
    (SELECT COUNT(*) FROM claims WHERE verification_status = 'Approved') AS approved_claims,
    (SELECT COUNT(*) FROM claims WHERE verification_status = 'Rejected') AS rejected_claims,
    (SELECT COUNT(*) FROM audit_log WHERE timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)) AS weekly_actions;

-- ============================================================
-- VIEW: item_lifecycle_view
-- Purpose: Track complete lifecycle of each item with all related events
-- ============================================================
CREATE OR REPLACE VIEW `item_lifecycle_view` AS
SELECT 
    i.id AS item_id,
    i.category,
    i.description,
    i.color,
    i.brand,
    i.location_found,
    i.date_reported,
    i.status AS current_status,
    u.name AS reporter_name,
    u.email AS reporter_email,
    u.department AS reporter_department,
    c.id AS claim_id,
    c.user_id AS claimant_id,
    cu.name AS claimant_name,
    c.claim_date,
    c.verification_status,
    c.admin_notes,
    al.action AS last_action,
    al.timestamp AS last_action_time,
    al.details AS last_action_details
FROM items i
JOIN users u ON i.reported_by = u.id
LEFT JOIN claims c ON i.id = c.item_id 
    AND c.verification_status IN ('Approved', 'Pending')
LEFT JOIN users cu ON c.user_id = cu.id
LEFT JOIN (
    SELECT item_id, action, timestamp, details,
           ROW_NUMBER() OVER (PARTITION BY item_id ORDER BY timestamp DESC) AS rn
    FROM audit_log
    WHERE item_id IS NOT NULL
) al ON i.id = al.item_id AND al.rn = 1;

-- ============================================================
-- VIEW: category_statistics_view
-- Purpose: Aggregated statistics by item category
-- ============================================================
CREATE OR REPLACE VIEW `category_statistics_view` AS
SELECT 
    i.category,
    COUNT(DISTINCT i.id) AS total_items,
    COUNT(DISTINCT CASE WHEN i.status = 'Found' THEN i.id END) AS available_items,
    COUNT(DISTINCT CASE WHEN i.status = 'Claimed' THEN i.id END) AS claimed_items,
    COUNT(DISTINCT CASE WHEN i.status = 'Returned' THEN i.id END) AS returned_items,
    COUNT(DISTINCT c.id) AS total_claims,
    COUNT(DISTINCT CASE WHEN c.verification_status = 'Approved' THEN c.id END) AS approved_claims,
    COUNT(DISTINCT CASE WHEN c.verification_status = 'Rejected' THEN c.id END) AS rejected_claims,
    AVG(TIMESTAMPDIFF(DAY, i.date_reported, NOW())) AS avg_days_outstanding,
    COUNT(DISTINCT i.reported_by) AS unique_reporters
FROM items i
LEFT JOIN claims c ON i.id = c.item_id
GROUP BY i.category
ORDER BY total_items DESC;

-- ============================================================
-- VIEW: user_activity_view
-- Purpose: User activity summary for profile pages and analytics
-- ============================================================
CREATE OR REPLACE VIEW `user_activity_view` AS
SELECT 
    u.id AS user_id,
    u.name,
    u.email,
    u.role,
    u.department,
    COUNT(DISTINCT CASE WHEN i.reported_by = u.id THEN i.id END) AS items_reported,
    COUNT(DISTINCT CASE WHEN i.reported_by = u.id AND i.status = 'Returned' THEN i.id END) AS items_successfully_returned,
    COUNT(DISTINCT c.id) AS claims_submitted,
    COUNT(DISTINCT CASE WHEN c.verification_status = 'Approved' THEN c.id END) AS claims_approved,
    COUNT(DISTINCT CASE WHEN c.verification_status = 'Rejected' THEN c.id END) AS claims_rejected,
    MAX(c.claim_date) AS last_claim_date,
    MAX(i.date_reported) AS last_report_date,
    u.createdAt AS member_since
FROM users u
LEFT JOIN items i ON u.id = i.reported_by
LEFT JOIN claims c ON u.id = c.user_id
GROUP BY u.id, u.name, u.email, u.role, u.department, u.createdAt;

-- ============================================================
-- VIEW: pending_claims_detailed_view
-- Purpose: Detailed view of pending claims for admin review
-- ============================================================
CREATE OR REPLACE VIEW `pending_claims_detailed_view` AS
SELECT 
    c.id AS claim_id,
    c.user_id,
    claimant.name AS claimant_name,
    claimant.email AS claimant_email,
    claimant.phone AS claimant_phone,
    claimant.department AS claimant_department,
    c.item_id,
    i.category AS item_category,
    i.description AS item_description,
    i.color AS item_color,
    i.brand AS item_brand,
    i.location_found,
    i.date_reported AS item_date_reported,
    i.image AS item_image,
    c.proof_description,
    c.claim_date,
    c.verification_status,
    reporter.name AS reporter_name,
    reporter.email AS reporter_email,
    TIMESTAMPDIFF(DAY, c.claim_date, NOW()) AS days_pending
FROM claims c
JOIN users claimant ON c.user_id = claimant.id
JOIN items i ON c.item_id = i.id
JOIN users reporter ON i.reported_by = reporter.id
WHERE c.verification_status = 'Pending'
ORDER BY c.claim_date ASC;

-- ============================================================
-- END OF VIEWS DEFINITION
-- ============================================================
