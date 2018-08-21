CREATE TABLE [dwh].[DimAscensionLevel]
(
	[AscensionLevelId] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[AscensionLevel] INT null,
	[ETLInsertedAt] DATETIME null,
	[ETLUpdatedAt] DATETIME null,
	[ETLUSer] nvarchar(50) null
)