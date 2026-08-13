# Centralized Campus Lost & Found System

## Project Overview

A comprehensive database-driven lost and found management system designed for large academic institutions. This project implements a **Database-as-Application** architecture where business logic is encapsulated within the RDBMS using stored procedures and triggers.

**Author:** Single Owner (No Co-authors)  
**Database Engine:** MySQL 8.0+  
**License:** All Rights Reserved

---

## 📁 Project Structure

```
lost-and-found-system/
├── sql/
│   ├── schema/
│   │   └── 01_core_schema.sql      # Core table definitions with AI headroom
│   ├── views/
│   │   └── 01_views.sql            # Data abstraction views
│   ├── indexes/
│   │   └── 01_indexes.sql          # Performance optimization indexes
│   ├── procedures/
│   │   └── 01_procedures.sql       # Business logic stored procedures
│   ├── triggers/
│   │   └── 01_triggers.sql         # Automation triggers
│   └── seed/
│       └── 01_seed_data.sql        # Test data for development
├── docs/
│   └── (documentation files)
└── scripts/
    └── (deployment and utility scripts)
```

---

## 🚀 Quick Start

### Prerequisites

- MySQL 8.0 or higher
- MySQL client with sufficient privileges to create databases, tables, procedures, and triggers

### Installation

1. **Clone or navigate to the project directory**
   ```bash
   cd lost-and-found-system
   ```

2. **Execute SQL files in order**
   ```bash
   mysql -u root -p < sql/schema/01_core_schema.sql
   mysql -u root -p < sql/indexes/01_indexes.sql
   mysql -u root -p < sql/views/01_views.sql
   mysql -u root -p < sql/procedures/01_procedures.sql
   mysql -u root -p < sql/triggers/01_triggers.sql
   mysql -u root -p < sql/seed/01_seed_data.sql
   ```

3. **Verify installation**
   ```sql
   USE campus_lost_found;
   SHOW TABLES;
   SHOW PROCEDURE STATUS WHERE Db = 'campus_lost_found';
   SHOW TRIGGERS;
   ```

---

## 🗄️ Database Schema

### Core Tables

| Table | Purpose | AI Headroom |
|-------|---------|-------------|
| `users` | Identity and role-based access control | `preferences_json` for ML recommendations |
| `items` | Lost/found item registry | `embedding_vector`, `metadata_json` for similarity search |
| `claims` | Ownership verification pipeline | `metadata_json` for fraud detection |
| `reports` | Historical event snapshots | - |
| `audit_log` | Immutable action tracking | - |
| `notifications` | User notification system | `metadata_json` for delivery optimization |
| `categories` | Standardized item taxonomy | `metadata_json` for category mapping |

### Key Features

- **Normalization:** 3NF/BCNF compliant schema
- **Referential Integrity:** Foreign key constraints across all related tables
- **Full-Text Search:** Optimized search vectors for natural language queries
- **JSON Columns:** Flexible metadata storage for AI/ML integration
- **Vector Support:** Native VECTOR(384) type for embedding storage (MySQL 8.0+)

---

## ⚙️ Stored Procedures

| Procedure | Purpose |
|-----------|---------|
| `sp_report_item` | Atomic item reporting with audit trail |
| `sp_submit_claim` | Claim submission with business rule validation |
| `sp_review_claim` | Admin claim review with automatic status transitions |
| `sp_search_items` | Advanced full-text search with filters |
| `sp_get_user_dashboard_data` | Comprehensive user dashboard retrieval |
| `sp_mark_notification_read` | Notification management |
| `sp_get_admin_dashboard_data` | Admin analytics and pending actions |

### Example Usage

```sql
-- Report a found item
CALL sp_report_item(
    1,                              -- user_id
    'Smartphones',                  -- category
    'iPhone 14 Pro with clear case',-- description
    'Space Gray',                   -- color
    'Apple',                        -- brand
    'Library Main Entrance',        -- location
    'Found',                        -- status
    NOW(),                          -- date
    'https://example.com/img.jpg',  -- image
    @item_id                        -- OUT parameter
);
SELECT @item_id;

-- Submit a claim
CALL sp_submit_claim(
    5,                              -- user_id
    1,                              -- item_id
    'Has Face ID and specific wallpaper', -- proof
    @claim_id                       -- OUT parameter
);

-- Admin review
CALL sp_review_claim(
    1,                              -- claim_id
    2,                              -- admin_id
    'Approved',                     -- status
    'Verified with biometric unlock', -- notes
    @success                        -- OUT parameter
);
```

---

## 🔁 Triggers & Automation

| Trigger | Event | Purpose |
|---------|-------|---------|
| `trg_before_item_insert` | BEFORE INSERT on items | Data validation and normalization |
| `trg_after_claim_update` | AFTER UPDATE on claims | Automatic item status transitions |
| `trg_before_claim_insert` | BEFORE INSERT on claims | Duplicate claim prevention |
| `trg_audit_user_changes` | AFTER UPDATE on users | Security audit logging |
| `trg_check_item_expiration` | BEFORE UPDATE on items | Auto-expire old unclaimed items |

