package swd_engine

import "core:math/bits"
// import linalg "core:math/linalg"
import "core:math/rand"
import "core:slice"
import "core:time"

Science_Symbol :: enum u8 {
	Astrolabe = 1,
	Scales,
	Sundial,
	Mortar_And_Pestle,
	Frame,
	Quill,
	Wheel,
}
Science_Symbol_Count :: [Science_Symbol]int

Progress_Token :: enum u16 {
	Agriculture = 1,
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
	Stable = 1,
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
	P1_2 = 1,
	P1_5,
	P2_2,
	P2_5,
}
Military_Tokens :: distinct bit_set[Military_Token;u8]

Object_Kind :: enum u8 {
	Brown = 1,
	Grey,
	Yellow,
	Green,
	Red,
	Blue,
	Purple,
	Wonder,
}
Object_Kind_Count :: [Object_Kind]int
object_kind_dot_product :: proc(r1, r2: Object_Kind_Count) -> int {
	sum: int
	for object in Object_Kind {
		sum += r1[object] * r2[object]
	}
	return sum
}

Guild :: enum u8 {
	Builders_Guild = 1,
	Moneylenders_Guild,
	Scientists_Guild,
	Shipowners_Guild,
	Merchants_Guild,
	Magistrates_Guild,
	Tacticians_Guild,
}
Guilds :: distinct bit_set[Guild;u8]

