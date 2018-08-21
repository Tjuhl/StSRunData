create table dwh.DimPath  -- "path_per_floor": ["M", "?", "$", "M", "M", "R", "E", "R", "T", "M", "E", "M", "M", "E", "R", "B", null, "M", "$", "?", "?", "$", "R", "M", "M", "T", "?", "$", "E", "R", "M", "R", "B", null, "M", "?", "M", "$", "M", "R", "E", "R", "T", "M", "M", "E", "M", "M", "R", "B"],
(
	PathId int identity(1,1) not null,
	PathType nvarchar(4) null, 
	PathName nvarchar(50) null, 
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
    CONSTRAINT [PK_DimPath] PRIMARY KEY ([PathId]), -- M = Encounter, ? = Event, $ = Shop, E = Elite, R = Campfire, B = Boss
)