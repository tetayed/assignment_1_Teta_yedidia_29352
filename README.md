# PLSQL Assignment One - Sunrise Supermarket

Teta Yedidia
**Reg No:** 29352  
**DBMS Used:** PostgreSQL (via pgAdmin 4)

---

## 1. Project Summary
This repository contains the database schema, data population scripts, and analytical queries for Sunrise Supermarket. The goal of this project is to model a retail environment and extract actionable business intelligence regarding customer demographics, purchasing habits, and revenue trends using advanced SQL techniques (JOINs, CTEs, and Window Functions).

## 2. How to Run
1. Ensure **PostgreSQL** and **pgAdmin 4** (or `psql`) are installed on your system.
2. Clone this repository to your local machine.
3. Open pgAdmin 4 and connect to your desired database.
4. Open the Query Tool and execute the provided `queries.sql` file to create the tables, seed the data, and run the analytical queries.
   

---

## 3. Business Scenario
Sunrise Supermarket sells daily consumer goods across various categories (Dairy, Bakery, Produce, Beverages). Management requires a deeper understanding of their sales operations to answer the following:
* Who are the most valuable customers?
* What is the frequency of repeat purchases?
* How is revenue trending over time?

The database consists of four tables: `customers`, `products`, `orders`, and `order_items`, seeded with 6 customers, 9 products, 16 orders, and 28 order items.

---

## 4. Analytical Queries & Explanations

### A. JOIN Queries

**1. Customer Order History (INNER JOIN)**
* **Explanation:** Joins `orders` and `customers` to map every transaction to a specific customer's demographic data (name and city).
```sql
SELECT o.order_id, c.customer_name, c.city, o.order_date
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_id;
```
* **Sample Result:** Returns 16 rows detailing who made each order and when.

**2. Itemized Order Details (INNER JOIN)**
* **Explanation:** Links `order_items` with `products` to decode product IDs into readable names, categories, and financial metrics (price and quantity).
```sql
SELECT oi.order_item_id, oi.order_id, p.product_name, p.category, p.price, oi.quantity
FROM order_items oi
INNER JOIN products p ON oi.product_id = p.product_id
ORDER BY oi.order_item_id;
```
* **Sample Result:** Returns 28 rows breaking down the exact contents of every basket.

**3. Complete Customer Roster Activity (LEFT JOIN)**
* **Explanation:** Uses a LEFT JOIN starting from `customers` to ensure all registered users are listed, even if they have not yet made a purchase.
```sql
SELECT c.customer_id, c.customer_name, c.city, o.order_id, o.order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;
```
* **Sample Result:** Returns 17 rows. Customer "Fiona Gallagher" appears with `NULL` for `order_id` and `order_date`, proving she has no orders.

---

### B. Common Table Expression (CTE)

**1. High-Value Customers (Above Average Spend)**
* **Explanation:** Uses a two-step CTE. The first calculates total spend per customer. The second calculates the overall store average. The main query filters for customers exceeding that average.
```sql
WITH customer_spending AS (
    SELECT c.customer_id, c.customer_name, COALESCE(SUM(oi.quantity * p.price), 0) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.customer_name
),
average_spending AS (
    SELECT AVG(total_spent) AS avg_spend FROM customer_spending
)
SELECT cs.customer_id, cs.customer_name, cs.total_spent, ROUND(a.avg_spend, 2) AS overall_avg_spent
FROM customer_spending cs
CROSS JOIN average_spending a
WHERE cs.total_spent > a.avg_spend
ORDER BY cs.total_spent DESC;
```

---

### C. Window Function Queries

**1. Customer Spending Rank**
* **Explanation:** Uses `DENSE_RANK()` over the aggregated total spend to rank customers. `DENSE_RANK` ensures no numerical gaps in the ranking if two customers spend the exact same amount.
```sql
WITH customer_totals AS (
    SELECT c.customer_id, c.customer_name, COALESCE(SUM(oi.quantity * p.price), 0) AS total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT customer_id, customer_name, total_spent,
       DENSE_RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
FROM customer_totals
ORDER BY spending_rank;
```

**2. Sequential Order Numbering**
* **Explanation:** Applies `ROW_NUMBER()` partitioned by `customer_id` and ordered chronologically to label a customer's 1st, 2nd, and 3rd order.
```sql
SELECT customer_id, order_id, order_date,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS customer_order_seq
FROM orders
ORDER BY customer_id, customer_order_seq;
```

**3. Running Total of Revenue**
* **Explanation:** Pre-calculates daily order totals in a CTE, then uses a windowed `SUM()` bounded from the start of the dataset to the current row to track cumulative revenue growth.
```sql
WITH daily_order_revenue AS (
    SELECT o.order_id, o.order_date, SUM(oi.quantity * p.price) AS order_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY o.order_id, o.order_date
)
SELECT order_id, order_date, order_revenue,
       SUM(order_revenue) OVER (ORDER BY order_date, order_id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_revenue
FROM daily_order_revenue
ORDER BY order_date, order_id;
```

**4. Purchase Velocity (Days Between Orders)**
* **Explanation:** Uses the `LAG()` function to fetch the date of a customer's previous order. A windowed `COUNT()` is used to exclude one-time buyers. Subtracting the dates yields the day interval.
```sql
WITH customer_order_lags AS (
    SELECT customer_id, order_id, order_date,
           LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS previous_order_date,
           COUNT(*) OVER (PARTITION BY customer_id) AS total_customer_orders
    FROM orders
)
SELECT customer_id, order_id, order_date, previous_order_date,
       (order_date - previous_order_date) AS days_since_last_order
FROM customer_order_lags
WHERE total_customer_orders > 1
ORDER BY customer_id, order_date;
```

---

## 5. Business Interpretation
Based on the data analysis:
1. **Customer Retention:** High-value customers like Alice and Charlie have a strong repeat purchase rate, often returning within 2 to 7 days. This indicates high satisfaction with staple goods.
2. **Dormant Accounts:** Fiona Gallagher registered but made no purchases. Marketing should target dormant accounts with introductory discounts to drive first-time conversion.
3. **Revenue Trajectory:** The running total indicates steady, uninterrupted growth throughout the month, primarily driven by multi-item baskets featuring both produce and beverages.

---

## 6. Challenges & Resolutions
* **Challenge:** The initial schema provided in the assignment used Oracle-specific data types (`VARCHAR2` and `NUMBER`). When executed in PostgreSQL, this resulted in syntax errors.
* **Resolution:** I adapted the schema to standard PostgreSQL data types. `VARCHAR2` was converted to `VARCHAR`, and `NUMBER` was converted to `INT` for primary/foreign keys and `NUMERIC(10,2)` for prices to ensure data integrity and proper mathematical calculations.
* **Challenge:** Filtering out one-time buyers when using the `LAG()` window function.
* **Resolution:** Standard `WHERE` clauses evaluate before window functions, meaning I could not directly filter on the window result. I resolved this by wrapping the window logic inside a CTE (`customer_order_lags`) and applying the filter (`total_customer_orders > 1`) in the outer query.
