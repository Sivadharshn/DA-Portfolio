--select * from airbnbcase1.listings
select count(id),count(distinct(property_type))
from airbnbcase1.listings 
