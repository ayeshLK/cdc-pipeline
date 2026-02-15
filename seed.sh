#!/usr/bin/env bash
set -e

MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=root
MYSQL_DB=ecommerce_db

MYSQL="docker exec -i mysql-source mysql -h$MYSQL_HOST -P$MYSQL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DB"

echo "🚀 Seeding source database..."

# ----------------------
# PRODUCTS
# ----------------------
echo "📦 Inserting products..."
$MYSQL <<EOF
INSERT INTO products (product_id, name, category, merchant_id, created_at, updated_at)
VALUES
  (101, 'Laptop Pro', 'Electronics', 10, NOW(), NOW()),
  (102, 'Wireless Mouse', 'Electronics', 10, NOW(), NOW()),
  (201, 'Office Chair', 'Furniture', 20, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  category = VALUES(category),
  updated_at = NOW();
EOF

# ----------------------
# ORDERS
# ----------------------
echo "🧾 Inserting orders..."
$MYSQL <<EOF
INSERT INTO orders (order_id, merchant_id, customer_id, order_status, order_time, created_at, updated_at)
VALUES
  (1001, 10, 501, 'CREATED', FROM_UNIXTIME(UNIX_TIMESTAMP()), NOW(), NOW()),
  (1002, 10, 502, 'CREATED', FROM_UNIXTIME(UNIX_TIMESTAMP()), NOW(), NOW()),
  (2001, 20, 601, 'CREATED', FROM_UNIXTIME(UNIX_TIMESTAMP()), NOW(), NOW())
ON DUPLICATE KEY UPDATE
  order_status = VALUES(order_status),
  updated_at = NOW();
EOF

# ----------------------
# ORDER ITEMS
# ----------------------
echo "🛒 Inserting order items..."
$MYSQL <<EOF
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, price, created_at, updated_at)
VALUES
  (1, 1001, 101, 1, 150000.00, NOW(), NOW()),
  (2, 1001, 102, 2, 5000.00, NOW(), NOW()),
  (3, 1002, 102, 1, 5000.00, NOW(), NOW()),
  (4, 2001, 201, 1, 35000.00, NOW(), NOW())
ON DUPLICATE KEY UPDATE
  quantity = VALUES(quantity),
  price = VALUES(price),
  updated_at = NOW();
EOF

# ----------------------
# UPDATES (CDC UPDATE EVENTS)
# ----------------------
echo "✏️ Updating product category..."
$MYSQL <<EOF
UPDATE products
SET category = 'Computer Accessories', updated_at = NOW()
WHERE product_id = 102;
EOF

echo "✏️ Updating order status..."
$MYSQL <<EOF
UPDATE orders
SET order_status = 'PAID', updated_at = NOW()
WHERE order_id = 1001;
EOF

# ----------------------
# DELETE (CDC DELETE EVENT)
# ----------------------
echo "🗑️ Deleting an order item..."
$MYSQL <<EOF
DELETE FROM order_items WHERE order_item_id = 3;
EOF

echo "✅ Seeding completed successfully!"
