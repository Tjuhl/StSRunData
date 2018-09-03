CREATE TABLE [dwh].[FactFloorItem]
(
	[PlayId] nvarchar(36) not null,
	[Floor] int null,
	[PathId] int null,
	[ItemId] int null,
	[ItemInteractionId] int null,
	[ETLInsertedAt] datetime null,
	[ETLUpdatedAt] datetime null,
	[ETLUser] nvarchar(50) null
)