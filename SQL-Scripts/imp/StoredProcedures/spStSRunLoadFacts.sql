CREATE PROCEDURE [imp].[spStSRunLoadFacts]
AS 

BEGIN 
	-- [dwh].[FactRun]
	INSERT INTO [dwh].[FactRun]
	SELECT 
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
		getdate() AS [ETLInsertedAt],
		getdate() AS [ETLUpdatedAt],
		system_user AS [ETLUser]	
FROM [imp].[StSJSONData] s
	LEFT JOIN [dwh].[DimBuildVersion] b ON b.[BuildVersion] = s.[build_version]
	LEFT JOIN [dwh].[DimAscensionLevel] a ON a.[AscensionLevel] = s.[ascension_level]
	LEFT JOIN [dwh].[DimCharacter] c ON c.[CharacterChosen] = s.[character_chosen]
	LEFT JOIN [dwh].[DimStartingBonus] n ON n.[StartingBonusName] = s.[neow_bonus] AND n.[StartingBonusCost] = s.[neow_cost]
	LEFT JOIN [dwh].[DimEncounter] k ON k.[EncounterName] = s.[killed_by]
	LEFT JOIN [dwh].[DimVictory] v ON v.[VictoryTF] = s.[victory]
	LEFT OUTER JOIN [dwh].[FactRun] t ON t.[PlayId] = s.[play_id]
		WHERE t.[PlayId] is null
		
/*
	-- [dwh].[FactFloor]
	INSERT INTO [dwh].[FactFloor]
	SELECT 
		distinct j.[build_version],
		getdate(),
		getdate(),
		system_user
	FROM [imp].[StSJSONData] j
	LEFT OUTER JOIN [dwh].[DimBuildVersion] s ON s.[BuildVersion] = j.[build_version]
		WHERE s.[BuildVersion] is null
*/
END;
