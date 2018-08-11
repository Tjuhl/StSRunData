create table dwh.DimBuildVersion -- "build_version": "2018-08-02",
(
	BuildId int identity(1,1) not null,
	BuildVersion nvarchar(20) null, 
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
    CONSTRAINT [PK_DimBuildVersion] PRIMARY KEY ([BuildId])
)