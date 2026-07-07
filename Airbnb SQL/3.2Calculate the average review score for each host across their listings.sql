--select * from airbnbcase1.listings

select host_id,host_name,round(avg(review_scores_rating),2) as average 
from airbnbcase1.listings
where review_scores_rating is not null
group by host_id,host_name
--having avg(review_scores_rating) is not null can also be used