CREATE PROCEDURE [imp].[InsertSTSJSONData]

@json NVARCHAR(max)

AS
BEGIN

INSERT INTO imp.StSJSONData
(
	 ascension_level
	,boss_relics
	,build_version
	,campfire_choices
	,campfire_rested
	,campfire_upgraded
	,card_choices
	,character_chosen
	,chose_seed
	,circlet_count
	,current_hp_per_floor
	,damage_taken
	,event_choices
	,floor_reached
	,gold
	,gold_per_floor
	,is_ascension_mode
	,is_beta
	,is_daily
	,is_endless
	,is_prod
	,is_trial
	,item_purchase_floors
	,items_purchased
	,items_purged
	,items_purged_floors
	,local_time
	,master_deck
	,max_hp_per_floor
	,neow_bonus
	,neow_cost
	,path_per_floor
	,path_taken
	,play_id
	,player_experience
	,playtime
	,potions_floor_spawned
	,potions_floor_usage
	,potions_obtained
	,purchased_purges
	,relics
	,relics_obtained
	,score
	,seed_played
	,seed_source_timestamp
	,run_timestamp
	,victory
	,win_rate 	
	,inserted_at
)

SELECT
	 ascension_level
	,boss_relics
	,build_version
	,campfire_choices
	,campfire_rested
	,campfire_upgraded
	,card_choices
	,character_chosen
	,chose_seed
	,circlet_count
	,current_hp_per_floor
	,damage_taken
	,event_choices
	,floor_reached
	,gold
	,gold_per_floor
	,is_ascension_mode
	,is_beta
	,is_daily
	,is_endless
	,is_prod
	,is_trial
	,item_purchase_floors
	,items_purchased
	,items_purged
	,items_purged_floors
	,local_time
	,master_deck
	,max_hp_per_floor
	,neow_bonus
	,neow_cost
	,path_per_floor
	,path_taken
	,play_id
	,player_experience
	,playtime
	,potions_floor_spawned
	,potions_floor_usage
	,potions_obtained
	,purchased_purges
	,relics
	,relics_obtained
	,score
	,seed_played
	,seed_source_timestamp
	,run_timestamp
	,victory
	,win_rate
	,getdate()
FROM OPENJSON(@json)
WITH 
(
	ascension_level int '$.ascension_level',
	boss_relics nvarchar(max) as json,
	build_version date '$.build_version',
	campfire_choices nvarchar(max) as json,
	campfire_rested int '$.campfire_rested',
	campfire_upgraded int '$.campfire_upgraded',
	card_choices nvarchar(max) as json,
	character_chosen nvarchar(25) '$.character_chosen',
	chose_seed nvarchar(5) '$.chose_seed',
	circlet_count int '$.circlet_count',
	current_hp_per_floor nvarchar(max) as json,
	damage_taken nvarchar(max) as json,
	event_choices nvarchar(max) as json,
	floor_reached int '$.floor_reached',
	gold int '$.gold',
	gold_per_floor nvarchar(max) as json,
	is_ascension_mode nvarchar(5) '$.is_ascension_mode',
	is_beta nvarchar(5) '$.is_beta',
	is_daily nvarchar(5) '$.is_daily',
	is_endless nvarchar(5) '$.is_endless',
	is_prod nvarchar(5) '$.is_prod',
	is_trial nvarchar(5) '$.is_trial',
	item_purchase_floors nvarchar(max) as json,
	items_purchased nvarchar(max) as json,
	items_purged nvarchar(max) as json,
	items_purged_floors nvarchar(max) as json,
	local_time bigint '$.local_time',
	master_deck nvarchar(max) as json,
	max_hp_per_floor nvarchar(max) as json,
	neow_bonus nvarchar(100) '$.neow_bonus',
	neow_cost nvarchar(100) '$.neow_cost',
	path_per_floor nvarchar(max) as json,
	path_taken nvarchar(max) as json,
	play_id nvarchar(48) '$.play_id',
	player_experience bigint '$.player_experience',
	playtime int '$.playtime',
	potions_floor_spawned nvarchar(max) as json,
	potions_floor_usage nvarchar(max) as json,
	potions_obtained nvarchar(max) as json,
	purchased_purges int '$.purchased_purges',
	relics nvarchar(max) as json,
	relics_obtained nvarchar(max) as json,
	score int '$.score',
	seed_played bigint '$.seed_played',
	seed_source_timestamp bigint '$.seed_source_timestamp',
	run_timestamp bigint '$.timestamp',
	victory nvarchar(5) '$.victory',
	win_rate int '$.win_rate'
) AS jsonValues

END