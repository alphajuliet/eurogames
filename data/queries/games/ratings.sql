select name, complexity, ranking from bgg 
left join notes on bgg.id = notes.id 
order by complexity
