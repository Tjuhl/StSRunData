CREATE PROCEDURE [imp].[spStSRunLoadDimensions] AS

BEGIN 
	
-- [dwh].[DimAscensionLevel]
INSERT INTO [dwh].[DimAscensionLevel]
SELECT 
	distinct [ascension_level],
	getdate(),
	getdate(),
	system_user
FROM [imp].[StSJSONData]

-- [dwh].[DimBuildVersion]
INSERT INTO [dwh].[DimBuildVersion]
SELECT 
	distinct [build_version],
	getdate(),
	getdate(),
	system_user
FROM [imp].[StSJSONData]

-- [dwh].[DimCharacter]
INSERT INTO [dwh].[DimCharacter]
SELECT 
	distinct [character_chosen],
	getdate(),
	getdate(),
	system_user
FROM [imp].[StSJSONData] 

-- [dwh].[DimEncounter]
INSERT INTO [dwh].[DimEncounter]
-- encounters
SELECT 
	distinct [enemies],
	'encounter' AS [EncounterType],
	getdate(),
	getdate(),
	system_user
FROM [imp].[StSJSONData]
CROSS APPLY OPENJSON ([damage_taken])
WITH (
	[enemies] nvarchar(255)	
	)
UNION ALL
-- events
SELECT 
	distinct [event_name],
	'event' AS [EncounterType],
	getdate(),
	getdate(),
	system_user
FROM [imp].[StSJSONData]
CROSS APPLY OPENJSON ([event_choices])
WITH (
	[event_name] nvarchar(255)	
	)
UNION ALL
-- victory
SELECT 
	'victory!?',
	'encounter' AS [EncouterType],
	getdate(),
	getdate(),
	system_user

-- [dwh].[DimEventChoice]
INSERT INTO [dwh].[DimEventChoice]
SELECT 
	distinct [event_name], 
	[player_choice],
	getdate(),
	getdate(),
	system_user
FROM [imp].[StSJSONData]
CROSS APPLY OPENJSON ([event_choices])
WITH (
	[event_name] nvarchar(255),
	[player_choice] nvarchar(255)
)

-- [dwh].[DimPath]
INSERT INTO [dwh].[DimPath]
SELECT 
	t.[path_type],
	CASE WHEN t.[path_type] = '$' THEN 'shop' 
	WHEN t.[path_type] = 'T' THEN 'treasure' 
	WHEN t.[path_type] = 'E' THEN 'elite' 
	WHEN t.[path_type] = '?' THEN 'event' 
	WHEN t.[path_type] = 'R' THEN 'campfire' 
	WHEN t.[path_type] = 'M' THEN 'enemy' 
	WHEN t.[path_type] = 'BOSS' THEN 'boss'
	WHEN t.[path_type] = 'brel' THEN 'boss_relic' 
	WHEN t.[path_type] = 'act4' THEN 'act_4'
	ELSE 'unknown'
	END AS [path_name],
	getdate(),
	getdate(),
	system_user	
FROM 
	(	
	SELECT 
		DISTINCT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s') AS [path_type]
	FROM [imp].[StSJSONData]
	CROSS APPLY STRING_SPLIT([path_taken], ',')
	) t

-- [dwh].[DimItem]
INSERT INTO [dwh].[DimItem]
SELECT DISTINCT 
	tt.[ItemName],
	tt.[ItemType],
	getdate(),
	getdate(),
	system_user
