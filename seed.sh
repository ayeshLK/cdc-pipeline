#!/usr/bin/env bash

# =============================================================================
# CDC Pipeline - Database Seeding Script
# =============================================================================
# Seeds the source MySQL database with sample e-commerce data and triggers
# CDC events (inserts, updates, deletes) for testing the pipeline.
# =============================================================================

set -e  # Exit on error
set -u  # Exit on undefined variable

# =============================================================================
# Configuration
# =============================================================================

# MySQL Connection Settings (can be overridden via environment variables)
MYSQL_CONTAINER="${MYSQL_CONTAINER:-mysql-source}"
MYSQL_HOST="${MYSQL_HOST:-localhost}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-root}"
MYSQL_DB="${MYSQL_DB:-ecommerce_db}"

# Script Options
SKIP_VALIDATION="${SKIP_VALIDATION:-false}"
SKIP_CDC_EVENTS="${SKIP_CDC_EVENTS:-false}"
VERBOSE="${VERBOSE:-false}"

# Colors for output
COLOR_RESET='\033[0m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_RED='\033[0;31m'
COLOR_BLUE='\033[0;34m'

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${COLOR_BLUE}ℹ️  $1${COLOR_RESET}"
}

log_success() {
    echo -e "${COLOR_GREEN}✅ $1${COLOR_RESET}"
}

log_warning() {
    echo -e "${COLOR_YELLOW}⚠️  $1${COLOR_RESET}"
}

log_error() {
    echo -e "${COLOR_RED}❌ $1${COLOR_RESET}" >&2
}

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${COLOR_BLUE}   $1${COLOR_RESET}"
    fi
}

# =============================================================================
# Validation Functions
# =============================================================================

check_docker() {
    log_verbose "Checking Docker availability..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    log_verbose "Docker is available"
}

check_container_running() {
    log_verbose "Checking if container '$MYSQL_CONTAINER' is running..."
    if ! docker ps --format '{{.Names}}' | grep -q "^${MYSQL_CONTAINER}$"; then
        log_error "MySQL container '$MYSQL_CONTAINER' is not running"
        log_error "Start it with: docker compose -f compose-infrastructure.yml up -d"
        exit 1
    fi
    log_verbose "Container is running"
}

check_database_connection() {
    log_verbose "Testing database connection..."
    if ! docker exec "$MYSQL_CONTAINER" mysql \
        -h"$MYSQL_HOST" \
        -P"$MYSQL_PORT" \
        -u"$MYSQL_USER" \
        -p"$MYSQL_PASSWORD" \
        -e "SELECT 1" &> /dev/null; then
        log_error "Cannot connect to MySQL database"
        log_error "Check credentials and ensure database is ready"
        exit 1
    fi
    log_verbose "Database connection successful"
}

check_database_exists() {
    log_verbose "Checking if database '$MYSQL_DB' exists..."
    if ! docker exec "$MYSQL_CONTAINER" mysql \
        -h"$MYSQL_HOST" \
        -P"$MYSQL_PORT" \
        -u"$MYSQL_USER" \
        -p"$MYSQL_PASSWORD" \
        -e "USE $MYSQL_DB" &> /dev/null; then
        log_error "Database '$MYSQL_DB' does not exist"
        exit 1
    fi
    log_verbose "Database exists"
}

validate_prerequisites() {
    if [[ "$SKIP_VALIDATION" == "true" ]]; then
        log_warning "Skipping prerequisite validation"
        return
    fi

    log_info "Validating prerequisites..."
    check_docker
    check_container_running
    check_database_connection
    check_database_exists
    log_success "All prerequisites validated"
}

# =============================================================================
# Database Helper Functions
# =============================================================================

execute_sql() {
    local sql="$1"
    local description="${2:-Executing SQL}"

    log_verbose "$description"

    if ! docker exec -i "$MYSQL_CONTAINER" mysql \
        -h"$MYSQL_HOST" \
        -P"$MYSQL_PORT" \
        -u"$MYSQL_USER" \
        -p"$MYSQL_PASSWORD" \
        "$MYSQL_DB" <<< "$sql" 2>&1; then
        log_error "Failed: $description"
        return 1
    fi

    return 0
}

