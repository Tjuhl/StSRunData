CREATE PROCEDURE [imp].[spStSRunLoadFacts] AS

BEGIN 

-- [dwh].[FactRun]
INSERT INTO [dwh].[FactRun]
SELECT 
	-- dimension ids
	s.[play_id] AS [PlayId],
	b.[BuildId],
	a.[AscensionLevelId],
	c.[CharacterId],
	n.[StartingBonusId],
	v.[VictoryId],
	k.[EncounterId] AS [KilledById],
	-- measures
	s.[floor_reached] AS [FloorReached],
	s.[campfire_rested] AS [CampfireRests],
	s.[campfire_upgraded] AS [CampfireUpgrades],
	s.[purchased_purges] AS [PurchasedPurges],
	s.[gold] AS [FinalGold],
	s.[player_experience] AS [PlayerExperience],
	s.[score] AS [Score],
	s.[playtime]/60 AS [PlayTimeMinutes],
	s.[win_rate] AS [WinRate],
	s.[circlet_count] AS [CircletCount],
	-- timestamps
	format(dateadd(S, s.[run_timestamp], '1970-01-01'), 'yyyyMMdd', 'en-US') as [RunStartedAt],
	-- other
	s.[seed_played] AS [SeedPlayed],
	-- additional data
	s.[master_deck] AS [MasterDeck],
	s.[relics] AS [Relics],
	s.[chose_seed] AS [ChoseSeed],
	s.[is_ascension_mode] AS [IsAscensionMode],
	s.[is_beta] AS [IsBeta],
	s.[is_daily] AS [IsDaily],
	s.[is_endless] AS [IsEndless],
	s.[is_prod] AS [IsProd],
	s.[is_trial] AS [IsTrial],
	-- logging
	getdate() AS [ETLInsertedAt],
	getdate() AS [ETLUpdatedAt],
	system_user AS [ETLUser]	
FROM [imp].[StSJSONData] s
LEFT JOIN [dwh].[DimBuildVersion] b ON b.[BuildVersion] = s.[build_version]
LEFT JOIN [dwh].[DimAscensionLevel] a ON a.[AscensionLevel] = s.[ascension_level]
LEFT JOIN [dwh].[DimCharacter] c ON c.[CharacterChosen] = s.[character_chosen]
LEFT JOIN [dwh].[DimStartingBonus] n ON n.[StartingBonusName] = s.[neow_bonus] AND n.[StartingBonusCost] = s.[neow_cost]
LEFT JOIN [dwh].[DimEncounter] k ON k.[EncounterName] = s.[killed_by] AND k.[EncounterType] = 'Encounter'
LEFT JOIN [dwh].[DimVictory] v ON v.[VictoryTF] = s.[victory]

