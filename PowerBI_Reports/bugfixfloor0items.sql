-- [dwh].[FactFloorItem] CTE
;WITH path_per_floor AS 
(
-- path per floor
SELECT 
	[play_id],
	REPLACE(REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[',''),'"','') AS [path_taken],
	ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [floor]	
FROM [imp].[StSJSONData]
CROSS APPLY STRING_SPLIT([path_taken], ',')		
)
,item_interaction AS 
(
-- card purged in shop
SELECT  
	purge_floor.[play_id],
	COALESCE(purge_floor.[item_purged_floor],0) AS [Floor],
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(purge_item.[item_purged],'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
	'card_purged' AS [ItemInteraction]
FROM  
	(
	SELECT 
		j.[play_id],
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [item_purged_floor],
		ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) AS [col_index]
	FROM [imp].[StSJSONData] j
	CROSS APPLY STRING_SPLIT([items_purged_floors], ',')
		WHERE value != '[]'
	) AS purge_floor
	LEFT JOIN 
	(
	SELECT 
		j.[play_id],
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [item_purged],
		ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) AS [col_index]			
	FROM [imp].[StSJSONData] j		
	CROSS APPLY STRING_SPLIT([items_purged], ',') 
		WHERE value != '[]'
	) AS purge_item ON purge_item.[play_id] = purge_floor.[play_id] AND purge_item.[col_index] = purge_floor.[col_index]
UNION ALL 
-- card purged via peace pipe (campfire)
SELECT  
	[play_id],
	CONVERT(int,(CASE WHEN [floor] like '%.%' THEN SUBSTRING([floor],0,CHARINDEX('.',[floor],0)) ELSE [floor] END)) AS [floor],
	REPLACE(campfire_choices.[data],' ','') AS [ItemName],
	'card_purged' AS [ItemInteraction]
FROM [imp].[StSJSONData]
CROSS APPLY OPENJSON (campfire_choices)
WITH 
	(
		[floor] nvarchar(5),
		[data] nvarchar(255),     
		[key] nvarchar(20)
	) AS campfire_choices
	WHERE campfire_choices.[key] = 'PURGE'
UNION ALL 
-- card picked	
SELECT 
	j.[play_id],
	CONVERT(int,(CASE WHEN card_picked.[floor] like '%.%' THEN SUBSTRING(card_picked.[floor],0,CHARINDEX('.',card_picked.[floor],0)) ELSE card_picked.[floor] END)) AS [floor],
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([picked],'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
	'card_picked' AS [ItemInteraction]
FROM [imp].[StSJSONData] j
CROSS APPLY OPENJSON ([card_choices]) 
WITH (
	[picked] nvarchar(255), 		
	[floor] nvarchar(5)
) AS card_picked 
	WHERE [picked] != '[]'
UNION ALL 
-- card not picked
SELECT 
	j.[play_id],
	CONVERT(int,(CASE WHEN not_picked.[floor] like '%.%' THEN SUBSTRING(not_picked.[floor],0,CHARINDEX('.',not_picked.[floor],0)) ELSE not_picked.[floor] END)) AS [floor],
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
	'card_not_picked' AS [ItemInteraction]
FROM [imp].[StSJSONData] j
CROSS APPLY OPENJSON ([card_choices]) 
WITH (
[not_picked] nvarchar(max) AS JSON,
[floor] nvarchar(5)
) AS not_picked
	CROSS APPLY STRING_SPLIT([not_picked], ',')
		WHERE value != '[]'		
UNION ALL
-- relics obtained
SELECT 
	j.[play_id],
	CONVERT(int,(CASE WHEN relics_obtained.[floor] like '%.%' THEN SUBSTRING(relics_obtained.[floor],0,CHARINDEX('.',relics_obtained.[floor],0)) ELSE relics_obtained.[floor] END)) AS [floor],
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(relics_obtained.[key],'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
	'relic_looted' AS [ItemInteraction]
FROM [imp].[StSJSONData] j
CROSS APPLY OPENJSON ([relics_obtained]) 
WITH (
	[floor] nvarchar(5),
	[key] nvarchar(255)
) AS relics_obtained 
	WHERE relics_obtained.[key] != '[]'
UNION ALL
-- boss relics picked
SELECT 
	j.[play_id],
	CASE WHEN ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) = 1 THEN 17 ELSE 34 END AS [floor],
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(boss_relics_picked.[picked],'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
	'boss_relic_picked' AS [ItemInteraction]
FROM [imp].[StSJSONData] j
CROSS APPLY OPENJSON ([boss_relics]) 
WITH (
	[picked] nvarchar(255)
) AS boss_relics_picked
	WHERE boss_relics_picked.[picked] != '[]'
-- boss relics not picked
UNION ALL 
SELECT 
	j.[play_id],
	CASE WHEN ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) = 1 THEN 17 ELSE 34 END AS [floor],
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
	'boss_relic_not_picked' AS [ItemInteraction]
FROM [imp].[StSJSONData] j
CROSS APPLY OPENJSON ([boss_relics]) 
WITH (
[not_picked] nvarchar(max) AS JSON,
[floor] nvarchar(5)
) AS not_picked
	CROSS APPLY STRING_SPLIT([not_picked], ',')
		WHERE value != '[]'
-- items purchased
UNION ALL 
SELECT  
	purchase_floor.[play_id],
	COALESCE(purchase_floor.[item_purchase_floor],0) AS [Floor],
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(purchase_item.[item_purchased],'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
	'item_purchased' AS [ItemInteraction]	
FROM  
	(
	SELECT 
		j.[play_id],
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [item_purchase_floor],
		ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) AS [col_index]
	FROM [imp].[StSJSONData] j
	CROSS APPLY STRING_SPLIT([item_purchase_floors], ',')
	) purchase_floor
	LEFT JOIN 
	(
	SELECT 
		j.[play_id],
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [item_purchased],
		ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) AS [col_index]			
	FROM [imp].[StSJSONData] j		
	CROSS APPLY STRING_SPLIT([items_purchased], ',') 
	) purchase_item ON purchase_item.[play_id] = purchase_floor.[play_id] AND purchase_item.[col_index] = purchase_floor.[col_index]
-- campfire upgrades
UNION ALL 
SELECT  
	[play_id],
	CONVERT(int,(CASE WHEN [floor] like '%.%' THEN SUBSTRING([floor],0,CHARINDEX('.',[floor],0)) ELSE [floor] END)) AS [floor],
	REPLACE(campfire_choices.[data],' ','')+'+1' AS [ItemName], -- all upgraded cards get +1 for end of run data comparison purposes
	'card_upgraded' AS [ItemInteraction]
FROM [imp].[StSJSONData]
CROSS APPLY OPENJSON (campfire_choices)
WITH 
	(
		[floor] nvarchar(5),
		[data] nvarchar(255),     
		[key] nvarchar(20)
	) AS campfire_choices
	WHERE campfire_choices.[key] = 'SMITH'
-- potions obtained
UNION ALL
SELECT 
	j.[play_id],
	CONVERT(int,(CASE WHEN potions_obtained.[floor] like '%.%' THEN SUBSTRING(potions_obtained.[floor],0,CHARINDEX('.',potions_obtained.[floor],0)) ELSE potions_obtained.[floor] END)) AS [floor],
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(potions_obtained.[key],'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
	'potion_looted' AS [ItemInteraction]
FROM [imp].[StSJSONData] j
CROSS APPLY OPENJSON ([potions_obtained]) 
WITH (
	[floor] nvarchar(5),
	[key] nvarchar(255)
) AS potions_obtained
)
, item_end_of_run AS
(
--  relics >> looted from events = relics at and of run not yet covered
SELECT 
	[play_id],
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
	'?' AS [path_taken],
	CASE	WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') IN ('BurningBlood','CrackedCore','RingoftheSnake') THEN 'starter_relic'
			ELSE 'looted_from_event' 
	END AS [ItemInteraction]
FROM [imp].[StSJSONData]
CROSS APPLY STRING_SPLIT([relics], ',') as relics
LEFT JOIN [dwh].[DimItem] i ON i.[ItemName] = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','')
	WHERE i.[ItemType] = 'relic'
	AND value != '[]'
UNION ALL
--  master_deck >> cards looted from events = cards at and of run not yet covered
SELECT 
	[play_id],
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s') AS [ItemName],
	'?' AS [path_taken],
	CASE	WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') IN ('Defend_R','Defend_G','Defend_B','Strike_R','Strike_G','Strike_B','Bash','Neutralize','Survivor','Dualcast','Zap','AscendersBane') THEN 'starter_card'
			ELSE 'looted_from_event'
	END AS [ItemInteraction]
FROM [imp].[StSJSONData]
CROSS APPLY STRING_SPLIT([master_deck], ',') as master_deck
LEFT JOIN [dwh].[DimItem] i ON i.[ItemName] = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','')
	WHERE i.[ItemType] = 'card'
	AND value != '[]'
)

--select COUNT(1) from item_interaction
select COUNT(1) from item_end_of_run

-- relics, master deck, starter_relics, starter_cards
SELECT 
	-- dimension ids
	item_end_of_run.[play_id] AS [PlayId],
	0 AS [Floor],
	p.[PathId],
	i.[ItemId],
	ia.[ItemInteractionId],
	i.ItemName,
	i.ItemType,
	ia.ItemInteractionName,
	-- logging
	getdate() AS [ETLInsertedAt],
	getdate() AS [ETLUpdatedAt],
	system_user AS [ETLUser]
FROM item_end_of_run
LEFT JOIN [dwh].[DimItem] i ON i.[ItemName] = item_end_of_run.[ItemName]
LEFT JOIN [dwh].[DimItemInteraction] ia ON ia.[ItemInteractionName] = item_end_of_run.[ItemInteraction]
LEFT JOIN [dwh].[DimPath] p ON p.[PathType] = item_end_of_run.[path_taken]
WHERE NOT EXISTS
	(
	SELECT 
		-- dimension ids
		item_interaction.[play_id] AS [PlayId],
		i.[ItemId]
	FROM item_interaction
	LEFT JOIN [dwh].[DimItem] i ON i.[ItemName] = item_interaction.[ItemName]
		WHERE item_interaction.[ItemName] = item_end_of_run.[ItemName] AND item_interaction.[play_id] = item_end_of_run.[play_id]
	)