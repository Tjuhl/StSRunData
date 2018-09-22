CREATE TABLE [dwh].[DimDate]
(
	[DateId] [bigint] IDENTITY(1,1) NOT NULL,
	[DateKey] [int] NULL,
	[Date] [datetime] NULL,
	[Year] [int] NULL,
	[MonthNumber] [tinyint] NULL,
	[MonthShort] [varchar](3) NULL,
	[Month] [varchar](10) NULL,
	[WeekdayNumber] [tinyint] NULL,
	[WeekdayShort] [varchar](3) NULL,
	[Weekday] [varchar](10) NULL,
	[CalendarWeek] [tinyint] NULL
CONSTRAINT [PK_DimDate] PRIMARY KEY CLUSTERED
(
	[DateId] ASC
)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]