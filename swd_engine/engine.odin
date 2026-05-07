package swd_engine

import linalg "core:math/linalg"
import "core:math/rand"
import "core:slice"
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
	Urbanism,
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
	P2_5,
}
Military_Tokens :: distinct bit_set[Military_Token;u8]

Object_Kind :: enum u8 {
	Brown,
	Grey,
	Yellow,
	Green,
	Red,
	Blue,
	Purple,
	Wonder,
}
Object_Kind_Count :: [Object_Kind]int

Resource :: enum u8 {
	Clay,
	Stone,
	Wood,
	Glass,
	Papyrus,
}
Resources :: distinct bit_set[Resource;u8]
Resource_Count :: [Resource]int
Resource_Key_Value_Pair :: struct {
	resource: Resource,
	value:    int,
}
brown_resources: Resources = {.Clay, .Stone, .Wood}
grey_resources: Resources = {.Glass, .Papyrus}


Object_Base_Cost :: struct {
	coins:                    int,
	resources:                Resource_Count,
	free_construction_symbol: Linking_Symbol,
}

Player_State :: struct {
	objects_constructed:                [dynamic; 34]Game_Object_Name,
	wonders_available:                  [dynamic; 4]Game_Object_Name,
	object_kind_count_owned:            Object_Kind_Count,
	coins:                              int,
	resource_production:                Resource_Count,
	resource_trade_price:               Resource_Count,
	variable_brown_resource_production: int,
	variable_grey_resource_production:  int,
	progress_tokens:                    Progress_Tokens,
	science_symbols:                    Science_Symbol_Count,
	linking_symbols:                    Linking_Symbols,
	fixed_vp:                           int,
	coin_per_vp:                        int,
	vp_per_object_kind:                 Object_Kind_Count,
	vp_per_progress_token:              int,
}

Player_ID :: enum i8 {
	P1 = -1,
	P2 = 1,
}

Age :: enum u8 {
	Draft,
	Age1,
	Age2,
	Age3,
}

Choice_State :: enum {
	Construct_Or_Discard,
	Choose_Card_To_Discard,
	Choose_Card_To_Tuck_Under_Wonder,
	Choose_Progress_Token,
	Choose_Unavailable_Progress_Token,
	Choose_Brown_Card_To_Destroy,
	Choose_Grey_Card_To_Destroy,
	Choose_Card_To_Revive,
}

Game :: struct {
	boards:                      [Age]Board,
	player_states:               #sparse[Player_ID]Player_State,
	cards_discarded:             [dynamic; 60]Game_Object_Name,
	cards_unavailable:           [dynamic; 13]Game_Object_Name,
	wonders_available:           [8]Game_Object_Name,
	rng_state:                   rand.Default_Random_State,
	rng_seed:                    u64,
	age:                         Age,
	turn:                        int,
	turn_player:                 Player_ID,
	choice_state:                Choice_State,
	go_again_active:             bool,
	military_track:              int, //negative means p1 leading
	military_tokens_available:   Military_Tokens,
	progress_tokens_available:   Progress_Tokens,
	progress_tokens_unavailable: Progress_Tokens,
}

Object_Real_Cost :: struct {
	total_coin_cost:     int,
	traded_coin_cost:    int,
	linking_symbol_used: bool,
}

game_object_cost_for_player :: proc(
	object_name: Game_Object_Name,
	player_id: Player_ID,
	game: ^Game,
) -> Object_Real_Cost {

	object := game_objects_db[object_name]
	player := &game.player_states[player_id]
	opponent := &game.player_states[Player_ID(-1 * int(player_id))]

	// check for free linking symbol
	if object.cost.free_construction_symbol in player.linking_symbols {
		return {linking_symbol_used = true}
	}

	building_coin_cost := object.cost.coins

	// check how many of each resource we need to trade for after using up "fixed" resource production.
	// this is effectively just brown and grey buildings
	// we also split the resource deficit into brown and grey to account for "varaible" resource production.
	extra_brown_res_required, extra_grey_res_required: int
	extra_res_required: Resource_Count
	for &value, resource in extra_res_required {
		value = max(0, object.cost.resources[resource] - player.resource_production[resource])
		if resource in brown_resources {extra_brown_res_required += value}
		if resource in grey_resources {extra_grey_res_required += value}
	}

	variable_brown_res_available := player.variable_brown_resource_production
	variable_grey_res_available := player.variable_grey_resource_production

	extra_brown_res_required = max(0, extra_brown_res_required - variable_brown_res_available)
	extra_grey_res_required = max(0, extra_grey_res_required - variable_grey_res_available)

	// do an early check for masonry and architecture
	total_extra_res_required := extra_brown_res_required + extra_grey_res_required
	if (object.kind == .Blue && .Masonry in player.progress_tokens) ||
	   (object.kind == .Wonder && .Architechture in player.progress_tokens) {
		total_extra_res_required -= 2
	}
	// if we can cover our production without considering trading then we are done. if not...
	if total_extra_res_required <= 0 {return {building_coin_cost, 0, false}}


	// if we have no varaible resource production, no need to sort.
	if variable_brown_res_available + variable_grey_res_available <= 0 {
		traded_coin_cost := linalg.vector_dot(player.resource_trade_price, extra_res_required)
		return {building_coin_cost + traded_coin_cost, traded_coin_cost, false}
	}
	// if we do, we need to know what the best way to spend "variable" resource production is
	resource_costs: [5]Resource_Key_Value_Pair = {
		{.Clay, player.resource_trade_price[.Clay]},
		{.Stone, player.resource_trade_price[.Stone]},
		{.Wood, player.resource_trade_price[.Wood]},
		{.Glass, player.resource_trade_price[.Glass]},
		{.Papyrus, player.resource_trade_price[.Papyrus]},
	}
	// sort resources from most to least expensive
	slice.sort_by(
		resource_costs[:],
		proc(i, j: Resource_Key_Value_Pair) -> bool {return i.value > j.value},
	)

	//iterate over the resource costs and decrement our avaialbe varaible resources until they are gone
	for kvp in resource_costs {
		if kvp.resource in brown_resources {
			for extra_res_required[kvp.resource] > 0 || variable_brown_res_available > 0 {
				extra_res_required[kvp.resource] -= 1
				variable_brown_res_available -= 1
			}
		}
		if kvp.resource in grey_resources {
			for extra_res_required[kvp.resource] > 0 || variable_grey_res_available > 0 {
				extra_res_required[kvp.resource] -= 1
				variable_grey_res_available -= 1
			}
		}
	}
	traded_coin_cost := linalg.vector_dot(player.resource_trade_price, extra_res_required)
	return {building_coin_cost + traded_coin_cost, traded_coin_cost, false}
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

	new_game.military_tokens_available = {.P1_2, .P1_5, .P2_2, .P2_5}

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

	new_game.player_states = {
		.P1 = {
			coins = 7,
			resource_trade_price = {.Wood = 2, .Clay = 2, .Stone = 2, .Glass = 2, .Papyrus = 2},
		},
		.P2 = {
			coins = 7,
			resource_trade_price = {.Wood = 2, .Clay = 2, .Stone = 2, .Glass = 2, .Papyrus = 2},
		},
	}

	return new_game
}