FROM 
	(
	-- cards in master deck at end of run
	SELECT 
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
		'card' AS [ItemType]
	FROM [imp].[StSJSONData]
	CROSS APPLY STRING_SPLIT([master_deck], ',')
		WHERE value != '[]'
	UNION ALL
	-- cards picked
	SELECT 
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(card_choices.[picked],'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
		'card' AS [ItemType]
	FROM [imp].[StSJSONData]
	CROSS APPLY OPENJSON ([card_choices]) 
	WITH ([picked] nvarchar(255)) AS card_choices
		WHERE card_choices.[picked] != '[]'
	UNION ALL 
	-- cards not picked
	SELECT 
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
		'card' AS [ItemType]
	FROM [imp].[StSJSONData]
	CROSS APPLY OPENJSON ([card_choices]) 
	WITH (
		[not_picked] nvarchar(max) AS JSON
		) AS not_picked
		CROSS APPLY STRING_SPLIT([not_picked], ',')
			WHERE value != '[]'
	UNION ALL 
	-- cards purged
	SELECT 
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
		'card' AS [ItemType]
	FROM [imp].[StSJSONData]
	CROSS APPLY STRING_SPLIT([items_purged], ',')
		WHERE value != '[]'
	UNION ALL 
	-- relics at end of run
	SELECT 
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
		'relic' AS [ItemType]
	FROM [imp].[StSJSONData]
	CROSS APPLY STRING_SPLIT([relics], ',')	
		WHERE value != '[]'
	UNION ALL
	-- relics obtained 
	SELECT 
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(relics_obtained.[key],'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
		'relic' AS [ItemType]
	FROM [imp].[StSJSONData]
	CROSS APPLY OPENJSON ([relics_obtained]) 
	WITH ([key] nvarchar(255)) AS relics_obtained 
		WHERE relics_obtained.[key] != '[]'
	UNION ALL 
	-- boss relics picked
	SELECT 
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(boss_relics_picked.[picked],'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
		'relic' AS [ItemType]
	FROM [imp].[StSJSONData]
	CROSS APPLY OPENJSON ([boss_relics]) 
	WITH ([picked] nvarchar(255)) AS boss_relics_picked
		WHERE boss_relics_picked.[picked] != '[]'
	UNION ALL 
	-- boss relics not picked
	SELECT 
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
		'relic' AS [ItemType]
	FROM [imp].[StSJSONData]
	CROSS APPLY OPENJSON ([boss_relics]) 
	WITH ([not_picked] nvarchar(max) AS JSON) AS not_picked
		CROSS APPLY STRING_SPLIT([not_picked], ',')
			WHERE value != '[]'
	UNION ALL 
	-- potions looted
	SELECT 
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([key],'"',''),']',''),'[',''),' ',''),'\u0027s','s'),'''','') AS [ItemName],
		'potion' AS [ItemType]
	FROM [imp].[StSJSONData]
	CROSS APPLY OPENJSON ([potions_obtained])
	WITH ([key] nvarchar(255)) AS J	
		WHERE [key] != '[]'
	) tt

-- [dwh].[DimItemInteraction]
INSERT INTO [dwh].[DimItemInteraction] ([ItemInteractionName],[ETLInsertedAt],[ETLUpdatedAt],[ETLUser])
VALUES
('potion_looted',getdate(),getdate(),SYSTEM_USER),
('relic_looted',getdate(),getdate(),SYSTEM_USER),
('card_picked',getdate(),getdate(),SYSTEM_USER),
('card_purged',getdate(),getdate(),SYSTEM_USER),
('item_purchased',getdate(),getdate(),SYSTEM_USER),
('card_not_picked',getdate(),getdate(),SYSTEM_USER),
('boss_relic_picked',getdate(),getdate(),SYSTEM_USER),
('boss_relic_not_picked',getdate(),getdate(),SYSTEM_USER),
('looted_from_event',getdate(),getdate(),SYSTEM_USER),
('starter_relic',getdate(),getdate(),SYSTEM_USER),
('starter_card',getdate(),getdate(),SYSTEM_USER),
('card_upgraded',getdate(),getdate(),SYSTEM_USER)

-- [dwh].[DimStartingBonus]
INSERT INTO [dwh].[DimStartingBonus]
SELECT 
	distinct [neow_bonus], 
	[neow_cost],
	getdate(),
	getdate(),
	system_user
FROM [imp].[StSJSONData]

-- [dwh].[DimVictory]
INSERT INTO [dwh].[DimVictory]
SELECT 
	distinct [victory],
	getdate(),
	getdate(),
	system_user
FROM [imp].[StSJSONData]

END