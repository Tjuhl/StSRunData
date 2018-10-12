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

	-- [dwh].[FactFloor]
	INSERT INTO [dwh].[FactFloor]
	SELECT  
		j.[play_id] AS [PlayId],
		cur_hp.[floor] AS [Floor],
		floor_path.[PathId],
		-- json data for floors [campfire_choices], [event_choices]
		campfire_choices.[CampfireChoiceId],
		-- all floors info [current_hp_per_floor],[gold_per_floor], [max_hp_per_floor], [path_per_floor], [path_taken]	
		cur_hp.[current_hp_per_floor] AS [CurrentHP],
		max_hp.[max_hp_per_floor] AS [MaxHP],
		cur_gold.[gold_per_floor] AS [Gold],	
		-- certain floor info [item_purchase_floors]+[items_purchased], [items_purged]+[items_purged_floors], [potions_floor_spawned], [potions_floor_usage]
		items_purchased.[items_purchased] AS [ItemsPurchased],
		items_purged.[items_purged] AS [ItemsPurged],
		potions_spawned.[potions_spawned] AS [PotionsSpawned],
		potions_used.[potions_used] AS [PotionsUsed],
		getdate() AS [ETLInsertedAt],
		getdate() AS [ETLUpdatedAt],
		system_user AS [ETLUser]	
	FROM [imp].[StSJSONData] j
	-- current hp per floor
	LEFT JOIN 
		(
		SELECT 
			j.[play_id],
			ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [floor],
			REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[','') AS [current_hp_per_floor]
		FROM [imp].[StSJSONData] j
		CROSS APPLY STRING_SPLIT([current_hp_per_floor], ',')
		) AS cur_hp ON cur_hp.[play_id] = j.[play_id]
	-- path per floor
	LEFT JOIN 
		(
		SELECT 
			t.[play_id],
			p.[PathId],
			t.[floor]
		FROM 
			(
			SELECT 
				j.[play_id],
				REPLACE(REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[',''),'"','') AS [path_taken],
				ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [floor]	
			FROM [imp].[StSJSONData] j
			CROSS APPLY STRING_SPLIT([path_taken], ',')		
			) t
		LEFT JOIN [dwh].[DimPath] p ON p.[PathType] = t.[path_taken]
		) AS [floor_path] ON floor_path.[play_id] = j.[play_id] AND floor_path.[floor] = cur_hp.[floor]
	-- max hp per floor
	LEFT JOIN 
		(
		SELECT 
			play_id,
			REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[','') AS [max_hp_per_floor],
			ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [floor]	
		FROM [imp].[StSJSONData] j
		CROSS APPLY STRING_SPLIT([max_hp_per_floor], ',')		
		) AS max_hp ON max_hp.[play_id] = j.[play_id] AND max_hp.[floor] = cur_hp.[floor]
	-- gold per floor
	LEFT JOIN 
		(
		SELECT 
			play_id,
			REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[','') AS [gold_per_floor],
			ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [floor]	
		FROM [imp].[StSJSONData] j
		CROSS APPLY STRING_SPLIT([gold_per_floor], ',')		
		) AS cur_gold ON cur_gold.[play_id] = j.[play_id] AND cur_gold.[floor] = cur_hp.[floor]
	-- item purchases per floor
	LEFT JOIN 
		(
		SELECT  
			t.[play_id],
			t.[item_purchase_floor],
			COUNT(t.[item_purchase_floor]) AS [items_purchased]
		FROM  
			(
			SELECT 
				j.[play_id],
				CASE WHEN value = '[]' THEN NULL ELSE REPLACE(REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[',''),'"','') END AS [item_purchase_floor],
				ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) AS [col_index]
			FROM [imp].[StSJSONData] j
			CROSS APPLY STRING_SPLIT([item_purchase_floors], ',')
			) AS t
				 GROUP BY t.[play_id], t.[item_purchase_floor]
		) AS items_purchased ON items_purchased.[play_id] = j.[play_id] AND items_purchased.[item_purchase_floor] = cur_hp.[floor]
	-- item purged 
	LEFT JOIN 
		(
		SELECT  
			t.[play_id],
			t.[item_purged_floor],
			COUNT(t.[item_purged_floor]) AS [items_purged]
		FROM  
			(
			SELECT 
				j.[play_id],
				CASE WHEN value = '[]' THEN NULL ELSE REPLACE(REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[',''),'"','') END AS [item_purged_floor],
				ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) AS [col_index]
			FROM [imp].[StSJSONData] j
			CROSS APPLY STRING_SPLIT([items_purged_floors], ',')
			) t	
				GROUP BY t.[play_id], t.[item_purged_floor]
		) AS items_purged ON items_purged.[play_id] = j.[play_id] AND items_purged.[item_purged_floor] = cur_hp.[floor]
	-- potions spawned per floor
	LEFT JOIN 
		(
		SELECT  
			t.[play_id],
			t.[potions_floor_spawned],
			COUNT(t.[potions_floor_spawned]) AS [potions_spawned]
		FROM  
			(
			SELECT 
				j.[play_id],
				CASE WHEN value = '[]' THEN NULL ELSE REPLACE(REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[',''),'"','') END AS [potions_floor_spawned],
				ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) AS [col_index]
			FROM [imp].[StSJSONData] j
			CROSS APPLY STRING_SPLIT([potions_floor_spawned], ',')
			) AS t
				 GROUP BY t.[play_id], t.[potions_floor_spawned]
		) AS potions_spawned ON potions_spawned.[play_id] = j.[play_id] AND potions_spawned.[potions_floor_spawned] = cur_hp.[floor]
	-- potions used per floor
	LEFT JOIN 
		(
		SELECT  
			t.[play_id],
			t.[potions_floor_usage],
			COUNT(t.[potions_floor_usage]) AS [potions_used]
		FROM  
			(
			SELECT 
				j.[play_id],
				CASE WHEN value = '[]' THEN NULL ELSE REPLACE(REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[',''),'"','') END AS [potions_floor_usage],
				ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) AS [col_index]
			FROM [imp].[StSJSONData] j
			CROSS APPLY STRING_SPLIT([potions_floor_usage], ',')
			) AS t
				 GROUP BY t.[play_id], t.[potions_floor_usage]
		) AS potions_used ON potions_used.[play_id] = j.[play_id] AND potions_used.[potions_floor_usage] = cur_hp.[floor]
	-- campfire choice
	LEFT JOIN 
		(
		SELECT  
			j.[play_id],
			CONVERT(int,(CASE WHEN [floor] like '%.%' THEN SUBSTRING([floor],0,CHARINDEX('.',[floor],0)) 
			ELSE [floor] 
			END)) AS [floor],
			CASE	WHEN campfire_choices.[key] = 'DIG' THEN 43
					WHEN campfire_choices.[key] = 'REST' THEN 87
			ELSE c.[CampfireChoiceId] END AS [CampfireChoiceId]
		FROM [imp].[StSJSONData] j
		CROSS APPLY OPENJSON (campfire_choices)
		WITH 
		(
			[floor] nvarchar(5),
			[data] nvarchar(255),     
			[key] nvarchar(20)
		) AS campfire_choices 
		LEFT JOIN [dwh].[DimCampfire] c ON c.[CampfireChoice] = campfire_choices.[data] AND c.[CampfireAction] = campfire_choices.[key]
		) AS campfire_choices ON campfire_choices.[play_id] = j.[play_id] AND campfire_choices.[floor] = cur_hp.[floor]
		LEFT OUTER JOIN [dwh].[FactFloor] t ON t.[PlayId] = j.[play_id]
		WHERE t.[PlayId] is null

	-- [dwh].[FactFloorEvent]
	INSERT INTO [dwh].[FactFloorEvent]
	-- dwh.FactFloorEvent
	SELECT 
		j.[play_id] AS [PlayId],
		floor_path.[floor] AS [Floor],
		floor_path.[PathId],
		encounter.[EncounterId],
		event_choices.[EventId],	
		COALESCE(encounter.[damage],event_choices.[damage_taken]) AS [DamageTaken],
		encounter.[turns] AS [TurnsTaken],
		getdate() AS [ETLInsertedAt],
		getdate() AS [ETLUpdatedAt],
		system_user AS [ETLUser]	
	FROM [imp].[StSJSONData] j
	-- path per floor
	LEFT JOIN 
		(
		SELECT 
			t.[play_id],
			p.[PathId],
			t.[floor]
		FROM 
			(
			SELECT 
				j.[play_id],
				REPLACE(REPLACE(REPLACE(REPLACE(value,' ',''),']',''),'[',''),'"','') AS [path_taken],
				ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [floor]	
			FROM [imp].[StSJSONData] j
			CROSS APPLY STRING_SPLIT([path_taken], ',')		
			) t
		LEFT JOIN [dwh].[DimPath] p ON p.[PathType] = t.[path_taken]
		) AS floor_path ON floor_path.[play_id] = j.[play_id]
	-- encounter
	LEFT JOIN 
		(
		SELECT 
			j.[play_id],
			CONVERT(int,(CASE WHEN [floor] like '%.%' THEN SUBSTRING([floor],0,CHARINDEX('.',[floor],0)) ELSE [floor] END)) AS [floor],
			encounter.[enemies],
			en.[EncounterId],
			CONVERT(int,(CASE WHEN [damage] like '%.%' THEN SUBSTRING([damage],0,CHARINDEX('.',[damage],0)) ELSE [damage] END)) AS [damage],
			CONVERT(int,(CASE WHEN [turns] like '%.%' THEN SUBSTRING([turns],0,CHARINDEX('.',[turns],0)) ELSE [turns] END)) AS [turns]
		FROM [imp].[StSJSONData] j
		CROSS APPLY OPENJSON ([damage_taken]) 
		WITH (
			[damage] nvarchar(5),
			[enemies] nvarchar(255), 
			[floor] nvarchar(5), 
			[turns] nvarchar(5)
		) AS encounter 
		LEFT JOIN [dwh].[DimEncounter] en ON en.[EncounterName] = encounter.[enemies]
		) AS encounter ON encounter.[play_id] = j.[play_id] AND floor_path.[floor] = encounter.[floor]
	-- event
	LEFT JOIN 
		(
		SELECT 
			j.[play_id],
			CONVERT(int,(CASE WHEN event_choices.[floor] like '%.%' THEN SUBSTRING(event_choices.[floor],0,CHARINDEX('.',event_choices.[floor],0)) ELSE event_choices.[floor] END)) AS [floor],
			CONVERT(int,(CASE WHEN event_choices.[damage_taken] like '%.%' THEN SUBSTRING(event_choices.[damage_taken],0,CHARINDEX('.',event_choices.[damage_taken],0)) ELSE event_choices.[damage_taken] END)) AS [damage_taken],
			e.[EventId]
		FROM [imp].[StSJSONData] j
		CROSS APPLY OPENJSON ([event_choices]) 
		WITH (
			[damage_taken] nvarchar(5),
			[event_name] nvarchar(255), 
			[floor] nvarchar(5), 
			[player_choice] nvarchar(255)
		) AS event_choices 
		LEFT JOIN [dwh].[DimEvent] e ON e.[EventName] = event_choices.[event_name] AND e.[PlayerChoice] = event_choices.[player_choice]
		) AS event_choices ON event_choices.[play_id] = j.[play_id] AND event_choices.[floor] = floor_path.[floor]
		LEFT OUTER JOIN [dwh].[FactFloorEvent] t ON t.[PlayId] = j.[play_id]
	WHERE t.[PlayId] is null
	AND (encounter.[EncounterId] IS NOT NULL OR event_choices.[EventId] IS NOT NULL)

	-- [dwh].[FactFloorItem]
	INSERT INTO [dwh].[FactFloorItem]
	-- dwh.FactFloorItem
	SELECT 
		j.[play_id] AS [PlayId],
		IFNULL(floor_path.[floor],0) AS [Floor],
		floor_path.[PathId],
		i.[ItemId],
		CASE 
			-- start relic
			WHEN i.[ItemName] IN ('BurningBlood','CrackedCore','RingoftheSnake') THEN 10 
			-- items obtained through events
			WHEN ia.[ItemInteractionName] IS NULL THEN 9
			-- items obtained through item interactions like purchase, purge, loot
			ELSE ia.[ItemInteractionId] 
		END AS [ItemInteractionId],
		getdate() AS [ETLInsertedAt],
		getdate() AS [ETLUpdatedAt],
		system_user AS [ETLUser]	
	FROM [imp].[StSJSONData] j
	-- path per floor
	LEFT JOIN 
		(
		SELECT 
			t.[play_id],
			p.[PathId],
			t.[floor]
		FROM 
			(
			SELECT 
				j.[play_id],
				REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s') AS [path_taken],
				ROW_NUMBER() OVER (PARTITION BY [play_id] ORDER BY [play_id] ASC) AS [floor]	
			FROM [imp].[StSJSONData] j
			CROSS APPLY STRING_SPLIT([path_taken], ',')		
			) t
		LEFT JOIN [dwh].[DimPath] p ON p.[PathType] = t.[path_taken]
		) AS floor_path ON floor_path.[play_id] = j.[play_id]
	-- item id and item interaction
	LEFT JOIN 
		(
		-- item purged
		SELECT  
			purge_floor.[play_id],
			COALESCE(purge_floor.[item_purged_floor],0) AS [Floor],
			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(purge_item.[item_purged],'"',''),']',''),'[',''),' ',''),'\u0027s','s') AS [ItemName],
			'card_purged' AS [ItemInteraction]
		FROM  
			(
			SELECT 
				j.[play_id],
				CASE WHEN value = '[]' THEN NULL ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s') END AS [item_purged_floor],
				ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) AS [col_index]
			FROM [imp].[StSJSONData] j
			CROSS APPLY STRING_SPLIT([items_purged_floors], ',')
			) purge_floor
			LEFT JOIN 
			(
			SELECT 
				j.[play_id],
				CASE WHEN value = '[]' THEN NULL ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s') END AS [item_purged],
				ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) AS [col_index]			
			FROM [imp].[StSJSONData] j		
			CROSS APPLY STRING_SPLIT([items_purged], ',') 
			) purge_item ON purge_item.[play_id] = purge_floor.[play_id] AND purge_item.[col_index] = purge_floor.[col_index]
				WHERE purge_item.[item_purged] IS NOT NULL
		UNION ALL 
		-- card picked	
		SELECT 
			j.[play_id],
			CONVERT(int,(CASE WHEN card_picked.[floor] like '%.%' THEN SUBSTRING(card_picked.[floor],0,CHARINDEX('.',card_picked.[floor],0)) ELSE card_picked.[floor] END)) AS [floor],
			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([picked],'"',''),']',''),'[',''),' ',''),'\u0027s','s') AS [ItemName],
			'card_picked' AS [ItemInteraction]
		FROM [imp].[StSJSONData] j
		CROSS APPLY OPENJSON ([card_choices]) 
		WITH (
			[picked] nvarchar(255), 		
			[floor] nvarchar(5)
		) AS card_picked 
		-- card not picked
		UNION ALL 
		SELECT 
			j.[play_id],
			CONVERT(int,(CASE WHEN not_picked.[floor] like '%.%' THEN SUBSTRING(not_picked.[floor],0,CHARINDEX('.',not_picked.[floor],0)) ELSE not_picked.[floor] END)) AS [floor],
			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s') AS [ItemName],
			'card_not_picked' AS [ItemInteraction]
		FROM [imp].[StSJSONData] j
		CROSS APPLY OPENJSON ([card_choices]) 
		WITH (
		[not_picked] nvarchar(max) AS JSON,
		[floor] nvarchar(5)
		) AS not_picked
			CROSS APPLY STRING_SPLIT([not_picked], ',')
		-- relics obtained
		UNION ALL
		SELECT 
			j.[play_id],
			CONVERT(int,(CASE WHEN relics_obtained.[floor] like '%.%' THEN SUBSTRING(relics_obtained.[floor],0,CHARINDEX('.',relics_obtained.[floor],0)) ELSE relics_obtained.[floor] END)) AS [floor],
			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(relics_obtained.[key],'"',''),']',''),'[',''),' ',''),'\u0027s','s') AS [ItemName],
			'relic_looted'
		FROM [imp].[StSJSONData] j
		CROSS APPLY OPENJSON ([relics_obtained]) 
		WITH (
			[floor] nvarchar(5),
			[key] nvarchar(255)
		) AS relics_obtained 
		-- boss relics picked
		UNION ALL
		SELECT 
			j.[play_id],
			CASE WHEN ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) = 1 THEN 17 ELSE 34 END AS [floor],
			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(boss_relics_picked.[picked],'"',''),']',''),'[',''),' ',''),'\u0027s','s') AS [ItemName],
			'boss_relic_picked' AS [ItemInteraction]
		FROM [imp].[StSJSONData] j
		CROSS APPLY OPENJSON ([boss_relics]) 
		WITH (
			[picked] nvarchar(255)
		) AS boss_relics_picked
		-- boss relics not picked
		UNION ALL 
		SELECT 
			j.[play_id],
			CASE WHEN ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) = 1 THEN 17 ELSE 34 END AS [floor],
			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s') AS [ItemName],
			'boss_relic_not_picked' AS [ItemInteraction]
		FROM [imp].[StSJSONData] j
		CROSS APPLY OPENJSON ([boss_relics]) 
		WITH (
		[not_picked] nvarchar(max) AS JSON,
		[floor] nvarchar(5)
		) AS not_picked
			CROSS APPLY STRING_SPLIT([not_picked], ',')
		-- items purchased
		UNION ALL 
		SELECT  
			purchase_floor.[play_id],
			COALESCE(purchase_floor.[item_purchase_floor],0) AS [Floor],
			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(purchase_item.[item_purchased],'"',''),']',''),'[',''),' ',''),'\u0027s','s') AS [ItemName],
			'item_purchased' AS [ItemInteraction]	
		FROM  
			(
			SELECT 
				j.[play_id],
				CASE WHEN value = '[]' THEN NULL ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s') END AS [item_purchase_floor],
				ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) AS [col_index]
			FROM [imp].[StSJSONData] j
			CROSS APPLY STRING_SPLIT([item_purchase_floors], ',')
			) purchase_floor
			LEFT JOIN 
			(
			SELECT 
				j.[play_id],
				CASE WHEN value = '[]' THEN NULL ELSE REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(value,'"',''),']',''),'[',''),' ',''),'\u0027s','s') END AS [item_purchased],
				ROW_NUMBER() OVER (PARTITION BY j.[play_id] ORDER BY j.[play_id] ASC) AS [col_index]			
			FROM [imp].[StSJSONData] j		
			CROSS APPLY STRING_SPLIT([items_purchased], ',') 
			) purchase_item ON purchase_item.[play_id] = purchase_floor.[play_id] AND purchase_item.[col_index] = purchase_floor.[col_index]
				WHERE purchase_item.[item_purchased] IS NOT NULL
		-- potions obtained
		UNION ALL
		SELECT 
			j.[play_id],
			CONVERT(int,(CASE WHEN potions_obtained.[floor] like '%.%' THEN SUBSTRING(potions_obtained.[floor],0,CHARINDEX('.',potions_obtained.[floor],0)) ELSE potions_obtained.[floor] END)) AS [floor],
			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(potions_obtained.[key],'"',''),']',''),'[',''),' ',''),'\u0027s','s') AS [ItemName],
			'potion_looted'
		FROM [imp].[StSJSONData] j
		CROSS APPLY OPENJSON ([potions_obtained]) 
		WITH (
			[floor] nvarchar(5),
			[key] nvarchar(255)
		) AS potions_obtained 
	) AS item ON item.[play_id] = j.[play_id] AND item.[Floor] = floor_path.[floor]
	LEFT JOIN [dwh].[DimItem] i ON i.[ItemName] = item.[ItemName]
	LEFT JOIN [dwh].[DimItemInteraction] ia ON ia.[ItemInteractionName] = item.[ItemInteraction]
	LEFT OUTER JOIN [dwh].[FactFloorItem] t ON t.[PlayId] = j.[play_id]
		WHERE t.[PlayId] is null
END;