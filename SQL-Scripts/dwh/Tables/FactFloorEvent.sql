CREATE TABLE [dwh].[FactFloorEvent]
(
	[PlayId] nvarchar(36) not null,
	[Floor] int null,
	[PathId] int null,
	[EncounterId] int null,
	[EventId] int null,
	[DamageTaken] int null,
	[TurnsTaken] int null,
	[ETLInsertedAt] datetime null,
	[ETLUpdatedAt] datetime null,
	[ETLUser] nvarchar(50) null
)