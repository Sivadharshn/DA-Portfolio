--select * from airbnbcase1.listings

select name,review_scores_rating
from airbnbcase1.listings
where review_scores_rating is not null
order by review_scores_rating desc
limit 10
