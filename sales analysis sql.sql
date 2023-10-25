use newportfoliodb;

-- Inspecting Data
SELECT * FROM sales_data_sample2;

-- Checking Unique Values
SELECT DISTINCT STATUS FROM sales_data_sample2;
SELECT DISTINCT YEAR_ID FROM sales_data_sample2;
SELECT DISTINCT PRODUCTLINE FROM sales_data_sample2;
SELECT DISTINCT COUNTRY FROM sales_data_sample2;
SELECT DISTINCT DEALSIZE FROM sales_data_sample2;
SELECT DISTINCT TERRITORY FROM sales_data_sample2;

SELECT DISTINCT MONTH_ID FROM sales_data_sample2
WHERE YEAR_ID = 2005;

-- Analysis
-- Grouping sales by productline
SELECT PRODUCTLINE, SUM(sales) Revenue FROM sales_data_sample2
group by PRODUCTLINE
ORDER BY 2 DESC;

-- Grouping sales by Year
SELECT YEAR_ID, SUM(sales) Revenue FROM sales_data_sample2
group by YEAR_ID
ORDER BY 2 DESC;

-- Grouping sales by DealSize
SELECT DEALSIZE, SUM(sales) Revenue FROM sales_data_sample2
group by DEALSIZE
ORDER BY 2 DESC;

-- What was the best month for sales in a specific year? and how much was earned that month?
SELECT MONTH_ID, sum(SALES) Revenue, count(ORDERNUMBER) frequency FROM sales_data_sample2
WHERE YEAR_ID = 2004 -- change the year
GROUP BY MONTH_ID
ORDER BY 2 DESC;

-- November seems to be the best month what product  sell THE MOST in november (ANS = Classic car)
SELECT MONTH_ID,PRODUCTLINE, sum(SALES) Revenue, count(ORDERNUMBER) frequency FROM sales_data_sample2
WHERE YEAR_ID = 2004 AND MONTH_ID = 11 -- change the year
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY 3 DESC;

-- who is our best customer(This could be best answered with RFM)
WITH rfm as
(
SELECT CUSTOMERNAME,
	   sum(SALES) MonetaryValue,
       avg(SALES) AvgMonetaryValue,
       count(ORDERNUMBER) Frequency,
       max(ORDERDATE) Last_order_date,
       (SELECT MAX(ORDERDATE) FROM sales_data_sample2) Max_order_date,
       DATEDIFF(max(ORDERDATE),(SELECT MAX(ORDERDATE) FROM sales_data_sample2)) Recency
FROM sales_data_sample2
GROUP BY CUSTOMERNAME
),
rfm_cal as
(
SELECT r.*,
	NTILE(4) OVER (ORDER BY Recency) rfm_recency,
    NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,
    NTILE(4) OVER (ORDER BY MonetaryValue) rfm_Monetary
FROM rfm r
),
rfm_data AS
(
SELECT 
	C.*, rfm_recency+rfm_frequency+rfm_Monetary AS rfm_cell,
	CONCAT(CAST(rfm_recency AS CHAR) , CAST(rfm_frequency AS CHAR) , CAST(rfm_Monetary AS CHAR)) rfm_cell_str
FROM rfm_cal C
)

SELECT CUSTOMERNAME, rfm_recency,rfm_frequency,rfm_Monetary,
	case
		when rfm_cell_str in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  -- lost customers
		when rfm_cell_str in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_str in (311, 411, 331) then 'new customers'
		when rfm_cell_str in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_str in (323, 333,321, 422, 332, 432) then 'active' -- (Customers who buy often & recently, but at low price points)
		when rfm_cell_str in (433, 434, 443, 444) then 'loyal'
	end rfm_segment
        
 FROM rfm_data
 ;
 
-- what products are sold most often together
select distinct OrderNumber,

	(select  group_concat(PRODUCTCODE)
	from sales_data_sample2 p
	where ORDERNUMBER in 
		(
			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM sales_data_sample2
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
	) prod_code

from sales_data_sample2 s
order by 2 desc


