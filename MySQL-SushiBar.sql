-- =============================================================
--  Crescent Sushi Bar Database
--  CWEB 1226 - Final Project
-- =============================================================

-- =============================================================
--  DDL - Create Tables
-- =============================================================

CREATE DATABASE sushiBar

CREATE TABLE customers (
    customer_id INT NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    address VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (customer_id)
);

CREATE TABLE menu_items (
    item_id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT,
    price DECIMAL(6,2) NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (item_id)
);

CREATE TABLE payment_info (
    payment_id INT NOT NULL AUTO_INCREMENT,
    customer_id INT NOT NULL,
    card_last_four CHAR(4) NOT NULL,
    card_type VARCHAR(20) NOT NULL,
    billing_address VARCHAR(255),
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (payment_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE dinner_reservations (
    reservation_id INT NOT NULL AUTO_INCREMENT,
    customer_id INT NOT NULL,
    reservation_date DATE NOT NULL,
    reservation_time TIME NOT NULL,
    party_size INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending', -- Pending, Confirmed, Cancelled
    special_requests TEXT,
    PRIMARY KEY (reservation_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE online_orders (
    order_id INT NOT NULL AUTO_INCREMENT,
    customer_id INT NOT NULL,
    payment_id INT,
    order_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    order_status VARCHAR(20) NOT NULL DEFAULT 'Received', -- Received, Preparing, Ready, Delivered
    total_amount DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    delivery_address VARCHAR(255),
    order_type VARCHAR(20) NOT NULL, -- 'Delivery' or 'Pickup'
    PRIMARY KEY (order_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (payment_id) REFERENCES payment_info(payment_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE order_items (
    order_item_id INT NOT NULL AUTO_INCREMENT,
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(6,2) NOT NULL,
    PRIMARY KEY (order_item_id),
    FOREIGN KEY (order_id) REFERENCES online_orders(order_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (item_id) REFERENCES menu_items(item_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- =============================================================
--  Indexes
-- =============================================================

-- Speed up customer lookups by email (login, search)
CREATE INDEX idx_customers_email ON customers(email);

-- Speed up order history queries per customer
CREATE INDEX idx_online_orders_customer ON online_orders(customer_id);

-- Speed up reservation lookups by date (host stand view)
CREATE INDEX idx_reservations_date ON dinner_reservations(reservation_date);

-- Speed up menu queries by category (menu page filter)
CREATE INDEX idx_menu_category ON menu_items(category);

-- =============================================================
--  Roles
-- =============================================================

CREATE ROLE IF NOT EXISTS 'sushi_admin';
CREATE ROLE IF NOT EXISTS 'sushi_staff';
CREATE ROLE IF NOT EXISTS 'sushi_readonly';

-- Admin: full access to all tables
GRANT ALL PRIVILEGES ON sushi_bar.* TO 'sushi_admin';

-- Staff: can read everything, insert/update orders and reservations, cannot touch payment data
GRANT SELECT ON sushi_bar.* TO 'sushi_staff';
GRANT INSERT, UPDATE ON sushi_bar.online_orders TO 'sushi_staff';
GRANT INSERT, UPDATE ON sushi_bar.order_items TO 'sushi_staff';
GRANT INSERT, UPDATE ON sushi_bar.dinner_reservations TO 'sushi_staff';

-- Readonly: menu display, reporting
GRANT SELECT ON sushi_bar.menu_items TO 'sushi_readonly';
GRANT SELECT ON sushi_bar.online_orders TO 'sushi_readonly';
GRANT SELECT ON sushi_bar.dinner_reservations TO 'sushi_readonly';

-- =============================================================
--  Views
-- =============================================================

-- Full order details joined with customer and item names
CREATE VIEW vw_order_details AS
SELECT
    o.order_id,
    o.order_time,
    o.order_type,
    o.order_status,
    o.total_amount,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    m.name AS item_name,
    m.category,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS line_total
FROM online_orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN menu_items m  ON oi.item_id = m.item_id;

-- Upcoming reservations (today and future) with customer info
CREATE VIEW vw_upcoming_reservations AS
SELECT
    r.reservation_id,
    r.reservation_date,
    r.reservation_time,
    r.party_size,
    r.status,
    r.special_requests,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.phone,
    c.email
FROM dinner_reservations r
JOIN customers c ON r.customer_id = c.customer_id
WHERE r.reservation_date >= CURDATE()
ORDER BY r.reservation_date, r.reservation_time;

-- Revenue summary per menu item
CREATE VIEW vw_menu_item_revenue AS
SELECT
    m.item_id,
    m.name,
    m.category,
    m.price AS current_price,
    SUM(oi.quantity) AS total_sold,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM menu_items m
LEFT JOIN order_items oi ON m.item_id = oi.item_id
GROUP BY m.item_id, m.name, m.category, m.price;

-- =============================================================
--  DML � Insert Sample Data
-- =============================================================

-- Customers
INSERT INTO customers (first_name, last_name, email, phone, address) VALUES
    ('Alice',   'Tanaka',  'alice.tanaka@email.com',   '651-555-0101', '100 Maple St, St. Paul, MN 55101'),
    ('Ben',     'Nguyen',  'ben.nguyen@email.com',     '612-555-0202', '200 Oak Ave, Minneapolis, MN 55401'),
    ('Clara',   'Kim',     'clara.kim@email.com',      '651-555-0303', '300 Pine Rd, Eagan, MN 55122'),
    ('David',   'Patel',   'david.patel@email.com',    '763-555-0404', '400 Elm Blvd, Burnsville, MN 55337'),
    ('Eva',     'Lopez',   'eva.lopez@email.com',      '952-555-0505', '500 Cedar Ln, Bloomington, MN 55420');

-- Menu items (representative sample � full import would come from the provided menu file)
INSERT INTO menu_items (name, category, description, price, is_available) VALUES
    ('Edamame',           'Appetizer', 'Steamed salted soybeans',                             5.00,  TRUE),
    ('Miso Soup',         'Appetizer', 'Tofu, wakame, and green onion in dashi broth',        3.50,  TRUE),
    ('Gyoza',             'Appetizer', 'Pan-fried pork and cabbage dumplings (6 pc)',         7.50,  TRUE),
    ('Salmon Nigiri',     'Nigiri',    'Two pieces fresh Atlantic salmon over rice',          6.50,  TRUE),
    ('Tuna Nigiri',       'Nigiri',    'Two pieces bluefin tuna over rice',                   7.00,  TRUE),
    ('Yellowtail Nigiri', 'Nigiri',    'Two pieces yellowtail over rice',                     7.00,  TRUE),
    ('California Roll',   'Roll',      'Crab, avocado, cucumber (8 pc)',                      8.50,  TRUE),
    ('Spicy Tuna Roll',   'Roll',      'Tuna, spicy mayo, cucumber (8 pc)',                   9.50,  TRUE),
    ('Dragon Roll',       'Roll',      'Shrimp tempura topped with avocado and eel (8 pc)',   13.00, TRUE),
    ('Rainbow Roll',      'Roll',      'California roll topped with assorted sashimi (8 pc)', 14.00, TRUE),
    ('Salmon Sashimi',    'Sashimi',   'Five slices fresh Atlantic salmon',                   12.00, TRUE),
    ('Mochi Ice Cream',   'Dessert',   'Three pieces � choice of flavors',                    6.00,  TRUE),
    ('Green Tea',         'Drink',     'Hot or iced',                                         3.00,  TRUE),
    ('Sake',              'Drink',     'House sake, 6 oz',                                    8.00,  TRUE),
    ('Soda',              'Drink',     'Pepsi, Diet Pepsi, or Starry',                        3.00,  TRUE);

-- Payment info
INSERT INTO payment_info (customer_id, card_last_four, card_type, billing_address, is_default) VALUES
    (1, '4242', 'Visa',       '100 Maple St, St. Paul, MN 55101',       TRUE),
    (2, '5353', 'Mastercard', '200 Oak Ave, Minneapolis, MN 55401',     TRUE),
    (3, '1111', 'Visa',       '300 Pine Rd, Eagan, MN 55122',           TRUE),
    (4, '2222', 'Amex',       '400 Elm Blvd, Burnsville, MN 55337',     TRUE),
    (5, '3333', 'Discover',   '500 Cedar Ln, Bloomington, MN 55420',    TRUE);

-- Dinner reservations
INSERT INTO dinner_reservations (customer_id, reservation_date, reservation_time, party_size, status, special_requests) VALUES
    (1, '2026-05-22', '18:00:00', 2, 'Confirmed', 'Window seat preferred'),
    (2, '2026-05-22', '19:30:00', 4, 'Confirmed', NULL),
    (3, '2026-05-23', '17:30:00', 2, 'Pending',   'Gluten-free options needed'),
    (4, '2026-05-24', '20:00:00', 6, 'Confirmed', 'Birthday celebration � please have candles ready'),
    (5, '2026-05-25', '18:30:00', 3, 'Pending',   NULL);

-- Online orders
INSERT INTO online_orders (customer_id, payment_id, order_status, total_amount, delivery_address, order_type) VALUES
    (1, 1, 'Delivered', 32.00, '100 Maple St, St. Paul, MN 55101',    'Delivery'),
    (2, 2, 'Preparing', 27.50, NULL,                                   'Pickup'),
    (3, 3, 'Received',  45.00, '300 Pine Rd, Eagan, MN 55122',        'Delivery'),
    (4, 4, 'Ready',     19.00, NULL,                                   'Pickup'),
    (5, 5, 'Delivered', 38.50, '500 Cedar Ln, Bloomington, MN 55420', 'Delivery');

-- Order items
INSERT INTO order_items (order_id, item_id, quantity, unit_price) VALUES
    -- Order 1: Alice � Delivery
    (1, 7,  1,  8.50),   -- California Roll
    (1, 8,  1,  9.50),   -- Spicy Tuna Roll
    (1, 1,  1,  5.00),   -- Edamame
    (1, 13, 1,  3.00),   -- Green Tea
    -- Order 2: Ben � Pickup
    (2, 4,  2,  6.50),   -- Salmon Nigiri x2
    (2, 5,  2,  7.00),   -- Tuna Nigiri x2
    -- Order 3: Clara � Delivery
    (3, 9,  1, 13.00),   -- Dragon Roll
    (3, 10, 1, 14.00),   -- Rainbow Roll
    (3, 2,  2,  3.50),   -- Miso Soup x2
    (3, 12, 1,  6.00),   -- Mochi Ice Cream
    -- Order 4: David � Pickup
    (4, 3,  1,  7.50),   -- Gyoza
    (4, 2,  1,  3.50),   -- Miso Soup
    (4, 13, 2,  3.00),   -- Green Tea x2
    -- Order 5: Eva � Delivery
    (5, 11, 1, 12.00),   -- Salmon Sashimi
    (5, 8,  1,  9.50),   -- Spicy Tuna Roll
    (5, 14, 1,  8.00),   -- Sake
    (5, 1,  1,  5.00);   -- Edamame

-- =============================================================
--  DQL � Queries
-- =============================================================

-- 1. All menu items, sorted by category then price
SELECT item_id, name, category, price, is_available
FROM menu_items
ORDER BY category, price;

-- 2. All upcoming reservations (using view)
SELECT * FROM vw_upcoming_reservations;

-- 3. Full details for a specific order
SELECT *
FROM vw_order_details
WHERE order_id = 3;

-- 4. All orders for a specific customer (by email)
SELECT o.order_id, o.order_time, o.order_type, o.order_status, o.total_amount
FROM online_orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE c.email = 'clara.kim@email.com'
ORDER BY o.order_time DESC;

-- 5. Revenue per menu item (using view)
SELECT name, category, current_price, total_sold, total_revenue
FROM vw_menu_item_revenue
ORDER BY total_revenue DESC;

-- 6. Most popular items (by quantity sold)
SELECT m.name, m.category, SUM(oi.quantity) AS times_ordered
FROM order_items oi
JOIN menu_items m ON oi.item_id = m.item_id
GROUP BY m.item_id, m.name, m.category
ORDER BY times_ordered DESC
LIMIT 5;

-- 7. Customers who have placed at least one order
SELECT DISTINCT c.customer_id, c.first_name, c.last_name, c.email
FROM customers c
INNER JOIN online_orders o ON c.customer_id = o.customer_id;

-- 8. Customers who have NOT placed any orders
SELECT c.customer_id, c.first_name, c.last_name, c.email
FROM customers c
LEFT JOIN online_orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- 9. Total revenue by order type (Delivery vs Pickup)
SELECT order_type, COUNT(*) AS order_count, SUM(total_amount) AS revenue
FROM online_orders
GROUP BY order_type;

-- 10. Reservations for a specific date with customer info
SELECT r.reservation_time, r.party_size, r.status,
       CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
       c.phone, r.special_requests
FROM dinner_reservations r
JOIN customers c ON r.customer_id = c.customer_id
WHERE r.reservation_date = '2026-05-22'
ORDER BY r.reservation_time;