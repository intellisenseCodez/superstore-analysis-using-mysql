
-- Insert distinct values of DimCategories with generated IDs
INSERT INTO DimCategories (category_name)
SELECT DISTINCT Category
FROM 
    RawSuperstore
WHERE 
     Category NOT IN (
        SELECT Category 
        FROM DimCategories
    );
    

-- Insert distinct values of DimSubCategories with generated IDs
INSERT INTO DimSubCategories(subcategory_name, category_id)
SELECT 
    s.`Sub-Category`,
    c.category_id
FROM 
    (SELECT DISTINCT `Sub-Category`, Category FROM rawsuperstore) AS s -- distinct sub-category from raw data
INNER JOIN
    DimCategories AS c ON s.Category = c.category_name
WHERE 
    s.`Sub-Category` NOT IN (
        SELECT subcategory_name 
        FROM DimSubCategories
    ); 
    


-- Insert the distinct DimProducts with their subcategory relationships
INSERT INTO DimProducts (product_id, product_name, subcategory_id)
SELECT
    r.`Product ID`,
    r.`Product Name`,
    s.subcategory_id
FROM 
    (SELECT DISTINCT `Product ID`, `Product Name`, `Sub-Category` FROM rawsuperstore) as r
JOIN 
    DimSubCategories as s ON r.`Sub-Category` = s.subcategory_name
WHERE 
	r.`Product ID` NOT IN (
		SELECT product_id 
		FROM DimProducts
	)
AND
	r.`Product Name` NOT IN (
		SELECT product_name 
		FROM DimProducts
	);



-- Insert the distinct DimCustomers 
INSERT INTO DimCustomers (customer_id, customer_name, segment)
SELECT DISTINCT 
    `Customer ID`, 
    `Customer Name`, 
    Segment
FROM 
    RawSuperstore
WHERE 
    `Customer ID` NOT IN (
        SELECT customer_id 
        FROM DimCustomers
    );


-- Insert distinct values of DimShipMode with generated IDs
INSERT INTO DimShipMode (ship_mode)
SELECT DISTINCT
    `ship Mode`
FROM RawSuperstore
WHERE 
    `ship Mode` NOT IN (
        SELECT ship_mode 
        FROM DimShipMode
    );


-- Insert distinct values of DimLocation 
INSERT INTO DimLocations (postal_code, city, state, region, country)
SELECT DISTINCT
    `Postal Code`,
    City,
    State,
    Region,
    Country
FROM 
    RawSuperstore
WHERE 
    City NOT IN (
		SELECT city FROM DimLocations
    );


-- Insert for DimOrders with all foreign key relationships validated
-- same order were mistakenly linked to the same postal_code
INSERT IGNORE INTO DimOrders (order_id, customer_id, order_date, ship_date, ship_mode_id, location_id)
SELECT
    r.`Order ID`,
    r.`Customer ID`,
    STR_TO_DATE(r.`Order Date`, '%d-%m-%Y') AS order_date,  -- Convert text to date
    STR_TO_DATE(r.`Ship Date`, '%d-%m-%Y') AS ship_date,    -- Convert text to date
    s.shipmode_id,
    l.location_id
FROM 
    (SELECT DISTINCT `Order ID`, `Customer ID`, `Order Date`, `Ship Date`, `Postal Code`, `Ship Mode` FROM rawsuperstore) AS r
JOIN DimCustomers c ON r.`Customer ID` = c.customer_id
JOIN DimShipMode s ON r.`Ship Mode` = s.ship_mode
JOIN DimLocations l ON r.`Postal Code` = l.postal_code
WHERE 
    r.`Order ID` NOT IN (SELECT order_id FROM DimOrders);


-- Insert for FactOrderDetails
INSERT INTO FactOrderDetails(order_id, product_id, quantity, sales, discount, profit)
SELECT 
    o.order_id,
    p.product_id,
    CAST(r.Quantity AS UNSIGNED), -- Only positive integers
    CAST(r.Sales AS FLOAT), -- Cast Sales to FLOAT
    CAST(r.Discount AS FLOAT), -- Cast Discount to FLOAT
    CAST(r.Profit AS FLOAT) -- Cast Profit to FLOAT
FROM RawSuperstore r
JOIN DimOrders o ON r.`Order ID` = o.order_id
JOIN DimProducts p ON r.`Product ID` = p.product_id AND p.product_name = r.`Product Name`
WHERE
	r.`Order ID` NOT IN (SELECT order_id FROM FactOrderDetails) AND
    r.Sales REGEXP '^[0-9]+(\\.[0-9]+)?$' AND -- Ensures Sales is numeric (integer or decimal)
    r.Discount REGEXP '^[0-9]+(\\.[0-9]+)?$' AND -- Ensures Discount is numeric
    r.Profit REGEXP '^[0-9]+(\\.[0-9]+)?$'; -- Ensures Profit is numeric
    
    

select count(*) from DimCategories;  -- 3 records
select count(*) from DimSubCategories; -- 17 records
select count(*) from DimProducts;  -- 1894 records
select count(*) from DimCustomers; -- 793 records
select count(*) from DimShipMode; -- 4 records
select count(*) from DimLocations; -- 632 records
select count(*) from DimOrders; -- 5009 records
select count(*) from FactOrderDetails; -- 7703 records






