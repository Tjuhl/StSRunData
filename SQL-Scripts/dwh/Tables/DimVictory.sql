create table dwh.DimVictory
(
	VictoryId int identity(1,1) not null,
	VictoryTF nvarchar(5) null, 
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
    CONSTRAINT [PK_DimVictory] PRIMARY KEY ([VictoryId])
)