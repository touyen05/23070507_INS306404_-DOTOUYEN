-- INS3064 Homework 06 - Online Bookstore
-- MariaDB 10.4+ / MySQL 8 compatible
-- FIXED: removes CHECK referencing AUTO_INCREMENT category_id (MariaDB error 1901).
-- Uses a new database homework06_bookstore so prior partially imported bookstore_db is untouched.
-- Creates a separate database. Do not run against existing project databases.

CREATE DATABASE IF NOT EXISTS homework06_bookstore CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE homework06_bookstore;

/*
3NF explanation:
1NF: Each field holds one atomic value, no comma-separated authors or categories.
2NF: In junction tables with composite keys, there are no non-key fields
    dependent on only one part of the composite key.
3NF: Author, publisher, category and customer details belong to their own tables.
    Book records reference publishers by publisher_id instead of repeating their
    names/addresses. Order lines snapshot the transactional unit_price, which
    is distinct from a book's current catalog price.
    order_items.subtotal is GENERATED from quantity * unit_price.
    orders.total_amount is a deliberate transaction summary for a historical
    order; maintain it from order items in application logic/transactions.
*/

CREATE TABLE authors (
  author_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(150) NOT NULL,
  biography TEXT NULL,
  nationality VARCHAR(80) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE publishers (
  publisher_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  publisher_name VARCHAR(150) NOT NULL UNIQUE,
  address VARCHAR(255) NULL,
  website VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE categories (
  category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT NULL,
  parent_category_id INT UNSIGNED NULL,
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id)
    REFERENCES categories(category_id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE books (
  book_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  isbn VARCHAR(20) NOT NULL UNIQUE,
  publisher_id INT UNSIGNED NOT NULL,
  price DECIMAL(12,2) NOT NULL,
  stock INT UNSIGNED NOT NULL DEFAULT 0,
  publication_date DATE NULL,
  description TEXT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT ck_books_price CHECK (price > 0),
  CONSTRAINT ck_books_stock CHECK (stock >= 0),
  CONSTRAINT fk_books_publisher FOREIGN KEY (publisher_id)
    REFERENCES publishers(publisher_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE book_authors (
  book_id INT UNSIGNED NOT NULL,
  author_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (book_id, author_id),
  CONSTRAINT fk_ba_book FOREIGN KEY (book_id) REFERENCES books(book_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_ba_author FOREIGN KEY (author_id) REFERENCES authors(author_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE book_categories (
  book_id INT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (book_id, category_id),
  CONSTRAINT fk_bc_book FOREIGN KEY (book_id) REFERENCES books(book_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_bc_category FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE customers (
  customer_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  phone VARCHAR(20) NULL,
  address VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE orders (
  order_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id INT UNSIGNED NOT NULL,
  order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('pending','confirmed','shipped','delivered','cancelled') NOT NULL DEFAULT 'pending',
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
  shipping_address VARCHAR(255) NOT NULL,
  CONSTRAINT ck_orders_total CHECK (total_amount >= 0),
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE order_items (
  order_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id INT UNSIGNED NOT NULL,
  book_id INT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  subtotal DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  UNIQUE KEY uq_order_book (order_id, book_id),
  CONSTRAINT ck_items_quantity CHECK (quantity > 0),
  CONSTRAINT ck_items_unit_price CHECK (unit_price > 0),
  CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_items_book FOREIGN KEY (book_id) REFERENCES books(book_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE reviews (
  review_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id INT UNSIGNED NOT NULL,
  book_id INT UNSIGNED NOT NULL,
  rating TINYINT UNSIGNED NOT NULL,
  comment TEXT NULL,
  review_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_review_customer_book (customer_id, book_id),
  CONSTRAINT ck_reviews_rating CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_reviews_book FOREIGN KEY (book_id) REFERENCES books(book_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO authors (full_name, biography, nationality) VALUES
('Nguyen Nhat Anh','Vietnamese novelist','Vietnam'),
('To Hoai','Vietnamese author','Vietnam'),
('Nam Cao','Vietnamese writer','Vietnam'),
('Paulo Coelho','Brazilian novelist','Brazil'),
('George Orwell','English novelist','United Kingdom'),
('J.K. Rowling','Fantasy author','United Kingdom');

INSERT INTO publishers (publisher_name, address, website) VALUES
('NXB Tre','Ho Chi Minh City','https://www.nxbtre.com.vn'),
('NXB Kim Dong','Hanoi','https://nxbkimdong.com.vn'),
('NXB Van Hoc','Hanoi',NULL),
('Bloomsbury Publishing','London','https://www.bloomsbury.com');

INSERT INTO categories (category_name, description, parent_category_id) VALUES
('Fiction','Fictional literature',NULL),
('Children','Children literature',NULL),
('Fantasy','Fantasy fiction',1),
('Classics','Classic literary works',1),
('Adventure','Adventure stories',1);

INSERT INTO books (title,isbn,publisher_id,price,stock,publication_date,description) VALUES
('Cho Toi Xin Mot Ve Di Tuoi Tho','9786041000001',1,85000,30,'2008-01-01','A story about childhood'),
('Mat Biec','9786041000002',1,105000,22,'1990-01-01','Vietnamese coming-of-age novel'),
('De Men Phieu Luu Ky','9786041000003',2,75000,40,'1941-01-01','The adventures of a cricket'),
('Chi Pheo','9786041000004',3,65000,18,'1941-01-01','A classic short story'),
('The Alchemist','9780061122415',3,135000,25,'1988-01-01','A philosophical novel'),
('1984','9780451524935',3,145000,12,'1949-06-08','Dystopian classic'),
('Animal Farm','9780451526342',3,95000,15,'1945-08-17','Political allegory'),
('Harry Potter and the Philosophers Stone','9780747532699',4,225000,35,'1997-06-26','A fantasy adventure');

INSERT INTO book_authors (book_id,author_id) VALUES
(1,1),(2,1),(3,2),(4,3),(5,4),(6,5),(7,5),(8,6);

INSERT INTO book_categories (book_id,category_id) VALUES
(1,1),(1,2),(2,1),(3,2),(3,5),(4,4),(5,1),(5,5),(6,1),(6,4),(7,1),(7,4),(8,2),(8,3),(8,5);

-- Sample hashes are placeholders and not valid login credentials.
INSERT INTO customers (full_name,email,password_hash,phone,address) VALUES
('Nguyen Van An','an@example.com','DEMO_HASH_NOT_FOR_LOGIN','0900000001','Hanoi'),
('Tran Thi Binh','binh@example.com','DEMO_HASH_NOT_FOR_LOGIN','0900000002','Hanoi'),
('Le Minh Chau','chau@example.com','DEMO_HASH_NOT_FOR_LOGIN','0900000003','Da Nang'),
('Pham Quoc Dung','dung@example.com','DEMO_HASH_NOT_FOR_LOGIN','0900000004','Ho Chi Minh City'),
('Hoang Thu Ha','ha@example.com','DEMO_HASH_NOT_FOR_LOGIN','0900000005','Hai Phong');

INSERT INTO orders (customer_id,order_date,status,total_amount,shipping_address) VALUES
(1,'2026-10-01 09:00:00','delivered',255000,'Hanoi'),
(2,'2026-10-02 10:30:00','shipped',210000,'Hanoi'),
(3,'2026-10-03 11:15:00','confirmed',360000,'Da Nang'),
(4,'2026-10-04 13:40:00','pending',290000,'Ho Chi Minh City'),
(5,'2026-10-05 16:00:00','delivered',320000,'Hai Phong'),
(1,'2026-10-06 08:45:00','confirmed',240000,'Hanoi');

INSERT INTO order_items (order_id,book_id,quantity,unit_price) VALUES
(1,1,1,85000),(1,2,1,105000),(1,4,1,65000),
(2,3,1,75000),(2,5,1,135000),
(3,6,1,145000),(3,7,1,95000),(3,3,1,75000),(3,4,1,45000),
(4,8,1,225000),(4,4,1,65000),
(5,8,1,225000),(5,7,1,95000),
(6,1,1,85000),(6,6,1,155000);

INSERT INTO reviews (customer_id,book_id,rating,comment,review_date) VALUES
(1,1,5,'Excellent book','2026-10-07 09:00:00'),
(1,2,4,'Very touching','2026-10-07 09:30:00'),
(2,3,5,'Great for children','2026-10-07 10:00:00'),
(2,5,4,'Meaningful story','2026-10-07 10:30:00'),
(3,6,5,'A classic','2026-10-07 11:00:00'),
(3,7,4,'Thought provoking','2026-10-07 11:30:00'),
(4,8,5,'Magical adventure','2026-10-07 12:00:00'),
(4,4,4,'Important literature','2026-10-07 12:30:00'),
(5,8,5,'Loved it','2026-10-07 13:00:00'),
(5,7,3,'Interesting read','2026-10-07 13:30:00');

-- Verification: counts, totals and a joined sample
SELECT 'authors' AS table_name, COUNT(*) AS rows_count FROM authors
UNION ALL SELECT 'publishers',COUNT(*) FROM publishers
UNION ALL SELECT 'categories',COUNT(*) FROM categories
UNION ALL SELECT 'books',COUNT(*) FROM books
UNION ALL SELECT 'book_authors',COUNT(*) FROM book_authors
UNION ALL SELECT 'book_categories',COUNT(*) FROM book_categories
UNION ALL SELECT 'customers',COUNT(*) FROM customers
UNION ALL SELECT 'orders',COUNT(*) FROM orders
UNION ALL SELECT 'order_items',COUNT(*) FROM order_items
UNION ALL SELECT 'reviews',COUNT(*) FROM reviews;

SELECT o.order_id,o.total_amount,SUM(oi.subtotal) AS calculated_total,
       IF(o.total_amount = SUM(oi.subtotal),'PASS','MISMATCH') AS validation
FROM orders o JOIN order_items oi ON o.order_id=oi.order_id
GROUP BY o.order_id,o.total_amount;
