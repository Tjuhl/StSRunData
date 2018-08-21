create table dwh.DimCard -- "card_choices": [{"floor": 1,"not_picked": ["Pommel Strike", "Reckless Charge"],"picked": "Heavy Blade"}]
(
	CardId int identity(1,1) not null,
	CardName nvarchar(255) null, 
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
    CONSTRAINT [PK_DimCard] PRIMARY KEY ([CardId])
)