construct_game_object :: proc(object_name: Game_Object_Name, player_id: Player_ID, game: ^Game) {
	object := game_objects_db[object_name]
	player := &game.player_states[player_id]
	opponent := &game.player_states[Player_ID(-1 * int(player_id))]

	append(&player.objects_constructed, object_name)
	player.object_kind_count_owned[object.kind] += 1

	coin_gain := linalg.vector_dot(
		object.coins_per_object_produced,
		player.object_kind_count_owned,
	)
	coin_gain += object.coins_produced
	if .Urbanism in player.progress_tokens &&
	   object.cost.free_construction_symbol in player.linking_symbols {
		coin_gain += 4
	}
	player.coins += coin_gain

	player.resource_production += object.resources_produced
	if object.kind == .Brown || object.kind == .Grey {
		for &value, resource in opponent.resource_trade_price {
			if value != 1 {
				value += object.resources_produced[resource]
			}
		}
	}

	if object.fixed_cost_resource_produced != {} {
		for &value, resource in player.resource_trade_price {
			if resource in object.fixed_cost_resource_produced {value = 1}
		}
	}
	player.variable_brown_resource_production += object.variable_brown_resource_produced
	player.variable_grey_resource_production += object.variable_grey_resource_produced

	player.fixed_vp += object.vp_produced

	player.vp_per_object_kind += object.vp_per_object_kind
	player.coin_per_vp += object.coin_per_vp

	player.linking_symbols |= {object.linking_symbol_produced}
	opponent.coins -= object.coins_destroyed

	if object.kind == .Red {
		game.military_track += int(player_id) * object.military_produced
		if .Strategy in player.progress_tokens {
			game.military_track += int(player_id)
		}
	}

	if game.military_track <= -3 && .P1_2 in game.military_tokens_available {opponent.coins -= 2}
	if game.military_track <= -6 && .P1_5 in game.military_tokens_available {opponent.coins -= 5}
	if game.military_track >= 3 && .P1_2 in game.military_tokens_available {opponent.coins -= 2}
	if game.military_track >= 6 && .P1_5 in game.military_tokens_available {opponent.coins -= 5}

	if object.go_again || (.Theology in player.progress_tokens && object.kind == .Wonder) {
		game.go_again_active = true
	}

	// Check for Science
	player.science_symbols[object.science_symbol_produced] += 1
	if player.science_symbols[object.science_symbol_produced] == 2 {
		game.choice_state = .Choose_Progress_Token
	}

	// Wonder specific effects
	if object.gain_unavailable_progress_token {game.choice_state = .Choose_Unavailable_Progress_Token}
	if object.destroy_brown_card {game.choice_state = .Choose_Brown_Card_To_Destroy}
	if object.destroy_grey_card {game.choice_state = .Choose_Grey_Card_To_Destroy}
	if object.revive_card {game.choice_state = .Choose_Card_To_Revive}
}


gain_progress_token :: proc(token: Progress_Token, player_id: Player_ID, game: ^Game) {
	player := &game.player_states[player_id]
	player.progress_tokens |= {token}
	switch token {
	case .Agriculture:
		{
			player.fixed_vp += 4
			player.coins += 6
		}
	case .Architechture:
		{}
	case .Economy:
		{}
	case .Law:
		{player.science_symbols[.Scales] += 1}
	case .Masonry:
		{}
	case .Mathematics:
		{player.vp_per_progress_token += 3}
	case .Philosophy:
		{player.fixed_vp += 7}
	case .Strategy:
		{}
	case .Theology:
		{}
	case .Urbanism:
		{player.coins += 6}
	}
}
