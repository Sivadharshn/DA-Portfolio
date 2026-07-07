--select * from airbnbcase1.listings

select host_id,host_name,count(id) as total_listings,round(avg(review_scores_rating),2)
from airbnbcase1.listings
group by host_id,host_name
having count(id) >=2 and avg(review_scores_rating) < 4