#!/bin/bash

# ============================================================
# CENTRALIZED CAMPUS LOST AND FOUND SYSTEM
# Stage 1 Deployment Script
# ============================================================
# Author: Single Owner (No Co-authors)
# Purpose: Automated deployment of database schema and objects
# Usage: ./deploy.sh [mysql_username] [database_host]
# ============================================================

set -e  # Exit on error

# Configuration
MYSQL_USER="${1:-root}"
MYSQL_HOST="${2:-localhost}"
MYSQL_PASS="${3:-}"
DB_NAME="campus_lost_found"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SQL_DIR="$SCRIPT_DIR/sql"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_mysql_connection() {
    log_info "Checking MySQL connection..."
    if [ -n "$MYSQL_PASS" ]; then
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -h "$MYSQL_HOST" -e "SELECT 1;" > /dev/null 2>&1
    else
        mysql -u "$MYSQL_USER" -h "$MYSQL_HOST" -e "SELECT 1;" > /dev/null 2>&1
    fi
    
    if [ $? -eq 0 ]; then
        log_success "MySQL connection established"
    else
        log_error "Failed to connect to MySQL. Please check credentials."
        exit 1
    fi
}

execute_sql_file() {
    local file=$1
    local description=$2
    
    log_info "Executing: $description"
    
    if [ -n "$MYSQL_PASS" ]; then
        mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -h "$MYSQL_HOST" < "$file"
    else
        mysql -u "$MYSQL_USER" -h "$MYSQL_HOST" < "$file"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "$description completed"
    else
        log_error "Failed to execute: $description"
        exit 1
    fi
}

verify_installation() {
    log_info "Verifying installation..."
    
    # Check tables
    TABLE_COUNT=$(mysql -u "$MYSQL_USER" -h "$MYSQL_HOST" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME';" 2>/dev/null)
    if [ "$TABLE_COUNT" -ge 7 ]; then
        log_success "Created $TABLE_COUNT tables"
    else
        log_error "Expected at least 7 tables, found $TABLE_COUNT"
        exit 1
    fi
    
    # Check procedures
    PROC_COUNT=$(mysql -u "$MYSQL_USER" -h "$MYSQL_HOST" -N -e "SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='$DB_NAME' AND routine_type='PROCEDURE';" 2>/dev/null)
    if [ "$PROC_COUNT" -ge 7 ]; then
        log_success "Created $PROC_COUNT stored procedures"
    else
        log_warning "Expected 7 procedures, found $PROC_COUNT"
    fi
    
    # Check triggers
    TRIGGER_COUNT=$(mysql -u "$MYSQL_USER" -h "$MYSQL_HOST" -N -e "SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema='$DB_NAME';" 2>/dev/null)
    if [ "$TRIGGER_COUNT" -ge 7 ]; then
        log_success "Created $TRIGGER_COUNT triggers"
    else
        log_warning "Expected 7 triggers, found $TRIGGER_COUNT"
    fi
    
    # Check views
    VIEW_COUNT=$(mysql -u "$MYSQL_USER" -h "$MYSQL_HOST" -N -e "SELECT COUNT(*) FROM information_schema.views WHERE table_schema='$DB_NAME';" 2>/dev/null)
    if [ "$VIEW_COUNT" -ge 6 ]; then
        log_success "Created $VIEW_COUNT views"
    else
        log_warning "Expected 6+ views, found $VIEW_COUNT"
    fi
    
    # Check seed data
    USER_COUNT=$(mysql -u "$MYSQL_USER" -h "$MYSQL_HOST" -N -e "SELECT COUNT(*) FROM $DB_NAME.users;" 2>/dev/null)
    ITEM_COUNT=$(mysql -u "$MYSQL_USER" -h "$MYSQL_HOST" -N -e "SELECT COUNT(*) FROM $DB_NAME.items;" 2>/dev/null)
    CLAIM_COUNT=$(mysql -u "$MYSQL_USER" -h "$MYSQL_HOST" -N -e "SELECT COUNT(*) FROM $DB_NAME.claims;" 2>/dev/null)
    
    log_success "Seed data loaded: $USER_COUNT users, $ITEM_COUNT items, $CLAIM_COUNT claims"
}

show_summary() {
    echo ""
    echo "============================================================"
    echo -e "${GREEN}DEPLOYMENT COMPLETED SUCCESSFULLY${NC}"
    echo "============================================================"
    echo ""
    echo "Database: $DB_NAME"
    echo "Host: $MYSQL_HOST"
    echo ""
    echo "Quick Start:"
    echo "  mysql -u $MYSQL_USER -h $MYSQL_HOST $DB_NAME"
    echo ""
    echo "Test a procedure:"
    echo "  CALL sp_get_admin_dashboard_data();"
    echo ""
    echo "Next Steps:"
    echo "  1. Review docs/STAGE_1_SUMMARY.md for verification queries"
    echo "  2. Test stored procedures with sample data"
    echo "  3. Proceed to Stage 2 (Frontend Development)"
    echo ""
    echo "============================================================"
}

# Main execution
main() {
    echo ""
    echo "============================================================"
    echo "Centralized Campus Lost & Found System"
    echo "Stage 1 Database Deployment"
    echo "============================================================"
    echo ""
    
    check_mysql_connection
    
    echo ""
    log_info "Starting deployment sequence..."
    echo ""
    
    # Execute SQL files in order
    execute_sql_file "$SQL_DIR/schema/01_core_schema.sql" "Core Schema"
    execute_sql_file "$SQL_DIR/indexes/01_indexes.sql" "Indexes"
    execute_sql_file "$SQL_DIR/views/01_views.sql" "Views"
    execute_sql_file "$SQL_DIR/procedures/01_procedures.sql" "Stored Procedures"
    execute_sql_file "$SQL_DIR/triggers/01_triggers.sql" "Triggers"
    execute_sql_file "$SQL_DIR/seed/01_seed_data.sql" "Seed Data"
    
    echo ""
    verify_installation
    
    show_summary
}

# Run main function
main
