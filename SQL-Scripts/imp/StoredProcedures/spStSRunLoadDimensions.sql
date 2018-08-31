CREATE PROCEDURE [imp].[spStSRunLoadDimensions]
AS 

BEGIN 
	-- [dwh].[DimAscensionLevel]
	INSERT INTO [dwh].[DimAscensionLevel]
	SELECT 
		distinct j.[ascension_level],
		getdate(),
		getdate(),
		system_user
	FROM [imp].[StSJSONData] j
	LEFT OUTER JOIN [dwh].[DimAscensionLevel] s ON s.[AscensionLevel] = j.[ascension_level]
		WHERE s.[AscensionLevel] is null

	-- [dwh].[DimBuildVersion]
	INSERT INTO [dwh].[DimBuildVersion]
	SELECT 
		distinct j.[build_version],
		getdate(),
		getdate(),
		system_user
	FROM [imp].[StSJSONData] j
	LEFT OUTER JOIN [dwh].[DimBuildVersion] s ON s.[BuildVersion] = j.[build_version]
		WHERE s.[BuildVersion] is null

	-- [dwh].[DimCampfire]
	INSERT INTO [dwh].[DimCampfire]
	SELECT 
		distinct j.[data],	
		j.[key],
		getdate() as [ETLInsertedAt],
		getdate() as [ETLUpdatedAt],
		system_user as [ETLUser]
	FROM [imp].[StSJSONData]
	CROSS APPLY OPENJSON ([campfire_choices])
	WITH (
		[data] nvarchar(255),     
		[key] nvarchar(20)
	) AS J
	LEFT OUTER JOIN [dwh].[DimCampfire] s ON s.[CampfireChoice] = j.[data] AND s.[CampfireAction] = j.[key]
		WHERE s.[CampfireChoice] is null
		AND s.[CampfireAction] is null

	-- [dwh].[DimCharacter]
	INSERT INTO [dwh].[DimCharacter]
	SELECT 
		distinct [character_chosen],
		getdate(),
		getdate(),
		system_user
	FROM [imp].[StSJSONData] 
	LEFT OUTER JOIN [dwh].[DimCharacter] s ON s.[CharacterChosen] = [character_chosen]
		WHERE s.[CharacterChosen] is null

	-- [dwh].[DimEncounter]
	INSERT INTO [dwh].[DimEncounter]
	SELECT 
		distinct [enemies], 
		getdate(),
		getdate(),
		system_user
	FROM [imp].[StSJSONData]
	CROSS APPLY OPENJSON ([damage_taken])
	WITH (
		[enemies] nvarchar(255)	
	) AS J
	LEFT OUTER JOIN [dwh].[DimEncounter] s ON s.[EncounterName] = j.[enemies]
		WHERE s.[EncounterName] is null

	-- [dwh].[DimEvent]
	INSERT INTO [dwh].[DimEvent]
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
	) AS J
	LEFT OUTER JOIN [dwh].[DimEvent] s ON s.[EventName] = j.[event_name] AND s.[PlayerChoice] = j.[player_choice]
		WHERE s.[EventName] is null

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
		ELSE 'unknown'
		END AS [path_name],
		getdate(),
		getdate(),
		system_user	
	FROM 
		(	
		SELECT 
			DISTINCT REPLACE(REPLACE(REPLACE(REPLACE(value,'[',''),']',''),' ',''),'"','') AS [path_type]
		FROM [imp].[StSJSONData]
		CROSS APPLY STRING_SPLIT([path_taken], ',')
		) t
	LEFT OUTER JOIN [dwh].[DimPath] s ON s.[PathType] = t.[path_type]
		WHERE s.[PathType] is null
		OR s.[PathName] is null

	-- [dwh].[DimItem]
	INSERT INTO [dwh].[DimItem]
	SELECT  
		tt.[ItemName],
		tt.[ItemType],
		getdate(),
		getdate(),
		system_user
	FROM 
		(
		SELECT 
			distinct card_choices.[picked] AS [ItemName],
			'card' AS [ItemType]
		FROM [imp].[StSJSONData] j
		CROSS APPLY OPENJSON ([card_choices]) 
		WITH ([picked] nvarchar(255)) AS card_choices
		UNION ALL 
		SELECT 
			distinct REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,' "',''),']',''),'[',''),'"',''),'\u0027s','s')  AS [ItemName],
			'card' AS [ItemType]
		FROM [imp].[StSJSONData]
		CROSS APPLY STRING_SPLIT([master_deck], ',')
		UNION ALL 
		SELECT 
			distinct [key] AS [ItemName],
			'potion' AS [ItemType]
		FROM [imp].[StSJSONData]
		CROSS APPLY OPENJSON ([potions_obtained])
		WITH ([key] nvarchar(255)) AS J	
		UNION ALL 
		SELECT 
			distinct REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,' "',''),']',''),'[',''),'"',''),'\u0027s','s') AS [ItemName],
			'relic' AS [ItemType]
		FROM [imp].[StSJSONData]
		CROSS APPLY STRING_SPLIT([relics], ',')	
		) tt
	LEFT OUTER JOIN [dwh].[DimItem] s ON s.[ItemName] = tt.[ItemName] AND s.[ItemType] = tt.[ItemType]
		WHERE s.[ItemName] is null
		OR s.[ItemType] is null	

	-- [dwh].[DimStartingBonus]
	INSERT INTO [dwh].[DimStartingBonus]
	SELECT 
		distinct [neow_bonus], 
		[neow_cost],
		getdate(),
		getdate(),
		system_user
	FROM [imp].[StSJSONData] 
	LEFT OUTER JOIN [dwh].[DimStartingBonus] s ON s.[StartingBonusName] = [neow_bonus] AND s.[StartingBonusCost] = [neow_cost]
		WHERE s.[StartingBonusName] is null

	-- [dwh].[DimVictory]
	INSERT INTO [dwh].[DimVictory]
	SELECT 
		distinct [victory],
		getdate(),
		getdate(),
		system_user
	FROM [imp].[StSJSONData] 
	LEFT OUTER JOIN [dwh].[DimVictory] s ON s.[VictoryTF] = [victory]
		WHERE s.[VictoryTF] is null

END
GO


