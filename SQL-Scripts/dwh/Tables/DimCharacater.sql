create table dwh.DimCharacter -- "character_chosen": "DEFECT",
(
	CharacterId int identity(1,1) not null,
	CharacterChosen nvarchar(50) null, 
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
    CONSTRAINT [PK_DimCharacter] PRIMARY KEY ([CharacterId])
)