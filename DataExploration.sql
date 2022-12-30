-- Creating datasets

CREATE TABLE gold_users_signup (userid int, gold_signup_date date);
INSERT INTO gold_users_signup (userid, gold_signup_date) 
VALUES 
  (1, '09-22-2017'), 
  (2, '04-21-2017'), 
  (5, '06-02-2017'), 
  (6, '09-13-2017');
CREATE TABLE sales (
  userid int, sales_date date, product_id int
);
INSERT INTO sales (userid, sales_date, product_id) 
VALUES 
  (3, '12-18-2019', 1), 
  (2, '07-20-2020', 3), 
  (1, '10-23-2019', 2), 
  (4, '03-19-2018', 3), 
  (3, '12-20-2016', 2), 
  (1, '11-09-2016', 1), 
  (5, '05-20-2016', 3), 
  (6, '09-24-2017', 1), 
  (1, '03-11-2017', 2), 
  (1, '03-11-2016', 1), 
  (3, '11-10-2016', 1), 
  (7, '12-07-2017', 2), 
  (3, '12-15-2016', 2), 
  (2, '11-08-2017', 2), 
  (2, '09-10-2018', 3), 
  (6, '11-10-2017', 2), 
  (7, '02-11-2017', 3), 
  (4, '12-03-2017', 2);
CREATE TABLE product (product_id int, product_name text, price int);
INSERT INTO product (product_id, product_name, price) 
Values 
  (1, 'p1', 980), 
  (2, 'p2', 870), 
  (3, 'p3', 330);
CREATE TABLE users(userid integer, signup_date date);
INSERT INTO users(userid, signup_date) 
VALUES 
  (1, '09-02-2014'), 
  (2, '01-15-2015'), 
  (3, '04-11-2014'), 
  (4, '02-13-2014'), 
  (5, '04-12-2014'), 
  (6, '03-17-2015'), 
  (7, '06-23-2015');
SELECT 
  * 
FROM 
  gold_users_signup;
SELECT 
  * 
FROM 
  sales;
SELECT 
  * 
FROM 
  product;
SELECT 
  * 
FROM 
  users;

-- 1. Total amount each customer spent?

SELECT 
  a.userid, 
  sum(b.price) total_amt_spent 
FROM 
  sales a 
  INNER JOIN product b ON a.product_id = b.product_id
  GROUP BY 
  a.userid;

 -- 2. How many days each customer visited?

 SELECT 
  userid, 
  COUNT(DISTINCT sales_date) no_of_days_visited 
FROM 
  sales 
group by 
  userid;

  -- 3. What is the first product purchased by each customer?

SELECT *
FROM   (SELECT *,
               Rank()
                 OVER(
                   partition BY userid
                   ORDER BY sales_date) rank
        FROM   sales) a
WHERE  rank = 1;

-- 4. What is the most purchased item and how many times is it purchased by all customers?

SELECT userid,
       Count(product_id) no_of_times_purchased
FROM   sales
WHERE  product_id = (SELECT TOP 1 product_id
                     FROM   sales
                     GROUP  BY product_id
                     ORDER  BY Count(product_id) DESC)
GROUP  BY userid;

-- 5. Which product is most popular for every customer?

SELECT *
FROM   (SELECT *,
               Rank()
                 OVER(
                   partition BY userid
                   ORDER BY count DESC) rank
        FROM   (SELECT userid,
                       product_id,
                       Count(product_id) count
                FROM   sales
                GROUP  BY userid,
                          product_id)a)b
WHERE  rank = 1;

