SELECT 
	c.[CharacterChosen],
	--fi.[Floor],	
	p.[PathName],
	ii.[ItemInteractionName],
	i.[ItemName],
	COUNT(fi.[ItemId]) AS [itemCount]	
FROM [dwh].[FactRun] r 
LEFT JOIN [dwh].[FactFloorItem] fi ON r.[PlayId] = fi.[PlayId]
LEFT JOIN [dwh].[DimItemInteraction] ii ON ii.[ItemInteractionId] = fi.[ItemInteractionId]
LEFT JOIN [dwh].[DimPath] p ON p.[PathId] = fi.[PathId]
LEFT JOIN [dwh].[DimCharacter] c ON c.[CharacterId] = r.[CharacterId]
LEFT JOIN [dwh].[DimItem] i ON i.[ItemId] = fi.[ItemId]
	WHERE fi.[ItemInteractionId] IN (3,6)	
	AND r.[AscensionLevelId] = 7
		GROUP BY c.[CharacterChosen], fi.[Floor], p.[PathName],	ii.[ItemInteractionName], i.[ItemName]