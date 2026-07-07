--select * from airbnbcase1.listings
select property_type, count(property_type) as total_property_type
from airbnbcase1.listings
group by property_type
order by total_property_type desc
limit 5
