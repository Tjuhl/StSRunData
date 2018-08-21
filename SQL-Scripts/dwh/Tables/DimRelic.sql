create table dwh.DimRelic -- "relics_obtained": [{"floor": 7,"key": "Orichalcum"}
(
	RelicId int identity(1,1) not null,
	RelicName nvarchar(255) null, 
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
    CONSTRAINT [PK_DimRelic] PRIMARY KEY ([RelicId])
)