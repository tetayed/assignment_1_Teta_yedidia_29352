

-- Clean up existing tables if rerun
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- 1. Table Definitions (Adapted for PostgreSQL)
CREATE TABLE customers (
  customer_id INT PRIMARY KEY,
  customer_name VARCHAR(100),
  email VARCHAR(100),
  city VARCHAR(50)
);

CREATE TABLE products (
  product_id INT PRIMARY KEY,
  product_name VARCHAR(100),
  category VARCHAR(50),
  price NUMERIC(10,2)
);

CREATE TABLE orders (
  order_id INT PRIMARY KEY,
  customer_id INT REFERENCES customers(customer_id),
  order_date DATE
);

CREATE TABLE order_items (
  order_item_id INT PRIMARY KEY,
  order_id INT REFERENCES orders(order_id),
  product_id INT REFERENCES products(product_id),
  quantity INT
);

-- 2. Data Population
-- Customers (6 customers; Customer 6 has no orders to test LEFT JOIN)
INSERT INTO customers (customer_id, customer_name, email, city) VALUES
(1, 'Alice Smith', 'alice@example.com', 'Kigali'),
(2, 'Bob Jones', 'bob@example.com', 'Musanze'),
(3, 'Charlie Brown', 'charlie@example.com', 'Huye'),
(4, 'Diana Prince', 'diana@example.com', 'Kigali'),
(5, 'Evan Wright', 'evan@example.com', 'Rubavu'),
(6, 'Fiona Gallagher', 'fiona@example.com', 'Kigali');

-- Products (9 products across 4 categories: Dairy, Bakery, Produce, Beverages)
INSERT INTO products (product_id, product_name, category, price) VALUES
(101, 'Fresh Whole Milk 1L', 'Dairy', 2.50),
(102, 'Cheddar Cheese 250g', 'Dairy', 4.50),
(103, 'Sourdough Bread', 'Bakery', 3.00),
(104, 'Butter Croissant', 'Bakery', 1.75),
(105, 'Organic Apples 1kg', 'Produce', 3.50),
(106, 'Cavendish Bananas 1kg', 'Produce', 1.80),
(107, 'Baby Spinach 200g', 'Produce', 2.20),
(108, 'Ground Arabica Coffee', 'Beverages', 8.00),
(109, 'Sparkling Water 500ml', 'Beverages', 1.25);

-- Orders (16 orders across multiple dates)
INSERT INTO orders (order_id, customer_id, order_date) VALUES
(1001, 1, '2026-08-01'),
(1002, 2, '2026-08-02'),
(1003, 3, '2026-08-03'),
(1004, 1, '2026-08-05'),
(1005, 4, '2026-08-06'),
(1006, 5, '2026-08-07'),
(1007, 2, '2026-08-10'),
(1008, 3, '2026-08-12'),
(1009, 1, '2026-08-15'),
(1010, 4, '2026-08-18'),
(1011, 5, '2026-08-20'),
(1012, 2, '2026-08-22'),
(1013, 3, '2026-08-25'),
(1014, 1, '2026-08-27'),
(1015, 4, '2026-08-29'),
(1016, 5, '2026-08-30');

-- Order Items (28 items across the 16 orders)
INSERT INTO order_items (order_item_id, order_id, product_id, quantity) VALUES
(1, 1001, 101, 2),
(2, 1001, 103, 1),
(3, 1002, 108, 1),
(4, 1002, 104, 3),
(5, 1003, 105, 2),
(6, 1004, 102, 1),
(7, 1004, 108, 2),
(8, 1005, 106, 4),
(9, 1005, 107, 2),
(10, 1006, 101, 3),
(11, 1007, 103, 2),
(12, 1007, 109, 4),
(13, 1008, 108, 1),
(14, 1008, 102, 2),
(15, 1009, 105, 3),
(16, 1010, 101, 1),
(17, 1010, 104, 2),
(18, 1011, 108, 1),
(19, 1012, 106, 2),
(20, 1012, 107, 1),
(21, 1013, 103, 1),
(22, 1013, 109, 2),
(23, 1014, 102, 1),
(24, 1014, 108, 1),
(25, 1015, 105, 2),
(26, 1015, 101, 2),
(27, 1016, 104, 4),
(28, 1016, 109, 3);