# =============================================================================
# Data Seeding Functions
# =============================================================================

seed_products() {
    log_info "📦 Seeding products..."

    local sql="
INSERT INTO products (product_id, name, category, merchant_id, created_at, updated_at)
VALUES
    (101, 'Laptop Pro 15\"', 'Electronics', 10, NOW(), NOW()),
    (102, 'Wireless Mouse', 'Electronics', 10, NOW(), NOW()),
    (103, 'USB-C Hub', 'Electronics', 10, NOW(), NOW()),
    (201, 'Office Chair', 'Furniture', 20, NOW(), NOW()),
    (202, 'Standing Desk', 'Furniture', 20, NOW(), NOW()),
    (301, 'Coffee Maker', 'Appliances', 30, NOW(), NOW())
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    category = VALUES(category),
    updated_at = NOW();
"

    if execute_sql "$sql" "Inserting products"; then
        log_success "Products seeded successfully (6 products)"
    else
        return 1
    fi
}

seed_orders() {
    log_info "🧾 Seeding orders..."

    local sql="
INSERT INTO orders (order_id, merchant_id, customer_id, order_status, order_time, created_at, updated_at)
VALUES
    (1001, 10, 501, 'CREATED', FROM_UNIXTIME(UNIX_TIMESTAMP()), NOW(), NOW()),
    (1002, 10, 502, 'CREATED', FROM_UNIXTIME(UNIX_TIMESTAMP()), NOW(), NOW()),
    (1003, 10, 503, 'CREATED', FROM_UNIXTIME(UNIX_TIMESTAMP()), NOW(), NOW()),
    (2001, 20, 601, 'CREATED', FROM_UNIXTIME(UNIX_TIMESTAMP()), NOW(), NOW()),
    (2002, 20, 602, 'CREATED', FROM_UNIXTIME(UNIX_TIMESTAMP()), NOW(), NOW()),
    (3001, 30, 701, 'CREATED', FROM_UNIXTIME(UNIX_TIMESTAMP()), NOW(), NOW())
ON DUPLICATE KEY UPDATE
    order_status = VALUES(order_status),
    updated_at = NOW();
"

    if execute_sql "$sql" "Inserting orders"; then
        log_success "Orders seeded successfully (6 orders)"
    else
        return 1
    fi
}

seed_order_items() {
    log_info "🛒 Seeding order items..."

    local sql="
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, price, created_at, updated_at)
VALUES
    -- Order 1001 (2 items)
    (1, 1001, 101, 1, 150000.00, NOW(), NOW()),
    (2, 1001, 102, 2, 5000.00, NOW(), NOW()),
    -- Order 1002 (1 item)
    (3, 1002, 102, 1, 5000.00, NOW(), NOW()),
    -- Order 1003 (2 items)
    (4, 1003, 101, 1, 150000.00, NOW(), NOW()),
    (5, 1003, 103, 3, 8000.00, NOW(), NOW()),
    -- Order 2001 (1 item)
    (6, 2001, 201, 1, 35000.00, NOW(), NOW()),
    -- Order 2002 (2 items)
    (7, 2002, 201, 2, 35000.00, NOW(), NOW()),
    (8, 2002, 202, 1, 75000.00, NOW(), NOW()),
    -- Order 3001 (1 item)
    (9, 3001, 301, 1, 12000.00, NOW(), NOW())
ON DUPLICATE KEY UPDATE
    quantity = VALUES(quantity),
    price = VALUES(price),
    updated_at = NOW();
"

    if execute_sql "$sql" "Inserting order items"; then
        log_success "Order items seeded successfully (9 items)"
    else
        return 1
    fi
}

trigger_cdc_updates() {
    log_info "✏️  Triggering CDC update events..."

    # Update product category
    local sql1="
UPDATE products
SET category = 'Computer Accessories', updated_at = NOW()
WHERE product_id = 102;
"
    execute_sql "$sql1" "Updating product category (product_id=102)"

    # Update order status
    local sql2="
UPDATE orders
SET order_status = 'PAID', updated_at = NOW()
WHERE order_id IN (1001, 1002);
"
    execute_sql "$sql2" "Updating order status to PAID (order_id=1001,1002)"

    # Update order item price
    local sql3="
UPDATE order_items
SET price = 4500.00, updated_at = NOW()
WHERE order_item_id = 2;
"
    execute_sql "$sql3" "Updating order item price (order_item_id=2)"

    log_success "CDC update events triggered (3 updates)"
}

