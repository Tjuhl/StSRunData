create table dwh.DimItem -- cards, relics, potions
(
	ItemId int identity(1,1) not null,
	ItemName nvarchar(255) null, 
	ItemType nvarchar(50) null,
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
    CONSTRAINT [PK_DimItem] PRIMARY KEY ([ItemId])
)
