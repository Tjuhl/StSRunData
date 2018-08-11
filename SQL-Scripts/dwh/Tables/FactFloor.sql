create table dwh.FactFloor
(
	FloorId int not null, -- 0 to 51
	PlayId nvarchar(32) null, -- "play_id": "821b51eb-5b50-4a99-85da-9c96b2358515",
	CharacterId int null, -- "character_chosen": "DEFECT",
	CardId int null, -- "card_choices": [{"floor": 1,"not_picked": ["Pommel Strike", "Reckless Charge"],"picked": "Heavy Blade"}, "items_purchased": ["Clothesline", "Strength Potion", "Pantograph", "Energy Potion"],
	PathId int null, -- "path_per_floor": ["M", "?", "$", "M", "M", "R", "E", "R", "T", "M", "E", "M", "M", "E", "R", "B", null, "M", "$", "?", "?", "$", "R", "M", "M", "T", "?", "$", "E", "R", "M", "R", "B", null, "M", "?", "M", "$", "M", "R", "E", "R", "T", "M", "M", "E", "M", "M", "R", "B"],
	RelicId int null, -- "relics_obtained": [{"floor": 7,"key": "Orichalcum"}
	EncounterId int null, -- "enemies": "Jaw Worm",
	PotionObtainedId int null, -- "potions_obtained": [{"floor": 5,"key": "Regen Potion"}
	CampfireChoiceId int null,
	VictoryId tinyint null,
	CurrentHealth int null, -- "current_hp_per_floor": [68, 68, 68, 74, 75, 75, 69, 69, 69, 68, 56, 56, 62, 61, 61, 39, 66, 67, 67, 46, 46, 46, 46, 47, 35, 45, 45, 45, 26, 51, 57, 57, 31, 72, 66, 66, 53, 53, 40, 65, 58, 58, 58, 56, 33, 32, 25, 28, 55, 29],
	MaxHealth int null,
	CurrentGold int null, -- "gold_per_floor": [114, 114, 15, 32, 49, 49, 80, 80, 106, 119, 154, 169, 186, 216, 216, 294, 294, 310, 11, 11, 11, 11, 11, 22, 42, 42, 42, 42, 77, 77, 93, 93, 171, 171, 189, 0, 17, 17, 35, 35, 63, 63, 63, 73, 85, 110, 120, 130, 130, 130],
	PotionSpawnedTF bit null, -- "potions_floor_spawned": [5, 10, 12, 13, 24, 25, 31, 37, 41, 44, 45],
	PotionUsedTF bit null, -- "potions_floor_usage": [7, 11, 13, 16, 16, 25, 33, 35, 41, 46, 46, 46],
	PotionObtainedTF bit null, -- "potions_obtained": [{"floor": 5,"key": "Regen Potion"}
	ItemPurgedTF bit null, -- "items_purged": [], "items_purged_floors": [],
	DamageTaken int null, -- "damage_taken": [{			"damage": 0,			"enemies": "Jaw Worm",			"floor": 1,			"turns": 3		}
	EncounterTurnsTaken int null, -- "damage_taken": [{			"damage": 0,			"enemies": "Jaw Worm",			"floor": 1,			"turns": 3
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
)