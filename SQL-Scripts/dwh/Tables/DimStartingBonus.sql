create table dwh.DimStartingBonus
(
	StartingBonusId int identity(1,1) not null,
	StartingBonusName nvarchar(25) null, -- "neow_bonus": "UPGRADE_CARD",
	StartingBonusCost nvarchar(25) null, -- "neow_cost": "NONE",
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
    CONSTRAINT [PK_DimStartingBonus] PRIMARY KEY ([StartingBonusId]))