# SQL - Sushi.Bar
I built a relational database, _Crescent Sushi Bar_, for a fictional restaurant with online ordering and dinner reservations. It covers customers, menu items, payment info, reservations, orders, and order line items. This was the final project for CWEB 1226 - Database I.
## Project - Crescent Sushi Bar Database

- **Schema Design (DDL)**: `customers`, `menu_items`, `payment_info`, `dinner_reservations`, `online_orders`, `order_items`

  I designed six tables in third normal form and connected them with primary and foreign keys. I chose each referential action on purpose: deleting a customer cascades to their payment info, reservations, and orders, while deleting a payment method sets the order's `payment_id` to `NULL` so order history survives. Menu items that appear on an order can't be deleted. I stored only `card_last_four` instead of full card numbers, and `order_items.unit_price` records the price at the time of the order so later menu changes don't alter past orders.

- **Indexes**: `idx_customers_email`, `idx_online_orders_customer`, `idx_reservations_date`, `idx_menu_category`

  I added indexes for the lookups the application would run most: finding a customer by email, pulling a customer's order history, listing reservations by date for the host stand, and filtering the menu by category.

- **Roles and Permissions**: `sushi_admin`, `sushi_staff`, `sushi_readonly`

  I practiced least-privilege access. The admin role has full access, staff can read everything but only insert and update orders, order items, and reservations (so payment data is read-only to them), and the readonly role can only see menu items, orders, and reservations for display and reporting.

- **Views**: `vw_order_details`, `vw_upcoming_reservations`, `vw_menu_item_revenue`

  I used views to wrap multi-table joins so common questions can be answered with a simple `SELECT`: full order details with customer and item names, today's and future reservations with contact info, and total units sold and revenue per menu item.

- **Sample Data (DML)**: 5 customers, 15 menu items, 5 payment methods, 5 reservations, 5 orders with 17 line items

  I wrote realistic sample data to test the relationships and give the queries something to work with. The menu items and prices come from the professor's high-fidelity website design.

- **Queries (DQL)**: 10 queries

  I wrote queries covering sorting, inner and left joins, aggregation with `GROUP BY`, the views above, and a top 5 with `LIMIT`. They include revenue by order type, the most popular items, and customers who have never placed an order (a `LEFT JOIN` filtered on `IS NULL`).

## Running the Project
1. Clone the repository: `git clone (https://github.com/joey-augustin/SQL-Sushi.Bar)`
2. Open `MySQL-SushiBar.sql` in MySQL Workbench or another MySQL client
3. Run the script from top to bottom: tables, indexes, roles, views, sample data, then queries
4. Note: `CREATE ROLE IF NOT EXISTS` requires MySQL 8.0 or newer

## Technologies Used
- MySQL Workbench 8.0 CE
