create table dwh.DimCampfire -- "campfire_choices": [{"data": "True Grit","floor": 6,"key": "SMITH"}]
(
	CampfireChoiceId int identity(1,1) not null,
	CampfireChoice nvarchar(100) null,
	CampfireAction nvarchar(25) null, 
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
    CONSTRAINT [PK_DimCampfire] PRIMARY KEY ([CampfireChoiceId]),
)