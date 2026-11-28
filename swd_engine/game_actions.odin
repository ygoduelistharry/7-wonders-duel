package swd_engine

// Generally shouldn't call any procs in this file directly.
// These are mostly called by execute_move_unsafe()

change_turn_player :: proc(game: ^Game) {
	game.turn_player = Player_ID(-1 * int(game.turn_player))
}

// Constructs an object and performs all immediate deterministic actions possible, for example;
// coin gain/loss, sets choice state to visit next, resolves military track tokens, etc.
construct_object :: proc(
	object_name: Object_Name,
	player_id: Player_ID,
	game: ^Game,
	resolution_log: ^Move_Resolution_Log = nil,
) {
	dummy_log: Move_Resolution_Log = ---
	log := resolution_log if resolution_log != nil else &dummy_log

	object := objects_db[object_name]
	player := &game.player_states[player_id]
	opponent := &game.player_states[Player_ID(-1 * int(player_id))]

	// Most common next state. Will get overridden if required.
	game.choice_state = .Choose_Object_To_Construct_Or_Discard

	if game_object_is_card(object_name) {
		append(&player.cards_constructed, object_name)
	}
	player.object_kind_count_owned[object.colour] += 1

	coin_gain :=
		object.coins_produced +
		dot(object.coins_per_object_produced, player.object_kind_count_owned)
	if .Urbanism in player.progress_tokens &&
	   object.cost.free_construction_symbol in player.linking_symbols {
		coin_gain += 4
		log.urbanism_triggered = true
	}
	if object.colour == .Purple {
		_, coin_from_guild := get_guild_value(object.guild, player_id, game^)
		coin_gain += coin_from_guild
	}

	player.coins += coin_gain
	log.gained_coins += coin_gain

	player.resource_production += object.resources_produced
	if object.colour == .Brown || object.colour == .Grey {
		for &value, resource in opponent.resource_trade_price {
			if value != 1 {
				value += object.resources_produced[resource]
			}
		}
	}

	for &value, resource in player.resource_trade_price {
		if resource in object.fixed_cost_resource_produced {value = 1}
	}

	player.generic_brown_res_production += object.variable_brown_resource_produced
	player.generic_grey_res_production += object.variable_grey_resource_produced

	if object.colour == .Blue {
		player.fixed_vp_from_blue += object.vp_produced
		log.gained_blue_vp = object.vp_produced
	} else {
		player.fixed_vp_from_other += object.vp_produced
		log.gained_other_vp = object.vp_produced
	}

	if symbol, ok := object.linking_symbol_produced.?; ok {player.linking_symbols |= {symbol}}

	coin_loss := object.coins_destroyed
	if object.military_produced > 0 {
		game.military_track -= int(player_id) * object.military_produced

		log.military_track_change -= int(player_id) * object.military_produced

		if object.colour == .Red {
			if .Strategy in player.progress_tokens {
				game.military_track += int(player_id)

				log.military_track_change -= int(player_id)
				log.strategy_triggered = true

			}
		}
		// Check for military victory
		if game.military_track <= -9 {
			game.choice_state = .Game_Over
			game.completed = true
			game.winner = .P1
			game.victory_type = .Military
			log.victory_triggered = .Military
			return
		}
		if game.military_track >= 9 {
			game.choice_state = .Game_Over
			game.completed = true
			game.winner = .P2
			game.victory_type = .Military
			log.victory_triggered = .Military
			return
		}
		// Destroy opponent coins and check for military
		if game.military_track <= -3 && .P1_2 in game.military_tokens_available {
			coin_loss += 2
			game.military_tokens_available -= {.P1_2}
			log.military_tokens_destroyed += {.P1_2}
		}
		if game.military_track <= -6 && .P1_5 in game.military_tokens_available {
			coin_loss += 5
			game.military_tokens_available -= {.P1_5}
			log.military_tokens_destroyed += {.P1_5}
		}
		if game.military_track >= 3 && .P2_2 in game.military_tokens_available {
			coin_loss += 2
			game.military_tokens_available -= {.P2_2}
			log.military_tokens_destroyed += {.P2_2}
		}
		if game.military_track >= 6 && .P2_5 in game.military_tokens_available {
			coin_loss += 5
			game.military_tokens_available -= {.P2_5}
			log.military_tokens_destroyed += {.P2_5}
		}
	}

	actual_coin_loss := min(opponent.coins, coin_loss)
	opponent.coins -= actual_coin_loss
	log.opponent_lost_coins = actual_coin_loss

	// Check for science
	if symbol, ok := object.science_symbol_produced.?; ok {
		player.science_symbols[symbol] += 1
		if player.science_symbols[symbol] == 1 {
			player.unique_science_symbols += 1
			if player.unique_science_symbols >= 6 {
				game.choice_state = .Game_Over
				game.completed = true
				game.winner = player_id
				game.victory_type = .Science
				log.victory_triggered = .Science
				return
			}
		}
		if player.science_symbols[symbol] == 2 {
			game.choice_state = .Choose_Progress_Token
			log.science_symbol_paired = symbol
		}
	}

	// Wonder specific effects
	if object.go_again {
		game.go_again_active = true
	} else if .Theology in player.progress_tokens && object.colour == .Wonder {
		game.go_again_active = true
		log.theology_triggered = true
	}
	if object.gain_unavailable_progress_token {
		game.choice_state = .Choose_Unavailable_Progress_Token
	} else if object.destroy_brown_card && opponent.object_kind_count_owned[.Brown] > 0 {
		game.choice_state = .Choose_Brown_Card_To_Destroy
	} else if object.destroy_grey_card && opponent.object_kind_count_owned[.Grey] > 0 {
		game.choice_state = .Choose_Grey_Card_To_Destroy
	} else if object.revive_card && len(game.cards_discarded) > 0 {
		game.choice_state = .Choose_Card_To_Revive
	}

	// check if object costs need recalculating
	if object_affects_cost(object) {
		for &slot in game.boards[game.age] {
			slot.cost_updated = {}
		}
		game.player_states[.P1].wonder_costs_updated = {}
		game.player_states[.P2].wonder_costs_updated = {}
	}

	return
}


