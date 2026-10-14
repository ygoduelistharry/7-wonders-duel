package swd_engine

Science_Symbol :: enum u8 {
	Astrolabe,
	Scales,
	Sundial,
	Mortar_And_Pestle,
	Frame,
	Quill,
	Wheel,
}

Progress_Token :: enum u16 {
	Agriculture,
	Architecture,
	Economy,
	Law,
	Masonry,
	Mathematics,
	Philosophy,
	Strategy,
	Theology,
	Urbanism,
}
Progress_Tokens :: distinct bit_set[Progress_Token;u16]
@(rodata)
progress_token_description: [Progress_Token]string = {
	.Agriculture  = "Gain 6 coins. Worth 4 VP.",
	.Architecture = "Future Wonders built by you cost 2 fewer resources.",
	.Economy      = "You gain money spent by your opponent when they trade for resources",
	.Law          = "Worth 1 scientific symbol.",
	.Masonry      = "Blue cards built by you cost 2 fewer resources.",
	.Mathematics  = "Worth 3 VP per Progress token at end of game (including itself).",
	.Philosophy   = "Worth 7 VP",
	.Strategy     = "Red cards built by you provide +1 shield.",
	.Theology     = "Future Wonders built by you have 'Play Again'",
	.Urbanism     = "Gain 6 coins. When constructing a building for free via linking symbol, gain 4 coins.",
}

Linking_Symbol :: enum u32 {
	None,
	Stable,
	Garrison,
	Palisade,
	Archery_Range,
	Parade_Ground,
	Scriptorium,
	Pharmacist,
	School,
	Laboratory,
	Theatre,
	Statue,
	Altar,
	Temple,
	Baths,
	Rostrum,
	Tavern,
	Brewery,
}
Linking_Symbols :: distinct bit_set[Linking_Symbol;u32]

Military_Token :: enum u8 {
	P1_2,
	P1_5,
	P2_2,
	P2_5,
}
Military_Tokens :: distinct bit_set[Military_Token;u8]

Object_Colour :: enum u8 {
	Brown,
	Grey,
	Yellow,
	Green,
	Red,
	Blue,
	Purple,
	Wonder,
}

Resource :: enum u8 {
	Clay,
	Stone,
	Wood,
	Glass,
	Papyrus,
}
Resources :: distinct bit_set[Resource;u8]
Resource_Key_Value_Pair :: struct {
	resource: Resource,
	value:    int,
}
@(rodata)
brown_resources: Resources = {.Clay, .Stone, .Wood}
@(rodata)
grey_resources: Resources = {.Glass, .Papyrus}

object_kind_dot_product :: proc(r1, r2: [Object_Colour]int) -> int {
	sum: int
	for object in Object_Colour {
		sum += r1[object] * r2[object]
	}
	return sum
}
resource_dot_product :: proc(r1, r2: [Resource]int) -> (sum: int) {
	for resource in Resource {
		sum += r1[resource] * r2[resource]
	}
	return sum
}
dot :: proc {
	resource_dot_product,
	object_kind_dot_product,
}


Guild :: enum u8 {
	None,
	Builders_Guild,
	Moneylenders_Guild,
	Scientists_Guild,
	Shipowners_Guild,
	Merchants_Guild,
	Magistrates_Guild,
	Tacticians_Guild,
}
Guilds :: distinct bit_set[Guild;u8]


Player_ID :: enum i8 {
	P1 = -1,
	P2 = 1,
}
other_player_id :: proc(player_id: Player_ID) -> Player_ID {return Player_ID(-1 * int(player_id))}

Age :: enum u8 {
	DraftWonders,
	Age1,
	Age2,
	Age3,
}

Choice_State :: enum u16 {
	Game_Over,
	Choose_Wonder_To_Draft,
	Choose_Object_To_Construct_Or_Discard,
	Choose_Progress_Token,
	Choose_Unavailable_Progress_Token,
	Choose_Brown_Card_To_Destroy,
	Choose_Grey_Card_To_Destroy,
	Choose_Card_To_Revive,
	Choose_First_Player,
}