-- [dwh].[FactFloor] CTE
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
, hp_per_floor AS 
(
-- current hp per floor
SELECT 
	[play_id],
	ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [floor],
	REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[','') AS [hp_per_floor]
FROM [imp].[StSJSONData]
CROSS APPLY STRING_SPLIT([current_hp_per_floor], ',')
)
, max_hp_per_floor AS 
(
-- max hp per floor
SELECT 
	play_id,
	REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[','') AS [max_hp_per_floor],
	ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [floor]	
FROM [imp].[StSJSONData] j
CROSS APPLY STRING_SPLIT([max_hp_per_floor], ',')
)
, gold_per_floor AS 
(
-- gold per floor
SELECT 
	play_id,
	REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[','') AS [gold_per_floor],
	ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [floor]	
FROM [imp].[StSJSONData] j
CROSS APPLY STRING_SPLIT([gold_per_floor], ',')
)
, potions_spawned_per_floor AS 
(
-- potions spawned per floor
SELECT  
	t.[play_id],
	t.[potions_floor_spawned],
	COUNT(t.[potions_floor_spawned]) AS [potions_spawned]
FROM  
	(
	SELECT 
		[play_id],
		REPLACE(REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[',''),'"','') AS [potions_floor_spawned],
		ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [col_index]
	FROM [imp].[StSJSONData]
	CROSS APPLY STRING_SPLIT([potions_floor_spawned], ',')
		WHERE value != '[]'
	) AS t
		GROUP BY t.[play_id], t.[potions_floor_spawned]
)
, potions_used_per_floor AS 
(
-- potions used per floor
SELECT  
	t.[play_id],
	t.[potions_floor_usage],
	COUNT(t.[potions_floor_usage]) AS [potions_used]
FROM  
	(
	SELECT 
		[play_id],
		REPLACE(REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[',''),'"','') AS [potions_floor_usage],
		ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [col_index]
	FROM [imp].[StSJSONData]
	CROSS APPLY STRING_SPLIT([potions_floor_usage], ',')
		WHERE value != '[]'
	) AS t
		GROUP BY t.[play_id], t.[potions_floor_usage]
)
, items_purchased_per_floor AS 
(
-- items purchased per floor
SELECT  
	t.[play_id],
	t.[item_purchase_floor],
	COUNT(t.[item_purchase_floor]) AS [items_purchased]
FROM  
	(
	SELECT 
		[play_id],
		CASE WHEN value = '[]' THEN NULL ELSE REPLACE(REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[',''),'"','') END AS [item_purchase_floor],
		ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [col_index]
	FROM [imp].[StSJSONData]
	CROSS APPLY STRING_SPLIT([item_purchase_floors], ',')
	) AS t
		GROUP BY t.[play_id], t.[item_purchase_floor]	
)
, items_purged_per_floor AS 
(
-- items purged 
SELECT  
	t.[play_id],
	t.[item_purged_floor],
	COUNT(t.[item_purged_floor]) AS [items_purged]
FROM  
	(
	SELECT 
		[play_id],
		CASE WHEN value = '[]' THEN NULL ELSE REPLACE(REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[',''),'"','') END AS [item_purged_floor],
		ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [col_index]
	FROM [imp].[StSJSONData]
	CROSS APPLY STRING_SPLIT([items_purged_floors], ',')
	) t	
		GROUP BY t.[play_id], t.[item_purged_floor]	
)
, campfire_choices AS 
(
-- campfire choices
SELECT  
	[play_id],
	CONVERT(int,(CASE WHEN [floor] like '%.%' THEN SUBSTRING([floor],0,CHARINDEX('.',[floor],0)) ELSE [floor] END)) AS [floor],
	campfire_choices.[key] AS [CampfireAction],
	CASE WHEN campfire_choices.[key] = 'REST' THEN 'REST' WHEN campfire_choices.[key] = 'DIG' THEN 'DIG' ELSE campfire_choices.[data] END AS [CampfireChoice]
FROM [imp].[StSJSONData]
CROSS APPLY OPENJSON (campfire_choices)
WITH 
	(
		[floor] nvarchar(5),
		[data] nvarchar(255),     
		[key] nvarchar(20)
	) AS campfire_choices 
)

-- [dwh].[FactFloor]
INSERT INTO [dwh].[FactFloor]
SELECT  
	-- dimension info
	path_per_floor.[play_id] AS [PlayId],
	path_per_floor.[floor] AS [Floor],
	p.[PathId],
	campfire_choices.[CampfireAction],
	campfire_choices.[CampfireChoice],
	-- measures
	hp_per_floor.[hp_per_floor] AS [CurrentHP],
	max_hp_per_floor.[max_hp_per_floor] AS [MaxHP],
	gold_per_floor.[gold_per_floor] AS [Gold],
	items_purchased_per_floor.[items_purchased] AS [ItemsPurchased],
	items_purged_per_floor.[items_purged] AS [ItemsPurged],
	potions_spawned_per_floor.[potions_spawned] AS [PotionsSpawned],
	potions_used_per_floor.[potions_used] AS [PotionsUsed],
	-- logging
	getdate() AS [ETLInsertedAt],
	getdate() AS [ETLUpdatedAt],
	system_user AS [ETLUser]	
FROM path_per_floor
LEFT JOIN hp_per_floor ON hp_per_floor.[play_id] = path_per_floor.[play_id] AND hp_per_floor.[floor] = path_per_floor.[floor]
LEFT JOIN max_hp_per_floor ON max_hp_per_floor.[play_id] = path_per_floor.[play_id] AND max_hp_per_floor.[floor] = path_per_floor.[floor]
LEFT JOIN gold_per_floor ON gold_per_floor.[play_id] = path_per_floor.[play_id] AND gold_per_floor.[floor] = path_per_floor.[floor]
LEFT JOIN potions_spawned_per_floor ON potions_spawned_per_floor.[play_id] = path_per_floor.[play_id] AND potions_spawned_per_floor.[potions_floor_spawned] = path_per_floor.[floor]
LEFT JOIN potions_used_per_floor ON potions_used_per_floor.[play_id] = path_per_floor.[play_id] AND potions_used_per_floor.[potions_floor_usage] = path_per_floor.[floor]
LEFT JOIN campfire_choices ON campfire_choices.[play_id] = path_per_floor.[play_id] AND campfire_choices.[floor] = path_per_floor.[floor]
LEFT JOIN items_purchased_per_floor ON items_purchased_per_floor.[play_id] = path_per_floor.[play_id] AND items_purchased_per_floor.[item_purchase_floor] = path_per_floor.[floor]
LEFT JOIN items_purged_per_floor ON items_purged_per_floor.[play_id] = path_per_floor.[play_id] AND items_purged_per_floor.[item_purged_floor] = path_per_floor.[floor]
LEFT JOIN [dwh].[DimPath] p ON p.[PathType] = path_per_floor.[path_taken]

-- [dwh].[FactFloorEvent] CTE
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
,encounter AS 
(
-- encounter
SELECT 
	[play_id],
	CONVERT(int,(CASE WHEN [floor] like '%.%' THEN SUBSTRING([floor],0,CHARINDEX('.',[floor],0)) ELSE [floor] END)) AS [floor],
	en.[EncounterId],
	CONVERT(int,(CASE WHEN [damage] like '%.%' THEN SUBSTRING([damage],0,CHARINDEX('.',[damage],0)) ELSE [damage] END)) AS [damage],
	CONVERT(int,(CASE WHEN [turns] like '%.%' THEN SUBSTRING([turns],0,CHARINDEX('.',[turns],0)) ELSE [turns] END)) AS [turns]
FROM [imp].[StSJSONData]
CROSS APPLY OPENJSON ([damage_taken]) 
WITH (
	[damage] nvarchar(5),
	[enemies] nvarchar(255), 
	[floor] nvarchar(5), 
	[turns] nvarchar(5)
) AS encounter 
LEFT JOIN [dwh].[DimEncounter] en ON en.[EncounterName] = encounter.[enemies] AND en.[EncounterType] = 'encounter'
)
,event_choice AS 
(
-- event choice
SELECT 
	[play_id],
	CONVERT(int,(CASE WHEN event_choices.[floor] like '%.%' THEN SUBSTRING(event_choices.[floor],0,CHARINDEX('.',event_choices.[floor],0)) ELSE event_choices.[floor] END)) AS [floor],
	en.[EncounterId],
	event_choices.[event_name],
	event_choices.[player_choice],
	CONVERT(int,(CASE WHEN event_choices.[damage_taken] like '%.%' THEN SUBSTRING(event_choices.[damage_taken],0,CHARINDEX('.',event_choices.[damage_taken],0)) ELSE event_choices.[damage_taken] END)) AS [damage_taken]
FROM [imp].[StSJSONData]
CROSS APPLY OPENJSON ([event_choices]) 
WITH (
	[damage_taken] nvarchar(5),
	[event_name] nvarchar(255), 
	[floor] nvarchar(5), 
	[player_choice] nvarchar(255)
) AS event_choices 
LEFT JOIN [dwh].[DimEncounter] en ON en.[EncounterName] = event_choices.[event_name] AND en.[EncounterType] = 'event'
)

-- [dwh].[FactFloorEvent]
INSERT INTO [dwh].[FactFloorEvent]
SELECT 
	-- dimension ids
	path_per_floor.[play_id] AS [PlayId],
	path_per_floor.[floor] AS [Floor],
	p.[PathId],
	COALESCE(encounter.[EncounterId],event_choice.[EncounterId]) AS [EncounterId],
	ev.[EventChoiceId],
	-- measures
	COALESCE(encounter.[damage],event_choice.[damage_taken]) AS [DamageTaken],	
	encounter.[turns] AS [TurnsTaken],
	-- logging
	getdate() AS [ETLInsertedAt],
	getdate() AS [ETLUpdatedAt],
	system_user AS [ETLUser]	
FROM path_per_floor
LEFT JOIN encounter ON path_per_floor.[play_id] = encounter.[play_id] AND path_per_floor.[floor] = encounter.[floor]
LEFT JOIN event_choice ON path_per_floor.[play_id] = event_choice.[play_id] AND path_per_floor.[floor] = event_choice.[floor]
LEFT JOIN [dwh].[DimPath] p ON p.[PathType] = path_per_floor.[path_taken]
LEFT JOIN [dwh].[DimEventChoice] ev ON ev.[EventName] = event_choice.[event_name] AND ev.[PlayerChoice] = event_choice.[player_choice]

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
-- cards purged
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
--  relics
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
-- master deck
SELECT 
	[play_id],
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s') AS [ItemName],
	'?' AS [path_taken],
	CASE	WHEN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') IN ('Defend_R','Defend_G','Defend_B','Strike_R','Strike_G','Strike_B','Bash','Neutralize','Survivor','Dualcast','Zap','AscendersBane') THEN 'starter_card'
			ELSE 'looted_from_event'
	END AS [ItemInteraction]
FROM [imp].[StSJSONData]
CROSS APPLY STRING_SPLIT([master_deck], ',') as master_deck
)

-- [dwh].[FactFloorItem]
INSERT INTO [dwh].[FactFloorItem]
SELECT 
	-- dimension ids
	path_per_floor.[play_id] AS [PlayId],
	path_per_floor.[floor] AS [Floor],
	p.[PathId],
	i.[ItemId],
	ia.[ItemInteractionId],
	-- logging
	getdate() AS [ETLInsertedAt],
	getdate() AS [ETLUpdatedAt],
	system_user AS [ETLUser]
FROM path_per_floor
LEFT JOIN item_interaction ON item_interaction.[play_id] = path_per_floor.[play_id] AND item_interaction.[Floor] = path_per_floor.[floor]
LEFT JOIN [dwh].[DimItem] i ON i.[ItemName] = item_interaction.[ItemName]
LEFT JOIN [dwh].[DimItemInteraction] ia ON ia.[ItemInteractionName] = item_interaction.[ItemInteraction]
LEFT JOIN [dwh].[DimPath] p ON p.[PathType] = path_per_floor.[path_taken]
UNION ALL
-- relics, master deck, starter_relics, starter_cards
SELECT 
	-- dimension ids
	item_end_of_run.[play_id] AS [PlayId],
	0 AS [Floor],
	p.[PathId],
	i.[ItemId],
	ia.[ItemInteractionId],
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

END