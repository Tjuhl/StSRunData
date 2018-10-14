create table dwh.DimEventChoice -- "event_choices": [{"damage_taken": 0,"event_name": "Living Wall","floor": 2,"player_choice": "Grow"}]
(
	EventChoiceId int identity(1,1) not null,
	EventName nvarchar(255) null,
	PlayerChoice nvarchar(255) null, 
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
    CONSTRAINT [PK_DimEventChoice] PRIMARY KEY ([EventChoiceId])
)