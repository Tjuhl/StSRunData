CREATE TABLE [dwh].[FactFloor]
(
	[PlayId] nvarchar(36) not null,
	[Floor] int null,
	[PathId] int null,
	[CampfireAction] nvarchar(50) null, 
	[CampfireChoice] nvarchar(255) null,
	[CurrentHP] int null,
	[MaxHP] int null,
	[Gold] int null,
	[ItemsPurchased] int null,
	[ItemsPurged] int null,
	[PotionsSpawned] int null,
	[PotionsUsed] int null,
	[ETLInsertedAt] datetime null,
	[ETLUpdatedAt] datetime null,
	[ETLUser] nvarchar(50) null
)