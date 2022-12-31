-- Creating datasets
DROP TABLE IF exists gold_users_signup;
CREATE TABLE gold_users_signup (userid int, gold_signup_date date);
INSERT INTO gold_users_signup (userid, gold_signup_date) 
VALUES 
  (1, '09-22-2017'), 
  (2, '04-21-2017'), 
  (5, '06-02-2017'), 
  (6, '09-13-2017');
DROP TABLE IF exists sales;
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
DROP TABLE IF exists product;
CREATE TABLE product (product_id int, product_name text, price int);
INSERT INTO product (product_id, product_name, price) 
Values 
  (1, 'p1', 980), 
  (2, 'p2', 870), 
  (3, 'p3', 330);
DROP TABLE IF exists users;
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

--6. Which item was bought first by the customer after becoming member?

SELECT *
FROM   (SELECT c.*,
               Rank()
                 OVER(
                   partition BY userid
                   ORDER BY sales_date) rank
        FROM   (SELECT a.userid,
                       a.sales_date,
                       a.product_id,
                       b.gold_signup_date
                FROM   sales a
                       INNER JOIN gold_users_signup b
                               ON a.userid = b.userid
                                  AND sales_date >= gold_signup_date)c)d
WHERE  rank = 1;

--7. Which item was purchased just before the custoer became the member?

SELECT *
FROM   (SELECT c.*,
               Rank()
                 OVER (
                   partition BY userid
                   ORDER BY sales_date DESC) rank
        FROM   (SELECT a.userid,
                       a.sales_date,
                       a.product_id,
                       b.gold_signup_date
                FROM   sales a
                       INNER JOIN gold_users_signup b
                               ON a.userid = b.userid
                WHERE  sales_date <= gold_signup_date) c)d
WHERE  rank = 1; 

--8. what is the total orders and amount spent by each customer before they became a member?

SELECT userid,
       Count(sales_date) total_orders_purchased,
       Sum(price)        total_amount_spent
FROM   (SELECT c.*,
               d.price
        FROM   (SELECT a.userid,
                       a.sales_date,
                       a.product_id,
                       b.gold_signup_date
                FROM   sales a
                       INNER JOIN gold_users_signup b
                               ON a.userid = b.userid) c
               INNER JOIN product d
                       ON c.product_id = d.product_id
        WHERE  sales_date <= gold_signup_date)e
GROUP  BY userid; 

--9. If buying each product generates points for e.g. 5 RS = 2 points and each product has different purchasing points,
-- for e.g p1 and p3 5 RS = 1 point, for p2 10 RS = 5 points
-- calculate cashback collected by each customer and which product has given most points to the customers?

SELECT userid,
       Sum(total_points) * 2.5 total_cashback
FROM   (SELECT userid,
               product_id,
               amount,
               amount / points total_points
        FROM   (SELECT d.*,
                       CASE
                         WHEN product_id = 1 THEN 5
                         WHEN product_id = 2 THEN 2
                         WHEN product_id = 3 THEN 5
                         ELSE 0
                       END AS points
                FROM   (SELECT userid,
                               product_id,
                               Sum(price) amount
                        FROM   (SELECT a.*,
                                       b.price
                                FROM   sales a
                                       INNER JOIN product b
                                               ON a.product_id = b.product_id)c
                        GROUP  BY userid,
                                  product_id)d)e)f
GROUP  BY userid; 

SELECT product_id,
       total_points_earned
FROM   (SELECT g.*,
               Rank()
                 OVER(
                   ORDER BY total_points_earned DESC) rank
        FROM   (SELECT product_id,
                       Sum(total_points) total_points_earned
                FROM   (SELECT userid,
                               product_id,
                               amount,
                               amount / points total_points
                        FROM   (SELECT d.*,
                                       CASE
                                         WHEN product_id = 1 THEN 5
                                         WHEN product_id = 2 THEN 2
                                         WHEN product_id = 3 THEN 5
                                         ELSE 0
                                       END AS points
                                FROM   (SELECT userid,
                                               product_id,
                                               Sum(price) amount
                                        FROM   (SELECT a.*,
                                                       b.price
                                                FROM   sales a
                                                       INNER JOIN product b
                                                               ON a.product_id =
                                                                  b.product_id)c
                                        GROUP  BY userid,
                                                  product_id)d)e)f
                GROUP  BY product_id)g)h
WHERE  rank = 1; 

--10. After joining the gold membership for the first year if the member gets 5 points for every 10 RS spent.
-- Which member has earned more and how much did they earn in the first year after membership?

SELECT userid,
       Sum(total_points) total_points_earned
FROM   (SELECT userid,
               points * 10 total_points
        FROM   (SELECT e.*,
                       price / 10 points
                FROM   (SELECT c.*,
                               d.price
                        FROM   (SELECT a.userid,
                                       a.sales_date,
                                       a.product_id,
                                       b.gold_signup_date
                                FROM   sales a
                                       INNER JOIN gold_users_signup b
                                               ON a.userid = b.userid)c
                               INNER JOIN product d
                                       ON c.product_id = d.product_id
                        WHERE  sales_date >= gold_signup_date
                               AND sales_date <= Dateadd(year, 1,
                                                 gold_signup_date))e)f
       )g
GROUP  BY userid; 

--11. Rank all the transactions of the customers based on sales date.

SELECT *,
       Rank()
         OVER(
           partition BY userid
           ORDER BY sales_date) rank
FROM   sales;

--12. Rank all transactions of all gold members and if they are not gold members rank as NA.

SELECT userid,
       sales_date,
       product_id,
       gold_signup_date,
       CASE
         WHEN rnk = 0 THEN 'NA'
         ELSE rnk
       END AS rank
FROM   (SELECT c.*,
               Cast (( CASE
                         WHEN gold_signup_date IS NULL THEN 0
                         ELSE Rank()
                                OVER(
                                  partition BY userid
                                  ORDER BY sales_date DESC)
                       END ) AS VARCHAR) AS rnk
        FROM   (SELECT a.userid,
                       a.sales_date,
                       a.product_id,
                       b.gold_signup_date
                FROM   sales a
                       LEFT JOIN gold_users_signup b
                              ON a.userid = b.userid)c)d; 

