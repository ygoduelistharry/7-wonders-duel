package swd_engine

import "core:math/rand"
import "core:time"

Science_Symbol :: enum u8 {
	None,
	Astrolabe,
	Scales,
	Sundial,
	Mortar_And_Pestle,
	Frame,
	Quill,
	Wheel,
}
Science_Symbol_Count :: [Science_Symbol]int

Progress_Token :: enum u16 {
	Agriculture,
	Architechture,
	Economy,
	Law,
	Masonry,
	Mathematics,
	Philosophy,
	Strategy,
	Theology,
	Urbanismm,
}
Progress_Tokens :: distinct bit_set[Progress_Token;u16]

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
	P2_4,
}
Military_Tokens :: distinct bit_set[Military_Token;u8]

Object_Type :: enum u8 {
	Brown,
	Grey,
	Yellow,
	Green,
	Red,
	Blue,
	Purple,
	Wonder,
}
Object_Type_Count :: [Object_Type]int

Resource :: enum u8 {
	Clay,
	Stone,
	Wood,
	Glass,
	Papyrus,
}
Resources :: distinct bit_set[Resource;u8]
Resource_Count :: [Resource]int
Coins :: distinct int

Cost :: struct {
	coins:                    Coins,
	resource_count:           Resource_Count,
	free_construction_symbol: Linking_Symbol,
}

Player_State :: struct {
	coins:                     Coins,
	resource_production:       Resource_Count,
	brown_resource_production: int,
	grey_resource_production:  int,
	fixed_cost_resources:      Resources,
	object_types_owned:        Object_Type_Count,
	progress_tokens:           Progress_Tokens,
	science_symbols:           Science_Symbol_Count,
	linking_symbols:           Linking_Symbols,
	fixed_vp:                  int,
	vp_per_object_type:        Object_Type_Count,
	wonders_available:         [dynamic; 4]Game_Object_Name,
	objects_built_by_type:     [Object_Type][dynamic; 16]Game_Object_Name,
}

Player_ID :: enum u8 {
	P1,
	P2,
}

Age :: enum u8 {
	Draft,
	Age1,
	Age2,
	Age3,
}

Game :: struct {
	rng_seed:                    u64,
	rng_state:                   rand.Default_Random_State,
	turn:                        int,
	turn_player:                 Player_ID,
	age:                         Age,
	boards:                      [Age]Board,
	wonders_available:           [8]Game_Object_Name,
	cards_unavailable:           [dynamic; 13]Game_Object_Name,
	p1:                          Player_State,
	p2:                          Player_State,
	military_track:              int, //negative means p1 leading
	military_tokens_available:   Military_Tokens,
	progress_tokens_available:   Progress_Tokens,
	progress_tokens_unavailable: Progress_Tokens,
}

game_create_new :: proc(rng_seed: i64 = -1) -> Game {
	new_game: Game = {}

	if rng_seed < 0 {
		new_game.rng_seed = u64(time.now()._nsec)} else {
		new_game.rng_seed = u64(rng_seed)
	}
	new_game.rng_state = rand.create_u64(new_game.rng_seed)

	rng := rand.default_random_generator(&new_game.rng_state)

	new_game.turn_player = rand.choice_enum(Player_ID, rng)

	new_game.age = .Draft

	wonders := get_all_wonder_names()
	rand.shuffle(wonders[:], rng)
	for wonder, idx in wonders {
		if idx < 8 {new_game.wonders_available[idx] = wonder} else {break}
	}

	new_game.boards = default_age_boards

	age1_cards := get_all_age1_card_names()
	age2_cards := get_all_age2_card_names()
	age3_non_guild_cards := get_all_age3_non_guild_card_names()
	guild_cards := get_all_guild_card_names()
	rand.shuffle(age1_cards[:], rng)
	rand.shuffle(age2_cards[:], rng)
	rand.shuffle(age3_non_guild_cards[:], rng)
	rand.shuffle(guild_cards[:], rng)
	for card, idx in age1_cards {
		if idx < 20 {new_game.boards[.Age1][idx].game_object_in_slot = card} else {
			append(&new_game.cards_unavailable, card)
		}
	}
	for card, idx in age2_cards {
		if idx < 20 {new_game.boards[.Age2][idx].game_object_in_slot = card} else {
			append(&new_game.cards_unavailable, card)
		}
	}
	for card, idx in age3_non_guild_cards {
		if idx < 17 {new_game.boards[.Age3][idx].game_object_in_slot = card} else {
			append(&new_game.cards_unavailable, card)
		}
	}
	for card, idx in guild_cards {
		if idx < 3 {new_game.boards[.Age3][idx + 17].game_object_in_slot = card} else {
			append(&new_game.cards_unavailable, card)
		}
	}

	new_game.military_tokens_available = {.P1_2, .P1_5, .P2_2, .P2_4}

	progress_tokens: [len(Progress_Token)]Progress_Token
	for token, idx in Progress_Token {
		progress_tokens[idx] = token
	}
	rand.shuffle(progress_tokens[:], rng)
	for token, idx in progress_tokens {
		if idx < 5 {
			new_game.progress_tokens_available |= {token}
		} else {
			new_game.progress_tokens_unavailable |= {token}
		}
	}

	new_game.p1 = {
		coins = 7,
	}
	new_game.p2 = {
		coins = 7,
	}

	return new_game
}
