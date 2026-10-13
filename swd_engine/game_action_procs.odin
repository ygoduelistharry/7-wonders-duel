package swd_engine

// Generally shouldnt call any procs in this file directly.
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
) -> (
	events: Events_Log,
) {
	object := objects_db[object_name]
	player := &game.player_states[player_id]
	opponent := &game.player_states[Player_ID(-1 * int(player_id))]

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
		events.urbanism_triggered = true
	}
	if object.colour == .Purple {
		_, coin_from_guild := get_guild_value(object.guild, player_id, game^)
		coin_gain += coin_from_guild
	}

	player.coins += coin_gain
	events.gained_coins += coin_gain

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
		events.gained_blue_vp = object.vp_produced
	} else {
		player.fixed_vp_from_other += object.vp_produced
		events.gained_other_vp = object.vp_produced
	}

	if symbol, ok := object.linking_symbol_produced.?; ok {player.linking_symbols |= {symbol}}

	if object.colour == .Red {
		game.military_track += int(player_id) * object.military_produced
		events.military_track_change += int(player_id) * object.military_produced
		if .Strategy in player.progress_tokens {
			game.military_track += int(player_id)
			events.military_track_change += int(player_id)
			events.strategy_triggered = true
		}
	}

	// destroy opponent coins
	coin_loss := object.coins_destroyed
	if game.military_track <= -3 && .P1_2 in game.military_tokens_available {
		coin_loss += 2
		game.military_tokens_available -= {.P1_2}
		events.military_tokens_destroyed += {.P1_2}
	}
	if game.military_track <= -6 && .P1_5 in game.military_tokens_available {
		coin_loss += 5
		game.military_tokens_available -= {.P1_5}
		events.military_tokens_destroyed += {.P1_5}
	}
	if game.military_track >= 3 && .P2_2 in game.military_tokens_available {
		coin_loss += 2
		game.military_tokens_available -= {.P2_2}
		events.military_tokens_destroyed += {.P2_2}
	}
	if game.military_track >= 6 && .P2_5 in game.military_tokens_available {
		coin_loss += 5
		game.military_tokens_available -= {.P2_5}
		events.military_tokens_destroyed += {.P2_5}
	}
	opponent.coins = max(0, opponent.coins - coin_loss)
	events.opponent_lost_coins = min(opponent.coins, coin_loss)

	// check for military victory
	if game.military_track <= -9 {
		game.choice_state = .Game_Over
		game.completed = true
		game.winner = .P1
		game.victory_type = .Military
		events.victory_triggered = .Military
		return
	}
	if game.military_track >= 9 {
		game.choice_state = .Game_Over
		game.completed = true
		game.winner = .P2
		game.victory_type = .Military
		events.victory_triggered = .Military
		return
	}


	// Check for science events
	if symbol, ok := object.science_symbol_produced.?; ok {
		player.science_symbols[symbol] += 1
		if player.science_symbols[symbol] == 1 {
			player.unique_science_symbols += 1
			if player.unique_science_symbols >= 6 {
				game.choice_state = .Game_Over
				game.completed = true
				game.winner = player_id
				game.victory_type = .Science
				events.victory_triggered = .Science
				return
			}
		}
		if player.science_symbols[symbol] == 2 {
			game.choice_state = .Choose_Progress_Token
			events.science_symbol_paired = symbol
		}
	}

	// Wonder specific effects
	if object.go_again {
		game.go_again_active = true
	} else if .Theology in player.progress_tokens && object.colour == .Wonder {
		game.go_again_active = true
		events.theology_triggered = true
	}
	if object.gain_unavailable_progress_token {
		game.choice_state = .Choose_Unavailable_Progress_Token
	} else if object.destroy_brown_card && opponent.object_kind_count_owned[.Brown] > 0 {
		game.choice_state = .Choose_Brown_Card_To_Destroy
	} else if object.destroy_grey_card && opponent.object_kind_count_owned[.Grey] > 0 {
		game.choice_state = .Choose_Grey_Card_To_Destroy
	} else if object.revive_card && len(game.cards_discarded) > 0 {
		game.choice_state = .Choose_Card_To_Revive
	} else {game.choice_state = .Choose_Object_To_Construct_Or_Discard}

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
	if game.objects_left_in_age <= 0 {game.end_of_age_triggered = true}
	return card_removed
}

gain_progress_token :: proc(
	token: Progress_Token,
	player_id: Player_ID,
	game: ^Game,
) -> (
	events: Events_Log,
) {
	player := &game.player_states[player_id]
	player.progress_tokens |= {token}
	switch token {
	case .Agriculture:
		{
			player.fixed_vp_from_other += 4
			player.coins += 6
		}
	case .Architecture:
		{}
	case .Economy:
		{}
	case .Law:
		{player.science_symbols[.Scales] += 1
			player.unique_science_symbols += 1
			if player.unique_science_symbols >= 6 {
				game.completed = true
				game.winner = player_id
				game.victory_type = .Science
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
	return
}

