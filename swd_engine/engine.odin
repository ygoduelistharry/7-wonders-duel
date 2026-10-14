package swd_engine

import "core:math/bits"
import "core:math/rand"
import "core:slice"
import "core:time"


Player_State :: struct {
	cards_constructed:            [dynamic; 30]Object_Name,
	wonders:                      [dynamic; 4]Object_Name,
	cards_tucked:                 [4]Object_Name,
	object_kind_count_owned:      [Object_Colour]int,
	player_id:                    Player_ID,
	coins:                        int,
	resource_production:          [Resource]int,
	resource_trade_price:         [Resource]int,
	generic_brown_res_production: int,
	generic_grey_res_production:  int,
	progress_tokens:              Progress_Tokens,
	science_symbols:              [Science_Symbol]int,
	unique_science_symbols:       int,
	linking_symbols:              Linking_Symbols,
	fixed_vp_from_blue:           int,
	fixed_vp_from_other:          int,
	guilds_built:                 Guilds,
}

Move :: struct {
	choice_state:   Choice_State,
	acting_player:  Player_ID,
	move_kind:      Move_Kind,
	wonder_name:    Maybe(Object_Name),
	wonder_idx:     Maybe(int),
	card_name:      Maybe(Object_Name),
	slot_idx:       Maybe(int),
	cost:           Maybe(Object_Real_Cost),
	token:          Maybe(Progress_Token),
	token_idx:      Maybe(int),
	card_idx:       Maybe(int),
	chosen_player:  Maybe(Player_ID),
	resolution_log: Events_Log,
}

Events_Log :: struct {
	gained_coins:              int,
	urbanism_triggered:        bool,
	opponent_gained_coins:     int,
	economy_triggered:         bool,
	military_track_change:     int,
	opponent_lost_coins:       int,
	military_tokens_destroyed: Military_Tokens,
	strategy_triggered:        bool,
	gained_blue_vp:            int,
	gained_other_vp:           int,
	theology_triggered:        bool,
	science_symbol_paired:     Maybe(Science_Symbol),
	victory_triggered:         Victory_Type,
	next_players_turn:         Player_ID,
}

Game :: struct {
	move_history:                [dynamic; 128]Move,
	boards:                      [Age]Board,
	player_states:               #sparse[Player_ID]Player_State,
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
	go_again_active:             bool,
	military_track:              int, //negative means p1 leading
	military_tokens_available:   Military_Tokens,
	progress_tokens_available:   [dynamic; 5]Maybe(Progress_Token),
	progress_tokens_unavailable: [dynamic; 10]Progress_Token,
	end_of_age_triggered:        bool,
	completed:                   bool,
	winner:                      Player_ID,
	victory_type:                Victory_Type,
}

