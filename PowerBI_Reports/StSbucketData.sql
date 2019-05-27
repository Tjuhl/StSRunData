select 
	 runId	
	,character
	,victoryTF
	,cards1
	,relics1
	,boss1
	,cards2 -- including act1 boss loot
	,relics2 -- including act1 boss loot
	,boss2
	,cards3 -- including act2 boss loot
	,relics3 -- including act2 boss loot
	,boss3 -- 1st boss in act3, as only that one is visible to the player 
from stsdata

select * from [imp].[StSJSONData] s where s.is_daily = 'true'