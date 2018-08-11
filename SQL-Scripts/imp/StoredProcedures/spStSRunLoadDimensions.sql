CREATE PROCEDURE imp.spStSRunLoadDimensions
AS 

BEGIN 

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

	-- [dwh].[DimCard]
	INSERT INTO [dwh].[DimCard]
	SELECT 
		distinct REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),
		getdate(),
		getdate(),
		system_user
	FROM [imp].[StSJSONData]
	CROSS APPLY STRING_SPLIT([master_deck], ',')
	LEFT OUTER JOIN [dwh].[DimCard] s ON s.[CardName] = value
		WHERE s.[CardName] is null

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
		ELSE 'unknown'
		END AS [path_name],
		getdate(),
		getdate(),
		system_user	
	FROM 
		(	
		SELECT 
			distinct replace(replace(replace(replace(value,'[',''),']',''),' ',''),'"','') as [path_type]
		FROM [imp].[StSJSONData]
		CROSS APPLY STRING_SPLIT([path_taken], ',')
		) t
	LEFT OUTER JOIN [dwh].[DimPath] s ON s.[PathType] = t.[path_type]
		WHERE s.[PathType] is null
		OR s.[PathName] is null

	-- [dwh].[DimPotion] 
	INSERT INTO [dwh].[DimPotion]
	SELECT 
		distinct [key],
		getdate(),
		getdate(),
		system_user
	FROM [imp].[StSJSONData]
	CROSS APPLY OPENJSON ([potions_obtained])
	WITH (
		[key] nvarchar(255)
	) AS J
	LEFT OUTER JOIN [dwh].[DimPotion] s ON s.[PotionName] = j.[key]
		WHERE s.[PotionName] is null

	-- [dwh].[DimRelic]
	INSERT INTO [dwh].[DimRelic]
	SELECT 
		distinct REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),
		getdate(),
		getdate(),
		system_user
	FROM [imp].[StSJSONData]
	CROSS APPLY STRING_SPLIT([relics], ',')
	LEFT OUTER JOIN [dwh].[DimRelic] s ON s.[RelicName] = value
		WHERE s.[RelicName] is null

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
		distinct CASE WHEN [victory]='true' then 1 else 0 end as [victory],
		getdate(),
		getdate(),
		system_user
	FROM [imp].[StSJSONData] 
	LEFT OUTER JOIN [dwh].[DimVictory] s ON s.[VictoryTF] = [victory]
		WHERE s.[VictoryTF] is null

END