@(rodata)
choice_state_text: [Choice_State]string = {
	.Game_Over                             = "Game over.",
	.Choose_Wonder_To_Draft                = "Choose a wonder to draft.",
	.Choose_Object_To_Construct_Or_Discard = "Choose an object to construct or discard.",
	.Choose_Progress_Token                 = "Choose a progress token.",
	.Choose_Unavailable_Progress_Token     = "Choose a progress token.",
	.Choose_Brown_Card_To_Destroy          = "Choose a Brown card to destroy.",
	.Choose_Grey_Card_To_Destroy           = "Choose a Grey card to destroy.",
	.Choose_Card_To_Revive                 = "Choose a card to revive.",
	.Choose_First_Player                   = "Choose which player goes first.",
}

Move_Kind :: enum {
	None,
	Draft_Wonder,
	Construct_Card,
	Construct_Wonder,
	Discard_For_Coins,
	Select_Progress_Token,
	Select_Card,
	Select_Player,
}

Victory_Type :: enum {
	None,
	Military,
	Science,
	Civilian,
}

Object :: struct {
	age:                              Age,
	colour:                           Object_Colour,
	cost:                             Object_Base_Cost,
	coins_produced:                   int,
	coins_per_object_produced:        [Object_Colour]int,
	resources_produced:               [Resource]int,
	variable_brown_resource_produced: int,
	variable_grey_resource_produced:  int,
	fixed_cost_resource_produced:     Resources,
	military_produced:                int,
	vp_produced:                      int,
	linking_symbol_produced:          Maybe(Linking_Symbol),
	science_symbol_produced:          Maybe(Science_Symbol),
	guild:                            Guild,
	// wonder specific traits
	coins_destroyed:                  int,
	go_again:                         bool,
	destroy_brown_card:               bool,
	destroy_grey_card:                bool,
	revive_card:                      bool,
	gain_unavailable_progress_token:  bool,
}

// need to include The Messe and The Statue of Liberty at some point
// Object_Name enum is sorted by a convenient UI display order
Object_Name :: enum {
	// brown wood
	Lumber_Yard,
	Logging_Camp,
	Sawmill,
	// brown clay
	Clay_Pool,
	Clay_Pit,
	Brickyard,
	// brown stone
	Quarry,
	Stone_Pit,
	Shelf_Quarry,
	// grey glass
	Glassworks,
	Glassblower,
	// grey paper
	Press,
	Drying_Room,
	// yellow discounts
	Stone_Reserve,
	Clay_Reserve,
	Wood_Reserve,
	Forum,
	Caravansery,
	Customs_House,
	// yellow money
	Tavern,
	Brewery,
	// yellow vp
	Chamber_of_Commerce,
	Port,
	Armory,
	Lighthouse,
	Arena,
	// blue
	Theatre,
	Altar,
	Baths,
	Courthouse,
	Statue,
	Temple,
	Aqueduct,
	Rostrum,
	Palace,
	Town_Hall,
	Obelisk,
	Gardens,
	Pantheon,
	Senate,
	// military
	Guard_Tower,
	Stable,
	Garrison,
	Palisade,
	Walls,
	Horse_Breeders,
	Barracks,
	Archery_Range,
	Parade_Ground,
	Arsenal,
	Pretorium,
	Fortifications,
	Siege_Workshop,
	Circus,
	// green frame
	Workshop,
	Laboratory,
	// green wheel
	Apothecary,
	School,
	// green quill
	Scriptorium,
	Library,
	// green mortar and pestle
	Pharmacist,
	Dispensary,
	// green sundial
	Academy,
	Study,
	// green astrolabe
	University,
	Observatory,
	// guilds
	Merchants_Guild,
	Shipowners_Guild,
	Builders_Guild,
	Magistrates_Guild,
	Scientists_Guild,
	Moneylenders_Guild,
	Tacticians_Guild,
	// wonders
	The_Appian_Way,
	The_Great_Lighthouse,
	The_Sphinx,
	The_Mausoleum,
	The_Statue_of_Zeus,
	Circus_Maximus,
	Piraeus,
	The_Pyramids,
	The_Temple_of_Artemis,
	The_Hanging_Gardens,
	The_Great_Library,
	The_Colossus,
}

