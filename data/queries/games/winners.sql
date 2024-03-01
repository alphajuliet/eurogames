SELECT name, winner, count(winner) AS wins FROM played
GROUP BY name, winner
