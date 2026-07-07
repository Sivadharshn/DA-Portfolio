--select * from airbnbcase1.listings

select host_id,host_name,count(id) as listing_count
from airbnbcase1.listings 
group by host_id,host_name
having count(id) > 3
order by listing_count

