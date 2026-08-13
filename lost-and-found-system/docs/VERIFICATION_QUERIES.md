# Lost and Found System - Verification Queries

## Quick Verification

Run these queries after deployment to verify the installation:

```sql
USE campus_lost_found;

-- 1. Count tables (should be 7)
SELECT COUNT(*) AS table_count 
FROM information_schema.tables 
WHERE table_schema = 'campus_lost_found';

-- 2. List all tables
SHOW TABLES;

-- 3. Count stored procedures (should be 7)
SELECT COUNT(*) AS procedure_count
FROM information_schema.routines
WHERE routine_schema = 'campus_lost_found' 
  AND routine_type = 'PROCEDURE';

-- 4. List all procedures
SHOW PROCEDURE STATUS WHERE Db = 'campus_lost_found';

-- 5. Count triggers (should be 7+)
SELECT COUNT(*) AS trigger_count
FROM information_schema.triggers
WHERE trigger_schema = 'campus_lost_found';

-- 6. List all triggers
SHOW TRIGGERS FROM campus_lost_found;

-- 7. Count views (should be 7)
SELECT COUNT(*) AS view_count
FROM information_schema.views
WHERE table_schema = 'campus_lost_found';

-- 8. List all views
SHOW FULL TABLES WHERE TABLE_TYPE = 'VIEW';
```

---

## Schema Verification

### Check AI Headroom Columns

```sql
SELECT 
    TABLE_NAME, 
    COLUMN_NAME, 
    DATA_TYPE,
    COLUMN_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'campus_lost_found'
  AND (COLUMN_NAME LIKE '%vector%' OR COLUMN_NAME LIKE '%json%')
ORDER BY TABLE_NAME, COLUMN_NAME;
```

### Check Foreign Keys

```sql
SELECT 
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE REFERENCED_TABLE_NAME IS NOT NULL 
  AND TABLE_SCHEMA = 'campus_lost_found'
ORDER BY TABLE_NAME;
```

### Check Indexes

```sql
SELECT 
    TABLE_NAME,
    INDEX_NAME,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS COLUMNS,
    INDEX_TYPE,
    NON_UNIQUE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'campus_lost_found'
GROUP BY TABLE_NAME, INDEX_NAME, INDEX_TYPE, NON_UNIQUE
ORDER BY TABLE_NAME, INDEX_NAME;
```

---

## Stored Procedure Testing

### Test sp_report_item

```sql
-- Report a new found item
CALL sp_report_item(
    1,                              -- user_id
    'Electronics',                  -- category
    'Test wireless mouse',          -- description
    'Black',                        -- color
    'Logitech',                     -- brand
    'Library Floor 3',              -- location
    'Found',                        -- status
    NOW(),                          -- date
    NULL,                           -- image
    @new_item_id                    -- OUT parameter
);

-- Check the generated item ID
SELECT @new_item_id AS new_item_id;

-- Verify item was created
SELECT * FROM items WHERE id = @new_item_id;

-- Verify audit log entry
SELECT * FROM audit_log 
WHERE item_id = @new_item_id 
ORDER BY timestamp DESC LIMIT 1;
```

### Test sp_submit_claim

```sql
-- Submit a claim for an existing item
CALL sp_submit_claim(
    5,                              -- user_id (different from reporter)
    1,                              -- item_id
    'This is my mouse. It has a scratch on the left side.',
    @new_claim_id                   -- OUT parameter
);

SELECT @new_claim_id AS new_claim_id;

-- Verify claim was created
SELECT * FROM claims WHERE id = @new_claim_id;

-- Verify item status changed to 'Claimed'
SELECT id, status FROM items WHERE id = 1;
```

### Test sp_review_claim

```sql
-- Admin approves the claim
CALL sp_review_claim(
    @new_claim_id,                  -- claim_id
    1,                              -- admin_id
    'Approved',                     -- verification_status
    'Verified with unique scratch mark',
    @success                        -- OUT parameter
);

SELECT @success AS approval_success;

-- Verify claim status updated
SELECT id, verification_status, admin_notes FROM claims WHERE id = @new_claim_id;

-- Verify item status auto-transitioned to 'Returned'
SELECT id, status FROM items WHERE id = 1;

-- Verify audit log entry for auto-return
SELECT * FROM audit_log 
WHERE action = 'AUTO_RETURNED' 
  AND item_id = 1 
ORDER BY timestamp DESC LIMIT 1;
```

### Test sp_search_items

```sql
-- Full-text search
CALL sp_search_items(
    'iPhone',                       -- search_term
    NULL,                           -- category
    NULL,                           -- color
    NULL,                           -- location
    NULL,                           -- status
    NULL,                           -- date_from
    NULL,                           -- date_to
    10,                             -- limit
    0                               -- offset
);

-- Filter by category
CALL sp_search_items(
    NULL,                           -- search_term
    'Smartphones',                  -- category
    NULL,                           -- color
    NULL,                           -- location
    'Found',                        -- status
    NULL,                           -- date_from
    NULL,                           -- date_to
    10,                             -- limit
    0                               -- offset
);
```

