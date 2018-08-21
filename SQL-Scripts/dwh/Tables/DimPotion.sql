create table dwh.DimPotion -- "potions_obtained": [{"floor": 5,"key": "Regen Potion"}
(
	PotionId int identity(1,1) not null,
	PotionName nvarchar(255) null, 
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
    CONSTRAINT [PK_DimPotion] PRIMARY KEY ([PotionId])
)