### Event Scheduler

- `evt_daily_cleanup`: Daily maintenance task for archiving old audit logs and expiring orphaned items

---

## 👁️ Views for Data Abstraction

| View | Purpose |
|------|---------|
| `public_search_view` | PII-masked public search interface |
| `user_claims_view` | User-specific claim history |
| `admin_dashboard_view` | Aggregated system statistics |
| `item_lifecycle_view` | Complete item journey tracking |
| `category_statistics_view` | Category-wise analytics |
| `pending_claims_detailed_view` | Admin claim review interface |

---

## 🧪 Test Data

The seed script populates:

- **25 Users** (5 admins/moderators, 20 regular users)
- **~30 Items** across all categories
- **~25 Claims** (approved, pending, rejected, under review)
- **7 Reports** (historical snapshots)
- **6 Audit Log Entries**
- **5 Notifications**

*Note: Full-scale deployment should use the provided Python script to generate 500+ items and 1000+ claims.*

---

## 🔒 Security Model

### Role-Based Access Control (RBAC)

| Role | Permissions |
|------|-------------|
| `user` | Report items, submit claims, view own data |
| `moderator` | User permissions + initial claim review |
| `admin` | Full system access, user management, final approvals |

### Security Features

- Prepared statement ready (all procedures use parameterized queries)
- IP address tracking in audit logs
- PII masking through views
- Immutable audit trail
- Transactional integrity with rollback on errors

---

## 🤖 AI Integration Headroom (Stage 3 Ready)

The schema includes dedicated columns for future AI features:

1. **`items.embedding_vector`**: Store 384-dimensional text embeddings for semantic similarity search
2. **`items.metadata_json`**: ML confidence scores, condition assessments
3. **`users.preferences_json`**: User preference profiles for recommendation engines
4. **`claims.metadata_json`**: Fraud detection features, risk scores
5. **`notifications.metadata_json`**: Optimal delivery timing, priority scoring
6. **`categories.metadata_json`**: Category embeddings for intelligent classification

---

## 📊 Performance Optimization

### Indexes

- **Single-column indexes** on all foreign keys and frequently queried columns
- **Composite indexes** for common query patterns (e.g., `status + date_reported`)
- **Full-text indexes** on `search_vector` for natural language search
- **Covering indexes** for dashboard views

### Query Optimization

- Materialized view patterns through summary tables
- Partitioning-ready schema for high-volume deployments
- Query result caching strategies documented in Stage 2

---

## 📈 Next Stages

### Stage 1 ✅ (Current)
- [x] Core schema with AI headroom
- [x] Views for data abstraction
- [x] Comprehensive indexing
- [x] Stored procedures for business logic
- [x] Automation triggers
- [x] Seed data for testing

### Stage 2 (Upcoming)
- [ ] Dynamic web UI (React/Next.js or Vue/Nuxt)
- [ ] RESTful API layer (Node.js/Express or Python/FastAPI)
- [ ] Authentication integration (OAuth 2.0 / JWT)
- [ ] Real-time notifications (WebSocket)
- [ ] Admin dashboard with analytics
- [ ] Mobile-responsive design

### Stage 3 (Future)
- [ ] AI-powered item matching (semantic search)
- [ ] Fraud detection ML model
- [ ] Recommendation engine for lost items
- [ ] Automated category classification
- [ ] Predictive analytics for high-loss locations
- [ ] Chatbot for claim assistance

---

## 📝 Testing Guidelines

### Manual Testing Scenarios

1. **Concurrent duplicate claims** → Should reject second claim with SQLSTATE 45000
2. **Claim approval flow** → Item status should auto-transition to 'Returned'
3. **Full-text search** → Sub-10ms retrieval for category searches
4. **Claim on returned item** → Should reject with "Item unavailable"
5. **Audit log completeness** → All critical actions must be recorded

### Automated Testing

*(Scripts to be added in Stage 2)*

```bash
npm run test:db
npm run test:api
npm run test:e2e
```

---

## 🐛 Troubleshooting

### Common Issues

**Issue:** Trigger compilation error  
**Solution:** Ensure MySQL version is 8.0+ for VECTOR type support

**Issue:** Event scheduler not running  
**Solution:** Enable with `SET GLOBAL event_scheduler = ON;`

**Issue:** Full-text search returning no results  
**Solution:** Ensure minimum word length (default 4 chars) or adjust `ft_min_word_len`

---

## 📚 References

1. MySQL 8.0 Reference Manual - Stored Objects and Triggers
2. Silberschatz, Korth, Sudarshan - *Database System Concepts*, 7th Edition
3. Thapar Institute UCS310 DBMS Course Guidelines

---

## 📞 Support

For issues or questions regarding this implementation, contact the project maintainer through official channels.

---

**Last Updated:** 2026  
**Version:** 1.0.0 (Stage 1 Complete)