### Test sp_get_user_dashboard_data

```sql
-- Get dashboard data for user ID 1
CALL sp_get_user_dashboard_data(1);
-- Returns 4 result sets: items, claims, notifications, statistics
```

### Test sp_get_admin_dashboard_data

```sql
-- Get comprehensive admin dashboard
CALL sp_get_admin_dashboard_data();
-- Returns 4 result sets: summary, pending claims, recent activity, category stats
```

---

## Trigger Testing

### Test Automatic Status Transition

```sql
-- Find a pending claim
SELECT id, item_id, verification_status 
FROM claims 
WHERE verification_status = 'Pending' 
LIMIT 1;

-- Approve it (trigger should auto-update item status)
UPDATE claims 
SET verification_status = 'Approved', 
    admin_notes = 'Test approval' 
WHERE id = 1;

-- Check item status (should be 'Returned')
SELECT i.id, i.status, c.verification_status
FROM items i
JOIN claims c ON i.id = c.item_id
WHERE c.id = 1;

-- Check audit log for automatic entry
SELECT * FROM audit_log 
WHERE action = 'AUTO_RETURNED' 
ORDER BY timestamp DESC LIMIT 1;
```

### Test Duplicate Claim Prevention

```sql
-- Try to submit duplicate claim (should fail)
CALL sp_submit_claim(
    1,                              -- same user
    1,                              -- same item
    'Duplicate claim test',
    @dup_claim_id
);
-- Expected: SQLSTATE 45000 error
```

---

## View Testing

### Test Public Search View (PII Masked)

```sql
-- Should NOT show reporter email, phone, etc.
SELECT * FROM public_search_view LIMIT 5;
```

### Test Admin Dashboard View

```sql
-- Summary statistics
SELECT * FROM admin_dashboard_view;
```

### Test Category Statistics

```sql
-- Analytics by category
SELECT * FROM category_statistics_view;
```

### Test Pending Claims Detailed View

```sql
-- Admin review queue
SELECT * FROM pending_claims_detailed_view;
```

### Test Item Lifecycle View

```sql
-- Complete journey tracking
SELECT * FROM item_lifecycle_view LIMIT 5;
```

---

## Data Integrity Checks

### Check Orphaned Records

```sql
-- Should return 0 for all queries
SELECT COUNT(*) AS orphaned_claims
FROM claims c
LEFT JOIN users u ON c.user_id = u.id
WHERE u.id IS NULL;

SELECT COUNT(*) AS orphaned_items
FROM items i
LEFT JOIN users u ON i.reported_by = u.id
WHERE u.id IS NULL;

SELECT COUNT(*) AS orphaned_reports
FROM reports r
LEFT JOIN users u ON r.user_id = u.id
WHERE u.id IS NULL;
```

### Check Status Consistency

```sql
-- Items marked as Returned should have approved claims
SELECT COUNT(*) AS inconsistent_returns
FROM items i
LEFT JOIN claims c ON i.id = c.item_id 
  AND c.verification_status = 'Approved'
WHERE i.status = 'Returned' AND c.id IS NULL;

-- Items marked as Claimed should have pending/approved claims
SELECT COUNT(*) AS inconsistent_claimed
FROM items i
LEFT JOIN claims c ON i.id = c.item_id 
  AND c.verification_status IN ('Pending', 'Approved')
WHERE i.status = 'Claimed' AND c.id IS NULL;
```

---

## Performance Tests

### Check Query Execution Time

```sql
-- Enable profiling
SET profiling = 1;

-- Run search query
CALL sp_search_items('iPhone', NULL, NULL, NULL, NULL, NULL, NULL, 10, 0);

-- Show execution profile
SHOW PROFILES;
SHOW PROFILE FOR QUERY 1;
```

### Check Index Usage

```sql
-- Explain search query
EXPLAIN SELECT * FROM items 
WHERE MATCH(search_vector) AGAINST('iPhone' IN NATURAL LANGUAGE MODE);

-- Explain claims lookup
EXPLAIN SELECT * FROM claims 
WHERE item_id = 1 AND verification_status = 'Pending';
```

---

## Cleanup Test Data (Optional)

```sql
-- Remove test item created during verification
DELETE FROM audit_log WHERE item_id = @new_item_id;
DELETE FROM claims WHERE item_id = @new_item_id;
DELETE FROM items WHERE id = @new_item_id;
```

---

**Expected Results Summary:**
- Tables: 7
- Procedures: 7
- Triggers: 7+
- Views: 7
- Seed Users: 25
- Seed Items: ~30
- Seed Claims: ~25

All verification queries should execute without errors.
