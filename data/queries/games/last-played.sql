select 
  max(date) as lastPlayed, 
  julianday(current_date)-julianday(max(date)) as daysSince, 
  count(date) as games, 
  name 
from played
group by name
order by date desc;