create_new_game :: proc(rng_seed: i64 = -1) -> (new_game: Game) {
	if rng_seed < 0 {
		new_game.rng_seed = u64(time.now()._nsec)} else {
		new_game.rng_seed = u64(rng_seed)
	}
	new_game.rng_state = rand.create_u64(new_game.rng_seed)

	rng := rand.default_random_generator(&new_game.rng_state)

	players: [2]Player_ID = {.P1, .P2}
	new_game.turn_player = rand.choice(players[:], rng)

	new_game.age = .DraftWonders
	new_game.choice_state = .Choose_Wonder_To_Draft
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

	rand.shuffle(all_selected_age3_cards[:], rng)
	for card, idx in all_selected_age3_cards {new_game.boards[.Age3][idx].card_in_slot = card}


	new_game.military_tokens_available = {.P1_2, .P1_5, .P2_2, .P2_5}


	progress_tokens: [len(Progress_Token)]Progress_Token
	for token, idx in Progress_Token {
		progress_tokens[idx] = token
	}
	rand.shuffle(progress_tokens[:], rng)
	for token in progress_tokens[:5] {
		append(&new_game.progress_tokens_available, token)}
	for token in progress_tokens[5:] {
		append(&new_game.progress_tokens_unavailable, token)
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

get_player_constructed_wonders_count :: proc(player: Player_State) -> int {
	count := 0
	for card in player.cards_tucked {
		if int(card) != 0 {count += 1}
	}
	return count
}
get_total_constructed_wonders_count :: proc(game: Game) -> int {
	return(
		get_constructed_wonders_count(game.player_states[.P1]) +
		get_constructed_wonders_count(game.player_states[.P2]) \
	)
}
get_constructed_wonders_count :: proc {
	get_player_constructed_wonders_count,
	get_total_constructed_wonders_count,
}

get_valid_moves :: proc(game: Game) -> (valid_moves: [dynamic; 64]Move) {
	if game.completed {return {}}
	turn_player_id := game.turn_player
	opponent_id := Player_ID(-1 * int(turn_player_id))
	turn_player := game.player_states[turn_player_id]
	opponent := game.player_states[opponent_id]

	switch game.choice_state {
	case .Game_Over:
		{
			return {}
		}
	case .Choose_Wonder_To_Draft:
		{
			for idx in game.wonder_ids_draftable {
				wonder := game.wonders_to_draft[idx]
				append(
					&valid_moves,
					Move{move_kind = .Draft_Wonder, wonder_name = wonder, wonder_idx = idx},
				)
			}
		}
	case .Choose_Object_To_Construct_Or_Discard:
		{
			// get all constructable wonders if 7 haven't been built yet
			base_wonder_moves: [dynamic; 4]Move
			if get_constructed_wonders_count(game) < 7 {
				for wonder, idx in turn_player.wonders {
					if int(turn_player.cards_tucked[idx]) != 0 {continue}
					wonder_cost := get_object_cost(wonder, game)
					if wonder_cost.can_afford {
						append(
							&base_wonder_moves,
							Move {
								move_kind = .Construct_Wonder,
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
						Move {
							move_kind = .Discard_For_Coins,
							card_name = slot.card_in_slot,
							slot_idx = slot.id,
						},
					)
					// add moves to construct cards
					card_cost := get_object_cost(slot.card_in_slot.?, game)
					if card_cost.can_afford {
						append(
							&valid_moves,
							Move {
								move_kind = .Construct_Card,
								card_name = slot.card_in_slot,
								slot_idx = slot.id,
								cost = card_cost,
							},
						)
					}
					// add moves to construct wonders
					for base_wonder_move in base_wonder_moves {
						wonder_move := base_wonder_move
						wonder_move.card_name = slot.card_in_slot
						wonder_move.slot_idx = slot.id
						append(&valid_moves, wonder_move)
					}
				}
			}
		}
	case .Choose_Progress_Token:
		{
			for token, idx in game.progress_tokens_available {
				if token != nil {
					append(
						&valid_moves,
						Move{move_kind = .Select_Progress_Token, token = token, token_idx = idx},
					)
				}

			}
		}
	case .Choose_Unavailable_Progress_Token:
		{
			for token, idx in game.progress_tokens_unavailable {
				if idx >= 3 {break}
				append(
					&valid_moves,
					Move{move_kind = .Select_Progress_Token, token = token, token_idx = idx},
				)
			}
		}
	case .Choose_Brown_Card_To_Destroy:
		{
			for card, idx in opponent.cards_constructed {
				if objects_db[card].colour == .Brown {
					append(
						&valid_moves,
						Move{move_kind = .Select_Card, card_name = card, card_idx = idx},
					)
				}
			}
		}
	case .Choose_Grey_Card_To_Destroy:
		{
			for card, idx in opponent.cards_constructed {
				if objects_db[card].colour == .Grey {
					append(
						&valid_moves,
						Move{move_kind = .Select_Card, card_name = card, card_idx = idx},
					)
				}
			}
		}
	case .Choose_Card_To_Revive:
		{
			for card, idx in game.cards_discarded {
				append(
					&valid_moves,
					Move{move_kind = .Select_Card, card_name = card, card_idx = idx},
				)
			}
		}
	case .Choose_First_Player:
		{
			append(&valid_moves, Move{move_kind = .Select_Player, chosen_player = turn_player_id})
			append(&valid_moves, Move{move_kind = .Select_Player, chosen_player = opponent_id})
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
	case .None:
		{}
	case .Builders_Guild:
		{
			count := max(
				get_constructed_wonders_count(player),
				get_constructed_wonders_count(opponent),
			)
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

get_victory_point_count :: proc(player_id: Player_ID, game: Game) -> (vp: int, blue_vp: int) {
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

// To be used externally by programs interacting with the game
execute_move_safe :: proc(move: Move, game: ^Game) -> bool {
	valid_moves := get_valid_moves(game^)
	for &valid_move in valid_moves {
		if move == valid_move {
			execute_move_unsafe(&valid_move, game)
			return true
		}
	}
	return false
}

// Executes a move and progresses the game state --
// Note! This function doesn't check if the move is valid first!
// Make sure 'move' is selected from array generated by get_valid_moves() procedure!
execute_move_unsafe :: proc(move: ^Move, game: ^Game) {
	board := &game.boards[game.age]
	player := &game.player_states[move.acting_player]
	opponent := &game.player_states[Player_ID(-1 * int(move.acting_player))]

	switch move.move_kind {
	case .None:
		{return}
	case .Draft_Wonder:
		{
			append(&player.wonders, move.wonder_name.?)
			game.wonder_ids_draftable -= {move.wonder_idx.?}
			// we do a snake draft, so players double pick when there are 6 and 2 wonders left
			wonders_left := &game.objects_left_in_age
			wonders_left^ -= 1
			if wonders_left^ != 6 && wonders_left^ != 2 {
				change_turn_player(game)
			}
			// reveal the next 4 wonders to draft if necessary
			if wonders_left^ == 4 {
				game.wonder_ids_draftable += {4, 5, 6, 7}
			}
			if game.objects_left_in_age <= 0 {
				game.end_of_age_triggered = true
			} else {
				game.choice_state = .Choose_Wonder_To_Draft
			}
		}
	case .Construct_Card:
		{
			player.coins -= move.cost.?.total_coin_cost
			if .Economy in opponent.progress_tokens {
				opponent.coins += move.cost.?.traded_coin_cost
			}
			slot := &board[move.slot_idx.?]
			card_to_construct := remove_card_from_board(slot, game)
			construct_object(card_to_construct.?, move.acting_player, game)
			if .Economy in opponent.progress_tokens {
				move.resolution_log.economy_triggered = true
				move.resolution_log.gained_coins = move.cost.?.traded_coin_cost
			}
			if game.choice_state == .Choose_Object_To_Construct_Or_Discard {
				change_turn_player(game)
			}
		}
	case .Construct_Wonder:
		{
			player.coins -= move.cost.?.total_coin_cost
			if .Economy in opponent.progress_tokens {
				opponent.coins += move.cost.?.traded_coin_cost
				move.resolution_log.economy_triggered = true
				move.resolution_log.gained_coins = move.cost.?.traded_coin_cost
			}
			slot := &board[move.slot_idx.?]
			card_to_tuck := remove_card_from_board(slot, game)
			construct_object(move.wonder_name.?, move.acting_player, game, move)
			if .Economy in opponent.progress_tokens {
			}
			for wonder, idx in player.wonders {
				if wonder == move.wonder_name {
					player.cards_tucked[idx] = card_to_tuck.?
					break
				}
			}
			if !game.go_again_active &&
			   game.choice_state == .Choose_Object_To_Construct_Or_Discard {
				change_turn_player(game)
			}
			game.go_again_active = false
		}
	case .Discard_For_Coins:
		{
			slot := &board[move.slot_idx.?]
			card_to_discard := remove_card_from_board(slot, game)
			player.coins += 2 + player.object_kind_count_owned[.Yellow]
			move.resolution_log.gained_coins = 2 + player.object_kind_count_owned[.Yellow]
			append(&game.cards_discarded, card_to_discard.?)
			change_turn_player(game)
		}
	case .Select_Progress_Token:
		{
			gain_progress_token(move.token.?, move.acting_player, game, move)
			if game.choice_state == .Choose_Progress_Token {
				game.progress_tokens_available[move.token_idx.?] = nil
			}
			if game.choice_state == .Choose_Unavailable_Progress_Token {
				unordered_remove(&game.progress_tokens_unavailable, move.token_idx.?)
			}
			game.choice_state = .Choose_Object_To_Construct_Or_Discard
			change_turn_player(game)
		}
	case .Select_Card:
		{
			if game.choice_state == .Choose_Card_To_Revive {
				unordered_remove(&game.cards_discarded, move.card_idx.?)
				construct_object(move.card_name.?, move.acting_player, game, move)
			} else if game.choice_state == .Choose_Brown_Card_To_Destroy ||
			   game.choice_state == .Choose_Grey_Card_To_Destroy {
				unordered_remove(&opponent.cards_constructed, move.card_idx.?)
				append(&game.cards_discarded, move.card_name.?)
				card_data := objects_db[move.card_name.?]
				opponent.object_kind_count_owned[card_data.colour] -= 1
				opponent.resource_production -= card_data.resources_produced
				game.choice_state = .Choose_Object_To_Construct_Or_Discard
			}
			if game.choice_state == .Choose_Object_To_Construct_Or_Discard {
				change_turn_player(game)
			}
		}
	case .Select_Player:
		{
			if game.choice_state == .Choose_First_Player {
				game.turn_player = move.chosen_player.?
			}
			if game.age == .DraftWonders {
				game.choice_state = .Choose_Wonder_To_Draft
			} else {
				game.choice_state = .Choose_Object_To_Construct_Or_Discard
			}
		}
	}


	if game.end_of_age_triggered {
		game.end_of_age_triggered = false
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
				game.choice_state = .Choose_First_Player
			} else {
				game.choice_state = .Choose_Object_To_Construct_Or_Discard
			}
		} else {
			game.completed = true
			game.choice_state = .Game_Over
			game.victory_type = .Civilian
			move.resolution_log.victory_triggered = .Civilian
			vp_p1, blue_vp_p1 := get_victory_point_count(Player_ID.P1, game^)
			vp_p2, blue_vp_p2 := get_victory_point_count(Player_ID.P2, game^)
			net_vp, net_blue_vp := vp_p2 - vp_p1, blue_vp_p2 - blue_vp_p1

			if net_vp != 0 {
				if net_vp < 0 {game.winner = .P1} else {game.winner = .P2}
			} else {
				if net_blue_vp < 0 {game.winner = .P1} else {game.winner = .P2}
			}
		}
	}

	append(&game.move_history, move^)
}

restart_game :: proc(game: ^Game, same_seed: bool = false) {
	if same_seed {
		game^ = create_new_game(i64(game.rng_seed))
	} else {game^ = create_new_game()}
}

undo_move :: proc(game: ^Game) {
	move_history := game.move_history
	restart_game(game, same_seed = true)
	i := 0
	for i < len(move_history) - 1 {
		execute_move_unsafe(&move_history[i], game)
		i += 1
	}
}

