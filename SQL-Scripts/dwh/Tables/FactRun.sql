create table dwh.FactRun
(
	-- ids
	PlayId nvarchar(36) not null, -- "play_id": "8f3a5379-95b2-4ade-b8c3-acae861e50a4",
	BuildId int null, -- "build_version": "2018-08-02",
	AscensionId int null, -- "ascension_level": 15,
	CharacterId int null, -- "character_chosen": "IRONCLAD",	
	StartingBonusId int null, -- "neow_bonus": "UPGRADE_CARD", "neow_cost": "NONE",
	-- measures
	FloorReachedId int null, -- "floor_reached": 51,
	KilledById int null, -- "killed_by": "3 Darklings",
	CampfireRests int null, -- "campfire_rested": 3,
	CampfireUpgrades int null, -- "campfire_upgraded": 6,
	PurchasedPurges int null, -- "purchased_purges": 0,
	FinalGold int null, -- "gold": 130,
	PlayerExperience bigint null, -- "player_experience": 758607,
	Score int null, -- "score": 1317,
	PlayTimeSeconds int null, -- "playtime": 2936,	
	WinRate float null, -- "win_rate": 0
	CircletCount int null, -- "circlet_count": 0,
	-- timestamps
	LocalTime datetime null, -- "local_time": "20180803170448",
	SeedGeneratedTimeStamp datetime null, -- "seed_source_timestamp": 692510983248,
	CreatedAt datetime null, -- "timestamp": 1533308688,
	-- other
	SeedPlayed bigint null, -- "seed_played": "7425912388502425920",	
	-- additional data
	VictoryId tinyint null, -- "victory": true,
	MasterDeck nvarchar(max) null, -- "master_deck": ["Strike_R", "Strike_R", "Strike_R", "Strike_R", "Strike_R", "Defend_R", "Defend_R", "Defend_R", "Defend_R", "Bash+1", "AscendersBane", "Heavy Blade+1", "Clothesline+1", "True Grit+1", "Immolate+1", "Battle Trance", "Headbutt", "Shrug It Off", "Iron Wave", "Inflame+1", "Offering", "Shrug It Off", "Necronomicurse", "Armaments+1", "Combust+1", "Shrug It Off", "Spot Weakness", "Barricade", "Disarm+1", "Feel No Pain", "Armaments+1", "Doubt", "Metallicize", "Shrug It Off"],
	Relics nvarchar(max) null, -- "relics": ["Burning Blood", "Orichalcum", "Potion Belt", "Nunchaku", "Paper Frog", "Snecko Eye", "Pantograph", "Necronomicon", "Pear", "Centennial Puzzle", "Cursed Key", "Red Mask", "Singing Bowl", "Lantern", "Omamori"],
	ChoseSeed bit null, -- "chose_seed": false,
	IsAscensionMode bit null, -- "is_ascension_mode": true,
	IsBeta bit null, -- "is_beta": false,
	IsDaily bit null, -- "is_daily": false,
	IsEndless bit null, -- "is_endless": false,
	IsProd bit null, -- "is_prod": false,
	IsTrial bit null, -- "is_trial": false,	
	ETLInsertedAt datetime null,
	ETLUpdatedAt datetime null,
	ETLUser nvarchar(50) null
)	
