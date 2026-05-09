package swd_engine

Object :: struct {
	age:                              Age,
	kind:                             Object_Kind,
	cost:                             Object_Base_Cost,
	coins_produced:                   int,
	coins_per_object_produced:        Object_Kind_Count,
	resources_produced:               Resource_Count,
	variable_brown_resource_produced: int,
	variable_grey_resource_produced:  int,
	fixed_cost_resource_produced:     Resources,
	military_produced:                int,
	vp_produced:                      int,
	linking_symbol_produced:          Linking_Symbol,
	science_symbol_produced:          Science_Symbol,
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
Object_Name :: enum {
	Lumber_Yard = 1,
	Logging_Camp,
	Clay_Pool,
	Clay_Pit,
	Quarry,
	Stone_Pit,
	Glassworks,
	Press,
	Guard_Tower,
	Workshop,
	Apothecary,
	Stone_Reserve,
	Clay_Reserve,
	Wood_Reserve,
	Stable,
	Garrison,
	Palisade,
	Scriptorium,
	Pharmacist,
	Theatre,
	Altar,
	Baths,
	Tavern,
	Sawmill,
	Brickyard,
	Shelf_Quarry,
	Glassblower,
	Drying_Room,
	Walls,
	Forum,
	Caravansery,
	Customs_House,
	Courthouse,
	Horse_Breeders,
	Barracks,
	Archery_Range,
	Parade_Ground,
	Library,
	Dispensary,
	School,
	Laboratory,
	Statue,
	Temple,
	Aqueduct,
	Rostrum,
	Brewery,
	Arsenal,
	Pretorium,
	Academy,
	Study,
	Chamber_of_Commerce,
	Port,
	Armory,
	Palace,
	Town_Hall,
	Obelisk,
	Circus,
	University,
	Observatory,
	Gardens,
	Pantheon,
	Senate,
	Lighthouse,
	Arena,
	Merchants_Guild,
	Shipowners_Guild,
	Builders_Guild,
	Magistrates_Guild,
	Scientists_Guild,
	Moneylenders_Guild,
	Tacticians_Guild,
	Fortifications,
	Siege_Workshop,
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
	.Lumber_Yard = {age = .Age1, kind = .Brown, resources_produced = #partial{.Wood = 1}},
	.Logging_Camp = {
		age = .Age1,
		kind = .Brown,
		cost = {coins = 1},
		resources_produced = #partial{.Wood = 1},
	},
	.Clay_Pool = {age = .Age1, kind = .Brown, resources_produced = #partial{.Clay = 1}},
	.Clay_Pit = {
		age = .Age1,
		kind = .Brown,
		cost = {coins = 1},
		resources_produced = #partial{.Clay = 1},
	},
	.Quarry = {kind = .Brown, resources_produced = #partial{.Stone = 1}, age = .Age1},
	.Stone_Pit = {
		age = .Age1,
		kind = .Brown,
		cost = {coins = 1},
		resources_produced = #partial{.Stone = 1},
	},
	.Glassworks = {
		age = .Age1,
		kind = .Grey,
		cost = {coins = 1},
		resources_produced = #partial{.Glass = 1},
	},
	.Press = {
		age = .Age1,
		kind = .Grey,
		cost = {coins = 1},
		resources_produced = #partial{.Papyrus = 1},
	},
	.Guard_Tower = {age = .Age1, kind = .Red, military_produced = 1},
	.Workshop = {
		age = .Age1,
		kind = .Green,
		cost = {resources = #partial{.Papyrus = 1}},
		science_symbol_produced = .Frame,
		vp_produced = 1,
	},
	.Apothecary = {
		age = .Age1,
		kind = .Green,
		cost = {resources = #partial{.Glass = 1}},
		science_symbol_produced = .Wheel,
		vp_produced = 1,
	},
	.Stone_Reserve = {
		age = .Age1,
		kind = .Yellow,
		cost = {coins = 3},
		fixed_cost_resource_produced = {.Stone},
	},
	.Clay_Reserve = {
		age = .Age1,
		kind = .Yellow,
		cost = {coins = 3},
		fixed_cost_resource_produced = {.Clay},
	},
	.Wood_Reserve = {
		age = .Age1,
		kind = .Yellow,
		cost = {coins = 3},
		fixed_cost_resource_produced = {.Wood},
	},
	.Stable = {
		age = .Age1,
		kind = .Red,
		cost = {resources = #partial{.Wood = 1}},
		military_produced = 1,
		linking_symbol_produced = .Stable,
	},
	.Garrison = {
		age = .Age1,
		kind = .Red,
		cost = {resources = #partial{.Clay = 1}},
		military_produced = 1,
		linking_symbol_produced = .Garrison,
	},
	.Palisade = {
		age = .Age1,
		kind = .Red,
		cost = {coins = 2},
		military_produced = 1,
		linking_symbol_produced = .Palisade,
	},
	.Scriptorium = {
		age = .Age1,
		kind = .Green,
		cost = {coins = 2},
		science_symbol_produced = .Quill,
		linking_symbol_produced = .Scriptorium,
	},
	.Pharmacist = {
		age = .Age1,
		kind = .Green,
		cost = {coins = 2},
		science_symbol_produced = .Mortar_And_Pestle,
		linking_symbol_produced = .Pharmacist,
	},
	.Theatre = {age = .Age1, kind = .Blue, vp_produced = 3, linking_symbol_produced = .Theatre},
	.Altar = {age = .Age1, kind = .Blue, vp_produced = 3, linking_symbol_produced = .Altar},
	.Baths = {
		age = .Age1,
		kind = .Blue,
		cost = {resources = #partial{.Stone = 1}},
		vp_produced = 3,
		linking_symbol_produced = .Baths,
	},
	.Tavern = {age = .Age1, kind = .Yellow, coins_produced = 4, linking_symbol_produced = .Tavern},
	.Sawmill = {
		age = .Age2,
		kind = .Brown,
		cost = {coins = 2},
		resources_produced = #partial{.Wood = 2},
	},
	.Brickyard = {
		age = .Age2,
		kind = .Brown,
		cost = {coins = 2},
		resources_produced = #partial{.Clay = 2},
	},
	.Shelf_Quarry = {
		age = .Age2,
		kind = .Brown,
		cost = {coins = 2},
		resources_produced = #partial{.Stone = 2},
	},
	.Glassblower = {age = .Age2, kind = .Grey, resources_produced = #partial{.Glass = 1}},
	.Drying_Room = {age = .Age2, kind = .Grey, resources_produced = #partial{.Papyrus = 1}},
	.Walls = {
		age = .Age2,
		kind = .Red,
		cost = {resources = #partial{.Stone = 2}},
		military_produced = 2,
	},
	.Forum = {
		age = .Age2,
		kind = .Yellow,
		cost = {coins = 3, resources = #partial{.Clay = 1}},
		variable_grey_resource_produced = 1,
	},
	.Caravansery = {
		age = .Age2,
		kind = .Yellow,
		cost = {coins = 2, resources = #partial{.Glass = 1, .Papyrus = 1}},
		variable_brown_resource_produced = 1,
	},
	.Customs_House = {
		age = .Age2,
		kind = .Yellow,
		cost = {coins = 4},
		fixed_cost_resource_produced = #partial{.Glass, .Papyrus},
	},
	.Courthouse = {
		age = .Age2,
		kind = .Blue,
		cost = {resources = #partial{.Wood = 2, .Glass = 1}},
		vp_produced = 5,
	},
	.Horse_Breeders = {
		age = .Age2,
		kind = .Red,
		cost = {resources = #partial{.Clay = 1, .Wood = 1}, free_construction_symbol = .Stable},
		military_produced = 1,
	},
	.Barracks = {
		age = .Age2,
		kind = .Red,
		cost = {coins = 3, free_construction_symbol = .Garrison},
		military_produced = 1,
	},
	.Archery_Range = {
		age = .Age2,
		kind = .Red,
		cost = {resources = #partial{.Stone = 1, .Wood = 1, .Papyrus = 1}},
		military_produced = 2,
		linking_symbol_produced = .Archery_Range,
	},
	.Parade_Ground = {
		age = .Age2,
		kind = .Red,
		cost = {resources = #partial{.Clay = 2, .Glass = 1}},
		military_produced = 2,
		linking_symbol_produced = .Parade_Ground,
	},
	.Library = {
		age = .Age2,
		kind = .Green,
		cost = {
			resources = #partial{.Stone = 1, .Wood = 1, .Glass = 1},
			free_construction_symbol = .Scriptorium,
		},
		vp_produced = 2,
		science_symbol_produced = .Quill,
	},
	.Dispensary = {
		age = .Age2,
		kind = .Green,
		cost = {
			resources = #partial{.Clay = 2, .Stone = 1},
			free_construction_symbol = .Pharmacist,
		},
		vp_produced = 2,
		science_symbol_produced = .Mortar_And_Pestle,
	},
	.School = {
		age = .Age2,
		kind = .Green,
		cost = {resources = #partial{.Wood = 1, .Papyrus = 2}},
		vp_produced = 1,
		science_symbol_produced = .Wheel,
		linking_symbol_produced = .School,
	},
	.Laboratory = {
		age = .Age2,
		kind = .Green,
		cost = {resources = #partial{.Wood = 1, .Glass = 2}},
		vp_produced = 1,
		science_symbol_produced = .Frame,
		linking_symbol_produced = .Laboratory,
	},
	.Statue = {
		age = .Age2,
		kind = .Blue,
		cost = {resources = #partial{.Clay = 2}, free_construction_symbol = .Theatre},
		vp_produced = 4,
		linking_symbol_produced = .Statue,
	},
	.Temple = {
		age = .Age2,
		kind = .Blue,
		cost = {resources = #partial{.Wood = 1, .Papyrus = 1}, free_construction_symbol = .Altar},
		vp_produced = 4,
		linking_symbol_produced = .Temple,
	},
	.Aqueduct = {
		age = .Age2,
		kind = .Blue,
		cost = {resources = #partial{.Stone = 3}, free_construction_symbol = .Baths},
		vp_produced = 5,
	},
	.Rostrum = {
		age = .Age2,
		kind = .Blue,
		cost = {resources = #partial{.Stone = 1, .Wood = 1}},
		vp_produced = 4,
		linking_symbol_produced = .Rostrum,
	},
	.Brewery = {
		age = .Age2,
		kind = .Yellow,
		coins_produced = 6,
		linking_symbol_produced = .Brewery,
	},
	.Arsenal = {
		age = .Age3,
		kind = .Red,
		cost = {resources = #partial{.Clay = 3, .Wood = 2}},
		military_produced = 3,
	},
	.Pretorium = {age = .Age3, kind = .Red, cost = {coins = 8}, military_produced = 3},
	.Academy = {
		age = .Age3,
		kind = .Green,
		cost = {resources = #partial{.Stone = 1, .Wood = 1, .Glass = 2}},
		vp_produced = 3,
		science_symbol_produced = .Sundial,
	},
	.Study = {
		age = .Age3,
		kind = .Green,
		cost = {resources = #partial{.Wood = 1, .Glass = 1, .Papyrus = 2}},
		vp_produced = 3,
		science_symbol_produced = .Sundial,
	},
	.Chamber_of_Commerce = {
		age = .Age3,
		kind = .Yellow,
		cost = {resources = #partial{.Papyrus = 2}},
		vp_produced = 3,
		coins_per_object_produced = #partial{.Grey = 3},
	},
	.Port = {
		age = .Age3,
		kind = .Yellow,
		cost = {resources = #partial{.Wood = 1, .Glass = 1, .Papyrus = 1}},
		vp_produced = 3,
		coins_per_object_produced = #partial{.Brown = 3},
	},
	.Armory = {
		age = .Age3,
		kind = .Yellow,
		cost = {resources = #partial{.Stone = 2, .Glass = 1}},
		vp_produced = 3,
		coins_per_object_produced = #partial{.Red = 1},
	},
	.Palace = {
		age = .Age3,
		kind = .Blue,
		cost = {resources = #partial{.Clay = 1, .Stone = 1, .Wood = 1, .Glass = 2}},
		vp_produced = 7,
	},
	.Town_Hall = {
		age = .Age3,
		kind = .Blue,
		cost = {resources = #partial{.Stone = 3, .Wood = 2}},
		vp_produced = 7,
	},
	.Obelisk = {
		age = .Age3,
		kind = .Blue,
		cost = {resources = #partial{.Stone = 2, .Glass = 1}},
		vp_produced = 5,
	},
	.Fortifications = {
		age = .Age3,
		kind = .Red,
		cost = {
			resources = #partial{.Stone = 2, .Clay = 1, .Papyrus = 1},
			free_construction_symbol = .Palisade,
		},
		military_produced = 2,
	},
	.Siege_Workshop = {
		age = .Age3,
		kind = .Red,
		cost = {
			resources = #partial{.Wood = 3, .Glass = 1},
			free_construction_symbol = .Archery_Range,
		},
		military_produced = 2,
	},
	.Circus = {
		age = .Age3,
		kind = .Red,
		cost = {
			resources = #partial{.Clay = 2, .Stone = 2},
			free_construction_symbol = .Parade_Ground,
		},
		military_produced = 2,
	},
	.University = {
		age = .Age3,
		kind = .Green,
		cost = {
			resources = #partial{.Clay = 1, .Glass = 1, .Papyrus = 1},
			free_construction_symbol = .School,
		},
		science_symbol_produced = .Astrolabe,
		vp_produced = 2,
	},
	.Observatory = {
		age = .Age3,
		kind = .Green,
		cost = {
			resources = #partial{.Stone = 1, .Papyrus = 2},
			free_construction_symbol = .Laboratory,
		},
		science_symbol_produced = .Astrolabe,
		vp_produced = 2,
	},
	.Gardens = {
		age = .Age3,
		kind = .Blue,
		cost = {resources = #partial{.Clay = 2, .Wood = 2}, free_construction_symbol = .Statue},
		vp_produced = 6,
	},
	.Pantheon = {
		age = .Age3,
		kind = .Blue,
		cost = {
			resources = #partial{.Clay = 1, .Wood = 1, .Papyrus = 2},
			free_construction_symbol = .Temple,
		},
		vp_produced = 6,
	},
	.Senate = {
		age = .Age3,
		kind = .Blue,
		cost = {
			resources = #partial{.Clay = 2, .Stone = 1, .Papyrus = 1},
			free_construction_symbol = .Rostrum,
		},
		vp_produced = 5,
	},
	.Lighthouse = {
		age = .Age3,
		kind = .Yellow,
		cost = {resources = #partial{.Clay = 2, .Glass = 1}, free_construction_symbol = .Tavern},
		coins_per_object_produced = #partial{.Yellow = 1},
		vp_produced = 3,
	},
	.Arena = {
		age = .Age3,
		kind = .Yellow,
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
		kind = .Purple,
		cost = {resources = #partial{.Clay = 1, .Wood = 1, .Glass = 1, .Papyrus = 1}},
	},
	.Shipowners_Guild = {
		guild = .Shipowners_Guild,
		age = .Age3,
		kind = .Purple,
		cost = {resources = #partial{.Clay = 1, .Stone = 1, .Glass = 1, .Papyrus = 1}},
	},
	.Builders_Guild = {
		guild = .Builders_Guild,
		age = .Age3,
		kind = .Purple,
		cost = {resources = #partial{.Stone = 2, .Clay = 1, .Wood = 1, .Glass = 1}},
	},
	.Magistrates_Guild = {
		guild = .Magistrates_Guild,
		age = .Age3,
		kind = .Purple,
		cost = {resources = #partial{.Wood = 2, .Clay = 1, .Papyrus = 1}},
	},
	.Scientists_Guild = {
		guild = .Scientists_Guild,
		age = .Age3,
		kind = .Purple,
		cost = {resources = #partial{.Clay = 2, .Wood = 2}},
	},
	.Moneylenders_Guild = {
		guild = .Moneylenders_Guild,
		age = .Age3,
		kind = .Purple,
		cost = {resources = #partial{.Stone = 2, .Wood = 2}},
	},
	.Tacticians_Guild = {
		guild = .Tacticians_Guild,
		age = .Age3,
		kind = .Purple,
		cost = {resources = #partial{.Stone = 2, .Clay = 1, .Papyrus = 1}},
	},
	.The_Appian_Way = {
		age = .DraftWonders,
		kind = .Wonder,
		cost = {resources = #partial{.Papyrus = 1, .Clay = 2, .Stone = 2}},
		coins_produced = 3,
		coins_destroyed = 3,
		vp_produced = 3,
		go_again = true,
	},
	.The_Great_Lighthouse = {
		age = .DraftWonders,
		kind = .Wonder,
		cost = {resources = #partial{.Papyrus = 2, .Stone = 1, .Wood = 1}},
		variable_brown_resource_produced = 1,
		vp_produced = 4,
	},
	.The_Sphinx = {
		age = .DraftWonders,
		kind = .Wonder,
		cost = {resources = #partial{.Glass = 2, .Clay = 1, .Stone = 1}},
		vp_produced = 6,
		go_again = true,
	},
	.The_Mausoleum = {
		age = .DraftWonders,
		kind = .Wonder,
		cost = {resources = #partial{.Papyrus = 1, .Glass = 2, .Clay = 2}},
		vp_produced = 2,
		revive_card = true,
	},
	.The_Statue_of_Zeus = {
		age = .DraftWonders,
		kind = .Wonder,
		cost = {resources = #partial{.Papyrus = 2, .Clay = 1, .Wood = 1, .Stone = 1}},
		military_produced = 1,
		vp_produced = 3,
		destroy_brown_card = true,
	},
	.Circus_Maximus = {
		age = .DraftWonders,
		kind = .Wonder,
		cost = {resources = #partial{.Glass = 1, .Wood = 1, .Stone = 2}},
		military_produced = 1,
		vp_produced = 3,
		destroy_grey_card = true,
	},
	.Piraeus = {
		age = .DraftWonders,
		kind = .Wonder,
		cost = {resources = #partial{.Clay = 1, .Stone = 1, .Wood = 2}},
		variable_grey_resource_produced = 1,
		vp_produced = 2,
		go_again = true,
	},
	.The_Pyramids = {
		age = .DraftWonders,
		kind = .Wonder,
		cost = {resources = #partial{.Papyrus = 1, .Stone = 3}},
		vp_produced = 9,
	},
	.The_Temple_of_Artemis = {
		age = .DraftWonders,
		kind = .Wonder,
		cost = {resources = #partial{.Papyrus = 1, .Glass = 1, .Stone = 1, .Wood = 1}},
		coins_produced = 9,
		go_again = true,
	},
	.The_Hanging_Gardens = {
		age = .DraftWonders,
		kind = .Wonder,
		cost = {resources = #partial{.Papyrus = 1, .Glass = 1, .Wood = 2}},
		coins_produced = 6,
		vp_produced = 3,
		go_again = true,
	},
	.The_Great_Library = {
		age = .DraftWonders,
		kind = .Wonder,
		cost = {resources = #partial{.Papyrus = 1, .Glass = 1, .Wood = 3}},
		vp_produced = 4,
		gain_unavailable_progress_token = true,
	},
	.The_Colossus = {
		age = .DraftWonders,
		kind = .Wonder,
		cost = {resources = #partial{.Glass = 1, .Clay = 3}},
		military_produced = 2,
		vp_produced = 3,
	},
}

get_all_age1_card_names :: proc() -> [23]Object_Name {
	names: [23]Object_Name
	idx: int = 0
	for card in Object_Name {
		if (idx >= 23) {return names}
		if (objects_db[card].age == .Age1) {
			names[idx] = card
			idx += 1
		}
	}
	return names
}

get_all_age2_card_names :: proc() -> [23]Object_Name {
	names: [23]Object_Name
	idx: int = 0
	for card in Object_Name {
		if (idx >= 23) {return names}
		if (objects_db[card].age == .Age2) {
			names[idx] = card
			idx += 1
		}
	}
	return names
}

get_all_age3_non_guild_card_names :: proc() -> [20]Object_Name {
	names: [20]Object_Name
	idx: int = 0
	for card in Object_Name {
		if (idx >= 20) {return names}
		if (objects_db[card].age == .Age3) {
			names[idx] = card
			idx += 1
		}
	}
	return names
}

get_all_guild_card_names :: proc() -> [7]Object_Name {
	names: [7]Object_Name
	idx: int = 0
	for card in Object_Name {
		if (idx >= 7) {return names}
		if (objects_db[card].kind == .Purple) {
			names[idx] = card
			idx += 1
		}
	}
	return names
}

get_all_wonder_names :: proc() -> [12]Object_Name {
	names: [12]Object_Name
	idx: int = 0
	for card in Object_Name {
		if (idx >= 12) {return names}
		if (objects_db[card].kind == .Wonder) {
			names[idx] = card
			idx += 1
		}
	}
	return names
}