Resource :: enum u8 {
	Clay = 1,
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
resource_dot_product :: proc(r1, r2: Resource_Count) -> (sum: int) {
	for resource in Resource {
		sum += r1[resource] * r2[resource]
	}
	return sum
}

dot :: proc {
	resource_dot_product,
	object_kind_dot_product,
}


Object_Base_Cost :: struct {
	coins:                    int,
	resources:                Resource_Count,
	free_construction_symbol: Linking_Symbol,
}

Player_State :: struct {
	cards_constructed:                  [dynamic; 30]Object_Name,
	wonders_constructed:                [dynamic; 4]Object_Name,
	cards_tucked:                       [dynamic; 4]Object_Name,
	wonders_available:                  [dynamic; 4]Object_Name,
	object_kind_count_owned:            Object_Kind_Count,
	player_id:                          Player_ID,
	coins:                              int,
	resource_production:                Resource_Count,
	resource_trade_price:               Resource_Count,
	variable_brown_resource_production: int,
	variable_grey_resource_production:  int,
	progress_tokens:                    Progress_Tokens,
	science_symbols:                    Science_Symbol_Count,
	unique_science_symbols:             int,
	linking_symbols:                    Linking_Symbols,
	fixed_vp_from_blue:                 int,
	fixed_vp_from_other:                int,
	guilds_built:                       Guilds,
}

Player_ID :: enum i8 {
	P1 = -1,
	P2 = 1,
}
other_player_id :: proc(player_id: Player_ID) -> Player_ID {return Player_ID(-1 * int(player_id))}

Age :: enum u8 {
	DraftWonders = 1,
	Age1,
	Age2,
	Age3,
}

Choice_State :: enum u16 {
	Choose_Wonder_To_Draft,
	Choose_Object_To_Construct_Or_Discard,
	Choose_Progress_Token,
	Choose_Unavailable_Progress_Token,
	Choose_Brown_Card_To_Destroy,
	Choose_Grey_Card_To_Destroy,
	Choose_Card_To_Revive,
	Choose_First_Player,
}

Game :: struct {
	boards:                      [Age]Board,
	player_states:               #sparse[Player_ID]Player_State,
	move_history:                [dynamic; 256]Move,
	cards_discarded:             [dynamic; 64]Object_Name,
	cards_unavailable:           [dynamic; 16]Object_Name,
	wonders_to_draft:            [8]Object_Name,
	wonder_ids_draftable:        bit_set[0 ..= 7;u8],
	rng_state:                   rand.Default_Random_State,
	rng_seed:                    u64,
	age:                         Age,
	objects_left_in_age:         int,
	turn_player:                 Player_ID,
	choice_state:                Choice_State,
	next_choice_state:           Choice_State,
	go_again_active:             bool,
	military_track:              int, //negative means p1 leading
	military_tokens_available:   Military_Tokens,
	progress_tokens_available:   Progress_Tokens,
	progress_tokens_unavailable: [dynamic; 10]Progress_Token,
	end_of_age_triggered:        bool,
	completed:                   bool,
	winner:                      Player_ID,
}
create_new_game :: proc(rng_seed: i64 = -1) -> (new_game: Game) {
	if rng_seed < 0 {
		new_game.rng_seed = u64(time.now()._nsec)} else {
		new_game.rng_seed = u64(rng_seed)
	}
	new_game.rng_state = rand.create_u64(new_game.rng_seed)

	rng := rand.default_random_generator(&new_game.rng_state)

	new_game.turn_player = rand.choice_enum(Player_ID, rng)

	new_game.age = .DraftWonders
	new_game.objects_left_in_age = 8

	wonders := get_all_wonder_names()
	rand.shuffle(wonders[:], rng)
	copy(new_game.wonders_to_draft[:], wonders[:8])
	new_game.wonder_ids_draftable = {0, 1, 2, 3}

	new_game.boards = default_age_boards

	age1_cards := get_all_age1_card_names()
	age2_cards := get_all_age2_card_names()
	age3_non_guild_cards := get_all_age3_non_guild_card_names()
	guild_cards := get_all_guild_card_names()
	rand.shuffle(age1_cards[:], rng)
	rand.shuffle(age2_cards[:], rng)
	rand.shuffle(age3_non_guild_cards[:], rng)
	rand.shuffle(guild_cards[:], rng)

	for card, idx in age1_cards[:20] {new_game.boards[.Age1][idx].card_in_slot = card}
	append(&new_game.cards_unavailable, ..age1_cards[20:])

	for card, idx in age2_cards[:20] {new_game.boards[.Age2][idx].card_in_slot = card}
	append(&new_game.cards_unavailable, ..age2_cards[20:])

	all_selected_age3_cards: [20]Object_Name
	copy(all_selected_age3_cards[:17], age3_non_guild_cards[:17])
	append(&new_game.cards_unavailable, ..age3_non_guild_cards[17:])
	copy(all_selected_age3_cards[17:], guild_cards[:3])
	append(&new_game.cards_unavailable, ..guild_cards[3:])

	rand.shuffle(all_selected_age3_cards[:])
	for card, idx in all_selected_age3_cards {new_game.boards[.Age3][idx].card_in_slot = card}


	new_game.military_tokens_available = {.P1_2, .P1_5, .P2_2, .P2_5}


	progress_tokens: [len(Progress_Token)]Progress_Token
	for token, idx in Progress_Token {
		progress_tokens[idx] = token
	}
	rand.shuffle(progress_tokens[:], rng)
	for token, idx in progress_tokens {
		if idx < 5 {
			new_game.progress_tokens_available += {token}
		} else {
			append(&new_game.progress_tokens_unavailable, token)
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

change_turn_player :: proc(game: ^Game) {
	game.turn_player = Player_ID(-1 * int(game.turn_player))
}

Object_Real_Cost :: struct {
	total_coin_cost:     int,
	traded_coin_cost:    int,
	linking_symbol_used: bool,
}
calculate_object_cost :: proc(
	object_name: Object_Name,
	player_id: Player_ID,
	game: Game,
) -> Object_Real_Cost {

	object := objects_db[object_name]
	player := game.player_states[player_id]
	opponent := game.player_states[Player_ID(-1 * int(player_id))]

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
		traded_coin_cost := dot(player.resource_trade_price, extra_res_required)
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
	traded_coin_cost := dot(player.resource_trade_price, extra_res_required)
	return {building_coin_cost + traded_coin_cost, traded_coin_cost, false}
}


Draft_Wonder :: struct {
	wonder_name: Object_Name,
	wonder_idx:  int,
}
Construct_Card :: struct {
	card_name: Object_Name,
	slot_idx:  int,
	cost:      Object_Real_Cost,
}
Construct_Wonder :: struct {
	wonder_name: Object_Name,
	wonder_idx:  int,
	cost:        Object_Real_Cost,
	card_name:   Object_Name,
	slot_idx:    int,
}
Discard_For_Coins :: struct {
	card_name: Object_Name,
	slot_idx:  int,
}
Select_Progress_Token :: struct {
	token:     Progress_Token,
	token_idx: int,
}
Select_Card :: struct {
	card_name: Object_Name,
	card_idx:  int,
}
Select_Player :: struct {
	chosen_player: Player_ID,
}

Move_Data :: union {
	Draft_Wonder,
	Construct_Card,
	Construct_Wonder,
	Discard_For_Coins,
	Select_Progress_Token,
	Select_Card,
	Select_Player,
}

Move :: struct {
	move_data:     Move_Data,
	choice_state:  Choice_State,
	acting_player: Player_ID,
}

get_valid_moves :: proc(game: Game) -> (valid_moves: [dynamic; 64]Move) {
	if game.completed {return {}}
	turn_player_id := game.turn_player
	opponent_id := Player_ID(-1 * int(turn_player_id))
	turn_player := game.player_states[turn_player_id]
	opponent := game.player_states[opponent_id]

	switch game.choice_state {
	case .Choose_Wonder_To_Draft:
		{
			for idx in game.wonder_ids_draftable {
				wonder := game.wonders_to_draft[idx]
				append(&valid_moves, Move{move_data = Draft_Wonder{wonder, idx}})
			}
		}
	case .Choose_Object_To_Construct_Or_Discard:
		{
			// get all constructable wonders if 7 haven't been built yet
			constructable_wonder_data: [dynamic; 4]Construct_Wonder
			if len(turn_player.wonders_constructed) + len(opponent.wonders_constructed) < 7 {
				for wonder, idx in turn_player.wonders_available {
					wonder_cost := calculate_object_cost(wonder, turn_player_id, game)
					if wonder_cost.total_coin_cost <= turn_player.coins {
						append(
							&constructable_wonder_data,
							Construct_Wonder {
								wonder_name = wonder,
								wonder_idx = idx,
								cost = wonder_cost,
							},
						)
					}
				}
			}

			// iterate over cards on the board
			for slot in game.boards[game.age] {
				if slot.selectable {
					// add moves to discard for coins
					append(
						&valid_moves,
						Move{move_data = Discard_For_Coins{slot.card_in_slot, slot.id}},
					)
					// add moves to construct wonders
					for data in constructable_wonder_data {
						wonder_data: Construct_Wonder = {
							wonder_name = data.wonder_name,
							wonder_idx  = data.wonder_idx,
							cost        = data.cost,
							card_name   = slot.card_in_slot,
							slot_idx    = slot.id,
						}
						append(&valid_moves, Move{move_data = wonder_data})
					}
					// add moves to construct cards
					card_cost := calculate_object_cost(slot.card_in_slot, turn_player_id, game)
					if card_cost.total_coin_cost <= turn_player.coins {
						append(
							&valid_moves,
							Move {
								move_data = Construct_Card{slot.card_in_slot, slot.id, card_cost},
							},
						)
					}
				}
			}
		}
	case .Choose_Progress_Token:
		{
			for token in Progress_Token {
				if token in game.progress_tokens_available {
					append(
						&valid_moves,
						Move{move_data = Select_Progress_Token{token, int(token)}},
					)
				}
			}
		}
	case .Choose_Unavailable_Progress_Token:
		{
			for token, idx in game.progress_tokens_unavailable {
				append(&valid_moves, Move{move_data = Select_Progress_Token{token, idx}})
				if idx >= 3 {break}
			}
		}
	case .Choose_Brown_Card_To_Destroy:
		{
			for card, idx in opponent.cards_constructed {
				if objects_db[card].kind == .Brown {
					append(&valid_moves, Move{move_data = Select_Card{card, idx}})
				}
			}
		}
	case .Choose_Grey_Card_To_Destroy:
		{
			for card, idx in opponent.cards_constructed {
				if objects_db[card].kind == .Grey {
					append(&valid_moves, Move{move_data = Select_Card{card, idx}})
				}
			}
		}
	case .Choose_Card_To_Revive:
		{
			for card, idx in game.cards_discarded {
				append(&valid_moves, Move{move_data = Select_Card{card, idx}})
			}
		}
	case .Choose_First_Player:
		{
			append(&valid_moves, Move{move_data = Select_Player{turn_player_id}})
			append(&valid_moves, Move{move_data = Select_Player{opponent_id}})
		}
	}

	for &move in valid_moves {
		move.choice_state = game.choice_state
		move.acting_player = turn_player_id
	}
	return valid_moves
}

get_guild_value :: proc(guild: Guild, player_id: Player_ID, game: Game) -> (vp: int, coin: int) {
	player := game.player_states[player_id]
	opponent := game.player_states[other_player_id(player_id)]
	player_obj_count := player.object_kind_count_owned
	opponent_obj_count := opponent.object_kind_count_owned
	switch guild {
	case .Builders_Guild:
		{
			count := max(len(player.wonders_constructed), len(opponent.wonders_constructed))
			vp = 2 * count
		}
	case .Moneylenders_Guild:
		{
			count := max(player.coins, opponent.coins)
			vp = count / 3
		}
	case .Scientists_Guild:
		{
			count := max(player_obj_count[.Green], opponent_obj_count[.Green])
			vp = count
			coin = count
		}
	case .Merchants_Guild:
		{
			count := max(player_obj_count[.Yellow], opponent_obj_count[.Yellow])
			vp = count
			coin = count
		}
	case .Magistrates_Guild:
		{
			count := max(player_obj_count[.Blue], opponent_obj_count[.Blue])
			vp = count
			coin = count

		}
	case .Tacticians_Guild:
		{
			count := max(player_obj_count[.Red], opponent_obj_count[.Red])
			vp = count
			coin = count

		}
	case .Shipowners_Guild:
		{
			count := max(
				player_obj_count[.Grey] + player_obj_count[.Brown],
				opponent_obj_count[.Grey] + opponent_obj_count[.Brown],
			)
			vp = count
			coin = count
		}
	}
	return vp, coin
}


// Constructs an object and performs all immediate deterministic actions possible, for example;
// coin gain/loss, sets choice state to visit next, resolves military track tokens, etc.
construct_object :: proc(object_name: Object_Name, player_id: Player_ID, game: ^Game) {
	object := objects_db[object_name]
	player := &game.player_states[player_id]
	opponent := &game.player_states[Player_ID(-1 * int(player_id))]

	if object.kind == .Wonder {
		append(&player.wonders_constructed, object_name)

	} else {
		append(&player.cards_constructed, object_name)
	}
	player.object_kind_count_owned[object.kind] += 1

	coin_gain :=
		object.coins_produced +
		dot(object.coins_per_object_produced, player.object_kind_count_owned)
	if .Urbanism in player.progress_tokens &&
	   object.cost.free_construction_symbol in player.linking_symbols {
		coin_gain += 4
	}
	if object.kind == .Purple {
		_, coin_from_guild := get_guild_value(object.guild, player_id, game^)
		coin_gain += coin_from_guild
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

	for &value, resource in player.resource_trade_price {
		if resource in object.fixed_cost_resource_produced {value = 1}
	}

	player.variable_brown_resource_production += object.variable_brown_resource_produced
	player.variable_grey_resource_production += object.variable_grey_resource_produced

	if object.kind == .Blue {
		player.fixed_vp_from_blue += object.vp_produced
	} else {
		player.fixed_vp_from_other += object.vp_produced
	}

	player.linking_symbols |= {object.linking_symbol_produced}

	if object.kind == .Red {
		game.military_track += int(player_id) * object.military_produced
		if .Strategy in player.progress_tokens {
			game.military_track += int(player_id)
		}
	}

	// destroy opponent coins
	coin_loss := object.coins_destroyed
	if game.military_track <= -3 && .P1_2 in game.military_tokens_available {coin_loss += 2}
	if game.military_track <= -6 && .P1_5 in game.military_tokens_available {coin_loss += 5}
	if game.military_track >= 3 && .P1_2 in game.military_tokens_available {coin_loss += 2}
	if game.military_track >= 6 && .P1_5 in game.military_tokens_available {coin_loss += 5}
	opponent.coins = max(0, opponent.coins - coin_loss)

	// check for military victory
	if game.military_track <= -9 {
		game.completed = true
		game.winner = .P1
		return
	}
	if game.military_track >= 9 {
		game.completed = true
		game.winner = .P2
		return
	}


	// Check for science events
	player.science_symbols[object.science_symbol_produced] += 1
	if player.science_symbols[object.science_symbol_produced] == 1 {
		player.unique_science_symbols += 1
		if player.unique_science_symbols >= 6 {
			game.completed = true
			game.winner = player_id
			return
		}
	}
	if player.science_symbols[object.science_symbol_produced] == 2 {
		game.next_choice_state = .Choose_Progress_Token
	}

	// Wonder specific effects
	if object.go_again || (.Theology in player.progress_tokens && object.kind == .Wonder) {
		game.go_again_active = true
	}
	if object.gain_unavailable_progress_token {game.next_choice_state = .Choose_Unavailable_Progress_Token}
	if object.destroy_brown_card {game.next_choice_state = .Choose_Brown_Card_To_Destroy}
	if object.destroy_grey_card {game.next_choice_state = .Choose_Grey_Card_To_Destroy}
	if object.revive_card {game.next_choice_state = .Choose_Card_To_Revive}
}

// Returns the card removed from the slot (will be .None if slot was empty)
remove_card_from_board :: proc(slot: ^Board_Slot, game: ^Game) -> (card_removed: Object_Name) {
	board: ^Board = &game.boards[slot.age]
	card_removed = slot.card_in_slot
	if card_removed != {} {
		slot.card_in_slot = {}
		game.objects_left_in_age -= 1
		slot.selectable = false
		for covered_id in slot.covers {
			board[covered_id].covered_by_count -= 1
			if board[covered_id].covered_by_count <= 0 {
				board[covered_id].selectable = true
				board[covered_id].visible = true
			}
		}
	}
	if game.objects_left_in_age <= 0 {game.end_of_age_triggered = true}
	return card_removed
}

gain_progress_token :: proc(token: Progress_Token, player_id: Player_ID, game: ^Game) {
	player := &game.player_states[player_id]
	player.progress_tokens |= {token}
	switch token {
	case .Agriculture:
		{
			player.fixed_vp_from_other += 4
			player.coins += 6
		}
	case .Architechture:
		{}
	case .Economy:
		{}
	case .Law:
		{player.science_symbols[.Scales] += 1
			player.unique_science_symbols += 1
			if player.unique_science_symbols >= 6 {
				game.completed = true
				game.winner = player_id
			}
		}
	case .Masonry:
		{}
	case .Mathematics:
		{}
	case .Philosophy:
		{player.fixed_vp_from_other += 7}
	case .Strategy:
		{}
	case .Theology:
		{}
	case .Urbanism:
		{player.coins += 6}
	}
}

calculate_victory_points :: proc(player_id: Player_ID, game: Game) -> (vp: int, blue_vp: int) {
	player := game.player_states[player_id]
	opponent := game.player_states[other_player_id(player_id)]

	blue_vp = player.fixed_vp_from_blue
	vp += blue_vp + player.fixed_vp_from_other + player.coins / 3

	player_military_score := int(player_id) * game.military_track
	switch player_military_score {
	case 1 ..= 2:
		{vp += 2}
	case 3 ..= 5:
		{vp += 5}
	case 6 ..= 8:
		{vp += 10}
	}

	if .Mathematics in player.progress_tokens {
		vp += int(bits.count_ones(transmute(u16)player.progress_tokens))
	}

	player_obj_count := player.object_kind_count_owned
	opponent_obj_count := opponent.object_kind_count_owned
	for guild in player.guilds_built {
		vp_gain, _ := get_guild_value(guild, player_id, game)
		vp += vp_gain
	}
	return vp, blue_vp
}


// Executes a move and progresses the game state --
// Note! This function doesn't check if the move is valid first!
// Make sure 'move' is selected from array generated by get_valid_moves() procedure!
execute_move_unsafe :: proc(move: Move, game: ^Game) {
	board := &game.boards[game.age]
	player := &game.player_states[move.acting_player]
	opponent := &game.player_states[Player_ID(-1 * int(move.acting_player))]

	// the most common next state is constructing an object or discarding for coins.
	// the switch statement will set the next state differently if appropriate.
	// the Move struct stores the choice_state when the move was made if it's needed
	game.next_choice_state = .Choose_Object_To_Construct_Or_Discard

	switch move_data in move.move_data {
	case Draft_Wonder:
		{
			append(&player.wonders_available, move_data.wonder_name)
			game.wonder_ids_draftable -= {move_data.wonder_idx}
			// we do a snake draft, so players double pick when there are 6 and 2 wonders left
			wonders_left := &game.objects_left_in_age
			wonders_left^ -= 1
			if wonders_left^ != 6 || wonders_left^ != 2 {
				change_turn_player(game)
			}
			// reveal the next 4 wonders to draft if necessary
			if wonders_left^ == 4 {
				game.wonder_ids_draftable += {4, 5, 6, 7}
			}
			if game.objects_left_in_age <= 0 {
				game.end_of_age_triggered = true
			} else {
				game.next_choice_state = .Choose_Wonder_To_Draft
			}
		}
	case Construct_Card:
		{
			player.coins -= move_data.cost.total_coin_cost
			if .Economy in opponent.progress_tokens {
				opponent.coins += move_data.cost.traded_coin_cost
			}
			slot := &board[move_data.slot_idx]
			card_to_construct := remove_card_from_board(slot, game)
			construct_object(card_to_construct, move.acting_player, game)
		}
	case Construct_Wonder:
		{
			player.coins -= move_data.cost.total_coin_cost
			if .Economy in opponent.progress_tokens {
				opponent.coins += move_data.cost.traded_coin_cost
			}
			slot := &board[move_data.slot_idx]
			card_to_tuck := remove_card_from_board(slot, game)
			unordered_remove(&player.wonders_available, move_data.wonder_idx)
			construct_object(move_data.wonder_name, move.acting_player, game)
			append(&player.cards_tucked, card_to_tuck)
		}
	case Discard_For_Coins:
		{
			slot := &board[move_data.slot_idx]
			card_to_discard := remove_card_from_board(slot, game)
			player.coins += 2 + player.object_kind_count_owned[.Yellow]
			append(&game.cards_discarded, card_to_discard)
		}
	case Select_Progress_Token:
		{
			gain_progress_token(move_data.token, move.acting_player, game)
			if move.choice_state == .Choose_Progress_Token {
				game.progress_tokens_available -= {move_data.token}
			}
			if move.choice_state == .Choose_Unavailable_Progress_Token {
				unordered_remove(&game.progress_tokens_unavailable, move_data.token_idx)
			}
		}
	case Select_Card:
		{
			if move.choice_state == .Choose_Card_To_Revive {
				unordered_remove(&game.cards_discarded, move_data.card_idx)
				construct_object(move_data.card_name, move.acting_player, game)
			}
			if move.choice_state == .Choose_Brown_Card_To_Destroy ||
			   move.choice_state == .Choose_Grey_Card_To_Destroy {
				unordered_remove(&opponent.cards_constructed, move_data.card_idx)
				append(&game.cards_discarded, move_data.card_name)
				card_data := objects_db[move_data.card_name]
				opponent.object_kind_count_owned[card_data.kind] -= 1
				opponent.resource_production -= card_data.resources_produced
			}
		}
	case Select_Player:
		{
			game.next_choice_state = .Choose_Object_To_Construct_Or_Discard
			if move.choice_state == .Choose_First_Player {
				game.turn_player = move_data.chosen_player
			}
		}
	}

	append(&game.move_history, move)

	if game.end_of_age_triggered {
		// if a go-again wonder was played as last card, it doesnt carry over to next age
		game.go_again_active = false
		if game.age != .Age3 {
			game.age = Age(int(game.age) + 1)
			game.objects_left_in_age = 20
			// we have a set first player in act 1,
			// and it should be correct already
			if game.age != .Age1 {
				if game.military_track > 0 {game.turn_player = .P1}
				if game.military_track < 0 {game.turn_player = .P2}
				// if military is a tie, the last action taker choses first
				// so we dont need to change the turn player
				game.next_choice_state = .Choose_First_Player
			}
		} else {
			game.completed = true
			vp_p1, blue_vp_p1 := calculate_victory_points(Player_ID.P1, game^)
			vp_p2, blue_vp_p2 := calculate_victory_points(Player_ID.P2, game^)
			net_vp, net_blue_vp := vp_p2 - vp_p1, blue_vp_p2 - blue_vp_p1

			if net_vp != 0 {
				if net_vp < 0 {game.winner = .P1} else {game.winner = .P2}
			} else {
				if net_blue_vp < 0 {game.winner = .P1} else {game.winner = .P2}
			}
			return
		}
	}

	if game.next_choice_state == .Choose_Object_To_Construct_Or_Discard {
		if !game.go_again_active {
			change_turn_player(game)
			game.go_again_active = false
		}
	}
}