trigger_cdc_deletes() {
    log_info "🗑️  Triggering CDC delete events..."

    local sql="
DELETE FROM order_items WHERE order_item_id = 3;
"

    if execute_sql "$sql" "Deleting order item (order_item_id=3)"; then
        log_success "CDC delete events triggered (1 deletion)"
    else
        return 1
    fi
}

# =============================================================================
# Main Seeding Flow
# =============================================================================

seed_all_data() {
    log_info "🚀 Starting database seeding process..."
    echo ""

    # Validate prerequisites
    validate_prerequisites
    echo ""

    # Seed base data
    log_info "📊 Seeding base data..."
    seed_products || exit 1
    sleep 0.5
    seed_orders || exit 1
    sleep 0.5
    seed_order_items || exit 1
    echo ""

    # Trigger CDC events
    if [[ "$SKIP_CDC_EVENTS" == "false" ]]; then
        log_info "🔄 Triggering CDC events..."
        sleep 1  # Brief pause before triggering events
        trigger_cdc_updates || exit 1
        sleep 0.5
        trigger_cdc_deletes || exit 1
        echo ""
    else
        log_warning "Skipping CDC events (SKIP_CDC_EVENTS=true)"
        echo ""
    fi
}

# =============================================================================
# Summary and Statistics
# =============================================================================

show_summary() {
    log_info "📈 Database Statistics:"

    local stats
    stats=$(docker exec "$MYSQL_CONTAINER" mysql \
        -h"$MYSQL_HOST" \
        -P"$MYSQL_PORT" \
        -u"$MYSQL_USER" \
        -p"$MYSQL_PASSWORD" \
        "$MYSQL_DB" \
        -e "
        SELECT 'Products' as Table_Name, COUNT(*) as Count FROM products
        UNION ALL
        SELECT 'Orders', COUNT(*) FROM orders
        UNION ALL
        SELECT 'Order Items', COUNT(*) FROM order_items;
        " 2>/dev/null)

    echo "$stats"
    echo ""
}

# =============================================================================
# Script Entry Point
# =============================================================================

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Seeds the MySQL source database with sample e-commerce data.

Options:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -s, --skip-validation   Skip prerequisite validation checks
    -c, --skip-cdc          Skip CDC event triggers (updates/deletes)

Environment Variables:
    MYSQL_CONTAINER         MySQL container name (default: mysql-source)
    MYSQL_HOST              MySQL host (default: localhost)
    MYSQL_PORT              MySQL port (default: 3306)
    MYSQL_USER              MySQL user (default: root)
    MYSQL_PASSWORD          MySQL password (default: root)
    MYSQL_DB                MySQL database (default: ecommerce_db)

Examples:
    # Standard seeding
    ./seed.sh

    # Verbose mode
    ./seed.sh --verbose

    # Seed without triggering CDC events
    ./seed.sh --skip-cdc

    # Custom configuration
    MYSQL_PORT=3307 MYSQL_USER=admin ./seed.sh

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -s|--skip-validation)
            SKIP_VALIDATION=true
            shift
            ;;
        -c|--skip-cdc)
            SKIP_CDC_EVENTS=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "  CDC Pipeline - Database Seeding"
    echo "════════════════════════════════════════════════════════════════"
    echo ""

    log_verbose "Configuration:"
    log_verbose "  Container: $MYSQL_CONTAINER"
    log_verbose "  Host:      $MYSQL_HOST:$MYSQL_PORT"
    log_verbose "  User:      $MYSQL_USER"
    log_verbose "  Database:  $MYSQL_DB"
    echo ""

    # Execute seeding
    seed_all_data

    # Show summary
    show_summary

    # Success message
    echo "════════════════════════════════════════════════════════════════"
    log_success "Seeding completed successfully!"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    log_info "Next steps:"
    echo "  1. Verify CDC events in Kafka topics"
    echo "  2. Check cache-enricher logs for cached data"
    echo "  3. Query analytics API for aggregated results"
    echo ""
}

# Run main function
main