// Returns the card removed from the slot (will be nil if slot was empty)
remove_card_from_board :: proc(
	slot: ^Board_Slot,
	game: ^Game,
) -> (
	card_removed: Maybe(Object_Name),
) {
	board: ^Board = &game.boards[slot.age]
	card_removed = slot.card_in_slot
	if card_removed != nil {
		slot.card_in_slot = nil
		game.objects_left_in_age -= 1
		slot.selectable = false
		for covered_id in slot.covers {
			board[covered_id].covered_by_count -= 1
			if board[covered_id].covered_by_count <= 0 {
				board[covered_id].selectable = true
				board[covered_id].face_up = true
			}
		}
	}
	return card_removed
}

gain_progress_token :: proc(
	token: Progress_Token,
	player_id: Player_ID,
	game: ^Game,
	resolution_log: ^Move_Resolution_Log = nil,
) {
	dummy_log: Move_Resolution_Log = ---
	log := resolution_log if resolution_log != nil else &dummy_log

	player := &game.player_states[player_id]
	player.progress_tokens |= {token}
	switch token {
	case .Agriculture:
		{
			player.fixed_vp_from_other += 4
			log.gained_other_vp += 4
			player.coins += 6
			log.gained_coins += 6
		}
	case .Architecture:
		{
			player.wonder_costs_updated = {}
		}
	case .Economy:
		{}
	case .Law:
		{player.science_symbols[.Scales] += 1
			player.unique_science_symbols += 1
			if player.unique_science_symbols >= 6 {
				game.completed = true
				game.winner = player_id
				game.victory_type = .Science
				if log != nil {log.victory_triggered = .Science}
			}
		}
	case .Masonry:
		{
			for &slot in game.boards[game.age] {
				slot.cost_updated[player_id] = false
			}
		}
	case .Mathematics:
		{}
	case .Philosophy:
		{
			player.fixed_vp_from_other += 7
			log.gained_other_vp += 7
		}
	case .Strategy:
		{}
	case .Theology:
		{}
	case .Urbanism:
		{
			player.coins += 6
			log.gained_coins += 6
		}
	}
	return
}

