select count(*)
from airbnbcase1.listings
having avg(review_scores_rating) < 4.0
