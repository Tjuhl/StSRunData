create table dwh.DimEvent -- "event_choices": [{"damage_taken": 0,"event_name": "Living Wall","floor": 2,"player_choice": "Grow"}]
(
	EventId int identity(1,1) not null,
	EventName nvarchar(50) null,
	PlayerChoice nvarchar(50) null, 
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
    CONSTRAINT [PK_DimEvent] PRIMARY KEY ([EventId])
)