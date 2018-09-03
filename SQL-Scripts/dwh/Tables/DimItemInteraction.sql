CREATE TABLE [dwh].[DimItemInteraction]
(
	[ItemInteractionId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[ItemInteractionName] NVARCHAR(50) null,
	[ETLInsertedAt] DATETIME null,
	[ETLUpdatedAt] DATETIME null,
	[ETLUser] nvarchar(50) null
)