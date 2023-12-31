USE mavenfuzzyfactory;

select  
	website_sessions.utm_content, 
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id)*100 as session_to_order_conv_rate
from website_sessions
LEFT JOIN orders
	ON website_sessions.website_session_id = orders.website_session_id
where website_sessions.website_session_id between 1000 AND 2000 
group by website_sessions.utm_content
order by sessions desc;

SELECT utm_source, utm_campaign, http_referer, COUNT(DISTINCT website_session_id) as sessions
FROM website_sessions 
WHERE created_at < "2012-04-12 00:00:00"
GROUP BY utm_source, utm_campaign, http_referer
ORDER BY sessions DESC;

SELECT COUNT(DISTINCT w.website_session_id) as sessions,
	COUNT(DISTINCT o.order_id) as orders,
    COUNT(DISTINCT o.order_id) * 100 / COUNT(DISTINCT w.website_session_id)  as CVR
FROM website_sessions w
LEFT JOIN orders o
ON
	o.website_session_id = w.website_session_id
WHERE w.created_at < "2012-04-14 00:00:00"
	AND w.utm_source = 'gsearch'
    AND w.utm_campaign = 'nonbrand'
    AND w.http_referer = 'https://www.gsearch.com';
	
    SELECT week(created_at), year(created_at), MIN(DATE(created_at)) as week_Start,
			count(DISTINCT website_session_id) as sessions
    FROM website_sessions
    WHERE website_session_id BETWEEN 100000 AND 150000
    GROUP BY 1,2;
		
SELECT primary_product_id ,
		COUNT(DISTINCT CASE WHEN items_purchased = 1 THEN order_id ELSE NULL END) AS single_item_orders,
        COUNT(DISTINCT CASE WHEN items_purchased = 2 THEN order_id ELSE NULL END) AS two_item_orders,
		COUNT(DISTINCT order_id) AS total_orders
FROM orders
WHERE order_id BETWEEN 31000 AND 32000
GROUP BY primary_product_id;

SELECT  MIN(DATE(created_at)) as week, COUNT(DISTINCT website_session_id) as sessions
FROM website_sessions
WHERE created_at < '2012-05-10'
		AND	utm_source = 'gsearch'
		AND utm_campaign = 'nonbrand'
		AND http_referer = 'https://www.gsearch.com'
GROUP BY week(created_at) ;

SELECT w.device_type, COUNT(DISTINCT w.website_session_id) as sessions, COUNT(DISTINCT o.order_id) as orders,
		COUNT(DISTINCT o.order_id)/COUNT(DISTINCT w.website_session_id) as CVR
FROM website_sessions w
LEFT JOIN orders o
ON 
	w.website_session_id = o.website_session_id
WHERE w.created_at < '2012-05-11'
	AND w.utm_source = 'gsearch'
    AND w.utm_campaign = 'nonbrand'
GROUP BY w.device_type;

-- WEEKLY SESSION VOLUMES BY DESKTOP AND MOBILE
SELECT MIN(DATE(created_at)) as Weeks,
		COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) as Desktop_sessions,
        COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) as Mobile_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-04-15' AND '2012-06-09'
		AND	utm_source = 'gsearch'
		AND utm_campaign = 'nonbrand'
		AND http_referer = 'https://www.gsearch.com'
GROUP BY WEEK(created_at);

-- TOP WEBSITE CONTENT PAGE OVERALL
SELECT pageview_url,
		COUNT(DISTINCT website_pageview_id) AS pvs
FROM website_pageviews
WHERE website_pageview_id < 1000
GROUP BY pageview_url
ORDER BY pvs DESC;

-- TOP ENTRY PAGES
CREATE TEMPORARY TABLE first_pageview
SELECT
		website_session_id, 
		MIN(website_pageview_id) as first_viewed_page_id
FROM website_pageviews
WHERE website_pageview_id < 1000
GROUP BY website_session_id;

SELECT 
        website_pageviews.pageview_url as Landing_page,
        count(distinct first_pageview.website_session_id)
FROM first_pageview
LEFT JOIN website_pageviews
ON 
	first_pageview.first_viewed_page_id = website_pageviews.website_pageview_id
group by website_pageviews.pageview_url;


-- SAME RESULT WITHOUT THE USE OF TEMP TABLE
SELECT website_session_id, pageview_url
FROM website_pageviews
WHERE website_pageview_id < 1000
	AND website_pageview_id in (select min(website_pageview_id) from website_pageviews group by website_session_id);

SELECT 
	pageview_url,
	COUNT(website_session_id) AS session_volume
FROM website_pageviews
WHERE created_at < '2012-06-09'
GROUP BY pageview_url
ORDER BY session_volume DESC;

CREATE TEMPORARY TABLE landing_page
SELECT website_session_id,
	MIN(website_pageview_id) as first_pg
FROM website_pageviews
WHERE created_at < '2012-06-12'
GROUP BY website_session_id;

SELECT wp.pageview_url, COUNT(lp.website_session_id) as first_pg_session_volume
FROM landing_page lp
LEFT JOIN website_pageviews wp
ON 
	lp.first_pg = wp.website_pageview_id 
WHERE created_at < '2012-06-12'
GROUP BY wp.pageview_url;
-- FOR ALL SESSIONS THE LANDING PAGE IS HOMEPAGE ONLY


-- ### NEW DAY ###

-- FINDING BOUNCE RATE FOR LANDING PAGE
CREATE TEMPORARY TABLE first_pgview
SELECT website_session_id,
	MIN(website_pageview_id) as first_pg
FROM website_pageviews
WHERE created_at < '2012-06-14'
GROUP BY website_session_id;

SELECT * FROM first_pgview;


-- LINKING THE FIRST PAGEVIEW ID OF EACH SESSION WITH ITS URL
CREATE TEMPORARY TABLE landing_pg_of_sessions
SELECT 
		first_pgview.website_session_id,
		first_pgview.first_pg,
        website_pageviews.pageview_url
FROM first_pgview
LEFT JOIN website_pageviews
ON 
	first_pgview.first_pg = website_pageviews.website_pageview_id;

-- FINDING SESSIONS WITH ONLY ONE PAGE VIEW I.E BOUNCE PAGE
CREATE TEMPORARY TABLE bounce_sessions_id_new
SELECT 
		website_session_id,
		COUNT(website_pageview_id) AS page_viewed
FROM website_pageviews
GROUP BY website_session_id
HAVING page_viewed = 1;

-- JOIN ABOVE TEMP TABLES TO FIND BOUNCE AND UNBOUNCED SESSIONS
SELECT 
        landing_pg_of_sessions.pageview_url,
        COUNT(DISTINCT landing_pg_of_sessions.website_session_id) AS total_sessions,
        COUNT(DISTINCT bounce_sessions_id_new.website_session_id) AS bounced_sessions,
        COUNT(bounce_sessions_id_new.website_session_id)/COUNT(landing_pg_of_sessions.website_session_id) AS bounce_rate
FROM landing_pg_of_sessions
LEFT JOIN bounce_sessions_id_new
ON 
	landing_pg_of_sessions.website_session_id = bounce_sessions_id_new.website_session_id
GROUP BY landing_pg_of_sessions.pageview_url
ORDER BY landing_pg_of_sessions.pageview_url; 






