objects_db: [Object_Name]Object = {
	.Lumber_Yard = {age = .Age1, colour = .Brown, resources_produced = #partial{.Wood = 1}},
	.Logging_Camp = {
		age = .Age1,
		colour = .Brown,
		cost = {coins = 1},
		resources_produced = #partial{.Wood = 1},
	},
	.Clay_Pool = {age = .Age1, colour = .Brown, resources_produced = #partial{.Clay = 1}},
	.Clay_Pit = {
		age = .Age1,
		colour = .Brown,
		cost = {coins = 1},
		resources_produced = #partial{.Clay = 1},
	},
	.Quarry = {colour = .Brown, resources_produced = #partial{.Stone = 1}, age = .Age1},
	.Stone_Pit = {
		age = .Age1,
		colour = .Brown,
		cost = {coins = 1},
		resources_produced = #partial{.Stone = 1},
	},
	.Glassworks = {
		age = .Age1,
		colour = .Grey,
		cost = {coins = 1},
		resources_produced = #partial{.Glass = 1},
	},
	.Press = {
		age = .Age1,
		colour = .Grey,
		cost = {coins = 1},
		resources_produced = #partial{.Papyrus = 1},
	},
	.Guard_Tower = {age = .Age1, colour = .Red, military_produced = 1},
	.Workshop = {
		age = .Age1,
		colour = .Green,
		cost = {resources = #partial{.Papyrus = 1}},
		science_symbol_produced = .Frame,
		vp_produced = 1,
	},
	.Apothecary = {
		age = .Age1,
		colour = .Green,
		cost = {resources = #partial{.Glass = 1}},
		science_symbol_produced = .Wheel,
		vp_produced = 1,
	},
	.Stone_Reserve = {
		age = .Age1,
		colour = .Yellow,
		cost = {coins = 3},
		fixed_cost_resource_produced = {.Stone},
	},
	.Clay_Reserve = {
		age = .Age1,
		colour = .Yellow,
		cost = {coins = 3},
		fixed_cost_resource_produced = {.Clay},
	},
	.Wood_Reserve = {
		age = .Age1,
		colour = .Yellow,
		cost = {coins = 3},
		fixed_cost_resource_produced = {.Wood},
	},
	.Stable = {
		age = .Age1,
		colour = .Red,
		cost = {resources = #partial{.Wood = 1}},
		military_produced = 1,
		linking_symbol_produced = .Stable,
	},
	.Garrison = {
		age = .Age1,
		colour = .Red,
		cost = {resources = #partial{.Clay = 1}},
		military_produced = 1,
		linking_symbol_produced = .Garrison,
	},
	.Palisade = {
		age = .Age1,
		colour = .Red,
		cost = {coins = 2},
		military_produced = 1,
		linking_symbol_produced = .Palisade,
	},
	.Scriptorium = {
		age = .Age1,
		colour = .Green,
		cost = {coins = 2},
		science_symbol_produced = .Quill,
		linking_symbol_produced = .Scriptorium,
	},
	.Pharmacist = {
		age = .Age1,
		colour = .Green,
		cost = {coins = 2},
		science_symbol_produced = .Mortar_And_Pestle,
		linking_symbol_produced = .Pharmacist,
	},
	.Theatre = {age = .Age1, colour = .Blue, vp_produced = 3, linking_symbol_produced = .Theatre},
	.Altar = {age = .Age1, colour = .Blue, vp_produced = 3, linking_symbol_produced = .Altar},
	.Baths = {
		age = .Age1,
		colour = .Blue,
		cost = {resources = #partial{.Stone = 1}},
		vp_produced = 3,
		linking_symbol_produced = .Baths,
	},
	.Tavern = {
		age = .Age1,
		colour = .Yellow,
		coins_produced = 4,
		linking_symbol_produced = .Tavern,
	},
	.Sawmill = {
		age = .Age2,
		colour = .Brown,
		cost = {coins = 2},
		resources_produced = #partial{.Wood = 2},
	},
	.Brickyard = {
		age = .Age2,
		colour = .Brown,
		cost = {coins = 2},
		resources_produced = #partial{.Clay = 2},
	},
	.Shelf_Quarry = {
		age = .Age2,
		colour = .Brown,
		cost = {coins = 2},
		resources_produced = #partial{.Stone = 2},
	},
	.Glassblower = {age = .Age2, colour = .Grey, resources_produced = #partial{.Glass = 1}},
	.Drying_Room = {age = .Age2, colour = .Grey, resources_produced = #partial{.Papyrus = 1}},
	.Walls = {
		age = .Age2,
		colour = .Red,
		cost = {resources = #partial{.Stone = 2}},
		military_produced = 2,
	},
	.Forum = {
		age = .Age2,
		colour = .Yellow,
		cost = {coins = 3, resources = #partial{.Wood = 1, .Clay = 1, .Stone = 1}},
		variable_grey_resource_produced = 1,
	},
	.Caravansery = {
		age = .Age2,
		colour = .Yellow,
		cost = {coins = 2, resources = #partial{.Glass = 1, .Papyrus = 1}},
		variable_brown_resource_produced = 1,
	},
	.Customs_House = {
		age = .Age2,
		colour = .Yellow,
		cost = {coins = 4},
		fixed_cost_resource_produced = #partial{.Glass, .Papyrus},
	},
	.Courthouse = {
		age = .Age2,
		colour = .Blue,
		cost = {resources = #partial{.Wood = 2, .Glass = 1}},
		vp_produced = 5,
	},
	.Horse_Breeders = {
		age = .Age2,
		colour = .Red,
		cost = {resources = #partial{.Clay = 1, .Wood = 1}, free_construction_symbol = .Stable},
		military_produced = 1,
	},
	.Barracks = {
		age = .Age2,
		colour = .Red,
		cost = {coins = 3, free_construction_symbol = .Garrison},
		military_produced = 1,
	},
	.Archery_Range = {
		age = .Age2,
		colour = .Red,
		cost = {resources = #partial{.Stone = 1, .Wood = 1, .Papyrus = 1}},
		military_produced = 2,
		linking_symbol_produced = .Archery_Range,
	},
	.Parade_Ground = {
		age = .Age2,
		colour = .Red,
		cost = {resources = #partial{.Clay = 2, .Glass = 1}},
		military_produced = 2,
		linking_symbol_produced = .Parade_Ground,
	},
	.Library = {
		age = .Age2,
		colour = .Green,
		cost = {
			resources = #partial{.Stone = 1, .Wood = 1, .Glass = 1},
			free_construction_symbol = .Scriptorium,
		},
		vp_produced = 2,
		science_symbol_produced = .Quill,
	},
	.Dispensary = {
		age = .Age2,
		colour = .Green,
		cost = {
			resources = #partial{.Clay = 2, .Stone = 1},
			free_construction_symbol = .Pharmacist,
		},
		vp_produced = 2,
		science_symbol_produced = .Mortar_And_Pestle,
	},
	.School = {
		age = .Age2,
		colour = .Green,
		cost = {resources = #partial{.Wood = 1, .Papyrus = 2}},
		vp_produced = 1,
		science_symbol_produced = .Wheel,
		linking_symbol_produced = .School,
	},
	.Laboratory = {
		age = .Age2,
		colour = .Green,
		cost = {resources = #partial{.Wood = 1, .Glass = 2}},
		vp_produced = 1,
		science_symbol_produced = .Frame,
		linking_symbol_produced = .Laboratory,
	},
	.Statue = {
		age = .Age2,
		colour = .Blue,
		cost = {resources = #partial{.Clay = 2}, free_construction_symbol = .Theatre},
		vp_produced = 4,
		linking_symbol_produced = .Statue,
	},
	.Temple = {
		age = .Age2,
		colour = .Blue,
		cost = {resources = #partial{.Wood = 1, .Papyrus = 1}, free_construction_symbol = .Altar},
		vp_produced = 4,
		linking_symbol_produced = .Temple,
	},
	.Aqueduct = {
		age = .Age2,
		colour = .Blue,
		cost = {resources = #partial{.Stone = 3}, free_construction_symbol = .Baths},
		vp_produced = 5,
	},
	.Rostrum = {
		age = .Age2,
		colour = .Blue,
		cost = {resources = #partial{.Stone = 1, .Wood = 1}},
		vp_produced = 4,
		linking_symbol_produced = .Rostrum,
	},
	.Brewery = {
		age = .Age2,
		colour = .Yellow,
		coins_produced = 6,
		linking_symbol_produced = .Brewery,
	},
	.Arsenal = {
		age = .Age3,
		colour = .Red,
		cost = {resources = #partial{.Clay = 3, .Wood = 2}},
		military_produced = 3,
	},
	.Pretorium = {age = .Age3, colour = .Red, cost = {coins = 8}, military_produced = 3},
	.Academy = {
		age = .Age3,
		colour = .Green,
		cost = {resources = #partial{.Stone = 1, .Wood = 1, .Glass = 2}},
		vp_produced = 3,
		science_symbol_produced = .Sundial,
	},
	.Study = {
		age = .Age3,
		colour = .Green,
		cost = {resources = #partial{.Wood = 1, .Glass = 1, .Papyrus = 2}},
		vp_produced = 3,
		science_symbol_produced = .Sundial,
	},
	.Chamber_of_Commerce = {
		age = .Age3,
		colour = .Yellow,
		cost = {resources = #partial{.Papyrus = 2}},
		vp_produced = 3,
		coins_per_object_produced = #partial{.Grey = 3},
	},
	.Port = {
		age = .Age3,
		colour = .Yellow,
		cost = {resources = #partial{.Wood = 1, .Glass = 1, .Papyrus = 1}},
		vp_produced = 3,
		coins_per_object_produced = #partial{.Brown = 3},
	},
	.Armory = {
		age = .Age3,
		colour = .Yellow,
		cost = {resources = #partial{.Stone = 2, .Glass = 1}},
		vp_produced = 3,
		coins_per_object_produced = #partial{.Red = 1},
	},
	.Palace = {
		age = .Age3,
		colour = .Blue,
		cost = {resources = #partial{.Clay = 1, .Stone = 1, .Wood = 1, .Glass = 2}},
		vp_produced = 7,
	},
	.Town_Hall = {
		age = .Age3,
		colour = .Blue,
		cost = {resources = #partial{.Stone = 3, .Wood = 2}},
		vp_produced = 7,
	},
	.Obelisk = {
		age = .Age3,
		colour = .Blue,
		cost = {resources = #partial{.Stone = 2, .Glass = 1}},
		vp_produced = 5,
	},
	.Fortifications = {
		age = .Age3,
		colour = .Red,
		cost = {
			resources = #partial{.Stone = 2, .Clay = 1, .Papyrus = 1},
			free_construction_symbol = .Palisade,
		},
		military_produced = 2,
	},
	.Siege_Workshop = {
		age = .Age3,
		colour = .Red,
		cost = {
			resources = #partial{.Wood = 3, .Glass = 1},
			free_construction_symbol = .Archery_Range,
		},
		military_produced = 2,
	},
	.Circus = {
		age = .Age3,
		colour = .Red,
		cost = {
			resources = #partial{.Clay = 2, .Stone = 2},
			free_construction_symbol = .Parade_Ground,
		},
		military_produced = 2,
	},
	.University = {
		age = .Age3,
		colour = .Green,
		cost = {
			resources = #partial{.Clay = 1, .Glass = 1, .Papyrus = 1},
			free_construction_symbol = .School,
		},
		science_symbol_produced = .Astrolabe,
		vp_produced = 2,
	},
	.Observatory = {
		age = .Age3,
		colour = .Green,
		cost = {
			resources = #partial{.Stone = 1, .Papyrus = 2},
			free_construction_symbol = .Laboratory,
		},
		science_symbol_produced = .Astrolabe,
		vp_produced = 2,
	},
	.Gardens = {
		age = .Age3,
		colour = .Blue,
		cost = {resources = #partial{.Clay = 2, .Wood = 2}, free_construction_symbol = .Statue},
		vp_produced = 6,
	},
	.Pantheon = {
		age = .Age3,
		colour = .Blue,
		cost = {
			resources = #partial{.Clay = 1, .Wood = 1, .Papyrus = 2},
			free_construction_symbol = .Temple,
		},
		vp_produced = 6,
	},
	.Senate = {
		age = .Age3,
		colour = .Blue,
		cost = {
			resources = #partial{.Clay = 2, .Stone = 1, .Papyrus = 1},
			free_construction_symbol = .Rostrum,
		},
		vp_produced = 5,
	},
	.Lighthouse = {
		age = .Age3,
		colour = .Yellow,
		cost = {resources = #partial{.Clay = 2, .Glass = 1}, free_construction_symbol = .Tavern},
		coins_per_object_produced = #partial{.Yellow = 1},
		vp_produced = 3,
	},
	.Arena = {
		age = .Age3,
		colour = .Yellow,
		cost = {
			resources = #partial{.Clay = 1, .Stone = 1, .Wood = 1},
			free_construction_symbol = .Brewery,
		},
		coins_per_object_produced = #partial{.Wonder = 2},
		vp_produced = 3,
	},
	.Merchants_Guild = {
		guild = .Merchants_Guild,
		age = .Age3,
		colour = .Purple,
		cost = {resources = #partial{.Clay = 1, .Wood = 1, .Glass = 1, .Papyrus = 1}},
	},
	.Shipowners_Guild = {
		guild = .Shipowners_Guild,
		age = .Age3,
		colour = .Purple,
		cost = {resources = #partial{.Clay = 1, .Stone = 1, .Glass = 1, .Papyrus = 1}},
	},
	.Builders_Guild = {
		guild = .Builders_Guild,
		age = .Age3,
		colour = .Purple,
		cost = {resources = #partial{.Stone = 2, .Clay = 1, .Wood = 1, .Glass = 1}},
	},
	.Magistrates_Guild = {
		guild = .Magistrates_Guild,
		age = .Age3,
		colour = .Purple,
		cost = {resources = #partial{.Wood = 2, .Clay = 1, .Papyrus = 1}},
	},
	.Scientists_Guild = {
		guild = .Scientists_Guild,
		age = .Age3,
		colour = .Purple,
		cost = {resources = #partial{.Clay = 2, .Wood = 2}},
	},
	.Moneylenders_Guild = {
		guild = .Moneylenders_Guild,
		age = .Age3,
		colour = .Purple,
		cost = {resources = #partial{.Stone = 2, .Wood = 2}},
	},
	.Tacticians_Guild = {
		guild = .Tacticians_Guild,
		age = .Age3,
		colour = .Purple,
		cost = {resources = #partial{.Stone = 2, .Clay = 1, .Papyrus = 1}},
	},
	.The_Appian_Way = {
		age = .DraftWonders,
		colour = .Wonder,
		cost = {resources = #partial{.Papyrus = 1, .Clay = 2, .Stone = 2}},
		coins_produced = 3,
		coins_destroyed = 3,
		vp_produced = 3,
		go_again = true,
	},
	.The_Great_Lighthouse = {
		age = .DraftWonders,
		colour = .Wonder,
		cost = {resources = #partial{.Papyrus = 2, .Stone = 1, .Wood = 1}},
		variable_brown_resource_produced = 1,
		vp_produced = 4,
	},
	.The_Sphinx = {
		age = .DraftWonders,
		colour = .Wonder,
		cost = {resources = #partial{.Glass = 2, .Clay = 1, .Stone = 1}},
		vp_produced = 6,
		go_again = true,
	},
	.The_Mausoleum = {
		age = .DraftWonders,
		colour = .Wonder,
		cost = {resources = #partial{.Papyrus = 1, .Glass = 2, .Clay = 2}},
		vp_produced = 2,
		revive_card = true,
	},
	.The_Statue_of_Zeus = {
		age = .DraftWonders,
		colour = .Wonder,
		cost = {resources = #partial{.Papyrus = 2, .Clay = 1, .Wood = 1, .Stone = 1}},
		military_produced = 1,
		vp_produced = 3,
		destroy_brown_card = true,
	},
	.Circus_Maximus = {
		age = .DraftWonders,
		colour = .Wonder,
		cost = {resources = #partial{.Glass = 1, .Wood = 1, .Stone = 2}},
		military_produced = 1,
		vp_produced = 3,
		destroy_grey_card = true,
	},
	.Piraeus = {
		age = .DraftWonders,
		colour = .Wonder,
		cost = {resources = #partial{.Clay = 1, .Stone = 1, .Wood = 2}},
		variable_grey_resource_produced = 1,
		vp_produced = 2,
		go_again = true,
	},
	.The_Pyramids = {
		age = .DraftWonders,
		colour = .Wonder,
		cost = {resources = #partial{.Papyrus = 1, .Stone = 3}},
		vp_produced = 9,
	},
	.The_Temple_of_Artemis = {
		age = .DraftWonders,
		colour = .Wonder,
		cost = {resources = #partial{.Papyrus = 1, .Glass = 1, .Stone = 1, .Wood = 1}},
		coins_produced = 9,
		go_again = true,
	},
	.The_Hanging_Gardens = {
		age = .DraftWonders,
		colour = .Wonder,
		cost = {resources = #partial{.Papyrus = 1, .Glass = 1, .Wood = 2}},
		coins_produced = 6,
		vp_produced = 3,
		go_again = true,
	},
	.The_Great_Library = {
		age = .DraftWonders,
		colour = .Wonder,
		cost = {resources = #partial{.Papyrus = 1, .Glass = 1, .Wood = 3}},
		vp_produced = 4,
		gain_unavailable_progress_token = true,
	},
	.The_Colossus = {
		age = .DraftWonders,
		colour = .Wonder,
		cost = {resources = #partial{.Glass = 1, .Clay = 3}},
		military_produced = 2,
		vp_produced = 3,
	},
}

game_object_is_card :: proc(game_object: Object_Name) -> bool {
	if objects_db[game_object].colour == .Wonder {return false} else {return true}
}

game_object_is_wonder :: proc(game_object: Object_Name) -> bool {
	if objects_db[game_object].colour == .Wonder {return true} else {return false}
}

get_all_age1_card_names :: proc() -> [23]Object_Name {
	names: [23]Object_Name
	count: int = 0
	for card in Object_Name {
		if (count >= 23) {return names}
		if (objects_db[card].age == .Age1) {
			names[count] = card
			count += 1
		}
	}
	return names
}

get_all_age2_card_names :: proc() -> [23]Object_Name {
	names: [23]Object_Name
	count: int = 0
	for card in Object_Name {
		if (count >= 23) {return names}
		if (objects_db[card].age == .Age2) {
			names[count] = card
			count += 1
		}
	}
	return names
}

get_all_age3_non_guild_card_names :: proc() -> [20]Object_Name {
	names: [20]Object_Name
	count: int = 0
	for card in Object_Name {
		if (count >= 20) {return names}
		if (objects_db[card].age == .Age3 && objects_db[card].colour != .Purple) {
			names[count] = card
			count += 1
		}
	}
	return names
}

get_all_guild_card_names :: proc() -> [7]Object_Name {
	names: [7]Object_Name
	count: int = 0
	for card in Object_Name {
		if (count >= 7) {return names}
		if (objects_db[card].colour == .Purple) {
			names[count] = card
			count += 1
		}
	}
	return names
}

get_all_wonder_names :: proc() -> [12]Object_Name {
	names: [12]Object_Name
	count: int = 0
	for card in Object_Name {
		if (count >= 12) {return names}
		if (objects_db[card].colour == .Wonder) {
			names[count] = card
			count += 1
		}
	}
	return names
}


Board_Slot :: struct {
	age:              Age,
	id:               int,
	face_up:          bool,
	selectable:       bool,
	covers:           [dynamic; 4]int,
	covered_by_count: int,
	card_in_slot:     Maybe(Object_Name),
}

Board :: [20]Board_Slot

default_age_boards: [Age]Board = #partial {
	.Age1 = {
		{age = .Age1, id = 0, face_up = true, selectable = true, covers = {6}},
		{age = .Age1, id = 1, face_up = true, selectable = true, covers = {6, 7}},
		{age = .Age1, id = 2, face_up = true, selectable = true, covers = {7, 8}},
		{age = .Age1, id = 3, face_up = true, selectable = true, covers = {8, 9}},
		{age = .Age1, id = 4, face_up = true, selectable = true, covers = {9, 10}},
		{age = .Age1, id = 5, face_up = true, selectable = true, covers = {10}},
		{age = .Age1, id = 6, covers = {11}, covered_by_count = 2},
		{age = .Age1, id = 7, covers = {11, 12}, covered_by_count = 2},
		{age = .Age1, id = 8, covers = {12, 13}, covered_by_count = 2},
		{age = .Age1, id = 9, covers = {13, 14}, covered_by_count = 2},
		{age = .Age1, id = 10, covers = {14}, covered_by_count = 2},
		{age = .Age1, id = 11, face_up = true, covers = {15}, covered_by_count = 2},
		{age = .Age1, id = 12, face_up = true, covers = {15, 16}, covered_by_count = 2},
		{age = .Age1, id = 13, face_up = true, covers = {16, 17}, covered_by_count = 2},
		{age = .Age1, id = 14, face_up = true, covers = {17}, covered_by_count = 2},
		{age = .Age1, id = 15, covers = {18}, covered_by_count = 2},
		{age = .Age1, id = 16, covers = {18, 19}, covered_by_count = 2},
		{age = .Age1, id = 17, covers = {19}, covered_by_count = 2},
		{age = .Age1, id = 18, face_up = true, covered_by_count = 2},
		{age = .Age1, id = 19, face_up = true, covered_by_count = 2},
	},
	.Age2 = {
		{age = .Age2, id = 0, face_up = true, selectable = true, covers = {2, 3}},
		{age = .Age2, id = 1, face_up = true, selectable = true, covers = {3, 4}},
		{age = .Age2, id = 2, covers = {5, 6}, covered_by_count = 1},
		{age = .Age2, id = 3, covers = {6, 7}, covered_by_count = 2},
		{age = .Age2, id = 4, covers = {7, 8}, covered_by_count = 1},
		{age = .Age2, id = 5, face_up = true, covers = {9, 10}, covered_by_count = 1},
		{age = .Age2, id = 6, face_up = true, covers = {10, 11}, covered_by_count = 2},
		{age = .Age2, id = 7, face_up = true, covers = {11, 12}, covered_by_count = 2},
		{age = .Age2, id = 8, face_up = true, covers = {12, 13}, covered_by_count = 1},
		{age = .Age2, id = 9, covers = {14, 15}, covered_by_count = 1},
		{age = .Age2, id = 10, covers = {15, 16}, covered_by_count = 2},
		{age = .Age2, id = 11, covers = {16, 17}, covered_by_count = 2},
		{age = .Age2, id = 12, covers = {17, 18}, covered_by_count = 2},
		{age = .Age2, id = 13, covers = {18, 19}, covered_by_count = 1},
		{age = .Age2, id = 14, face_up = true, covered_by_count = 1},
		{age = .Age2, id = 15, face_up = true, covered_by_count = 2},
		{age = .Age2, id = 16, face_up = true, covered_by_count = 2},
		{age = .Age2, id = 17, face_up = true, covered_by_count = 2},
		{age = .Age2, id = 18, face_up = true, covered_by_count = 2},
		{age = .Age2, id = 19, face_up = true, covered_by_count = 1},
	},
	.Age3 = {
		{age = .Age3, id = 0, face_up = true, selectable = true, covers = {2, 3}},
		{age = .Age3, id = 1, face_up = true, selectable = true, covers = {3, 4}},
		{age = .Age3, id = 2, covers = {5, 6}, covered_by_count = 1},
		{age = .Age3, id = 3, covers = {6, 7}, covered_by_count = 2},
		{age = .Age3, id = 4, covers = {7, 8}, covered_by_count = 1},
		{age = .Age3, id = 5, face_up = true, covers = {9}, covered_by_count = 1},
		{age = .Age3, id = 6, face_up = true, covers = {9}, covered_by_count = 2},
		{age = .Age3, id = 7, face_up = true, covers = {10}, covered_by_count = 2},
		{age = .Age3, id = 8, face_up = true, covers = {10}, covered_by_count = 1},
		{age = .Age3, id = 9, covers = {11, 12}, covered_by_count = 2},
		{age = .Age3, id = 10, covers = {13, 14}, covered_by_count = 2},
		{age = .Age3, id = 11, face_up = true, covers = {15}, covered_by_count = 1},
		{age = .Age3, id = 12, face_up = true, covers = {15, 16}, covered_by_count = 1},
		{age = .Age3, id = 13, face_up = true, covers = {16, 17}, covered_by_count = 1},
		{age = .Age3, id = 14, face_up = true, covers = {17}, covered_by_count = 1},
		{age = .Age3, id = 15, covers = {18}, covered_by_count = 2},
		{age = .Age3, id = 16, covers = {18, 19}, covered_by_count = 2},
		{age = .Age3, id = 17, covers = {19}, covered_by_count = 2},
		{age = .Age3, id = 18, face_up = true, covered_by_count = 2},
		{age = .Age3, id = 19, face_up = true, covered_by_count = 2},
	},
}

