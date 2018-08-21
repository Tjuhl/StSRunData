create table dwh.DimEncounter -- "damage_taken": [{"damage": 6,"enemies": "2 Louse","floor": 1,"turns": 3}]
(
	EncounterId int identity(1,1) not null,
	EncounterName nvarchar(255) null, 
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
    CONSTRAINT [PK_DimEncounter] PRIMARY KEY ([EncounterId]),	
)