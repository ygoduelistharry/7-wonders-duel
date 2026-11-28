package swd_engine

import "core:log"

log_turn_info :: proc(game: Game) {
	switch game.age {
	case .DraftWonders:
		{
			log.infof(
				"┌─────────────────────────────────────",
			)
			log.infof("│ %v Draft Pick: %v", game.turn_player, 8 - game.objects_left_in_age + 1)
		}
	case .Age1, .Age2, .Age3:
		{
			if game.choice_state == .Choose_Object_To_Construct_Or_Discard {
				log.infof(
					"┌─────────────────────────────────────",
				)
				log.infof(
					"│ %v's turn (Age %v, Turn %v)",
					game.turn_player,
					int(game.age),
					20 - game.objects_left_in_age + 1,
				)
			}
		}
	}
}

log_move :: proc(move: Move, resolution_log: Move_Resolution_Log) {
	switch move.move_kind {
	case .None:
		{return}
	case .Draft_Wonder:
		{
			log.infof("└─ %v drafted %v.", move.acting_player, move.wonder_name)
		}
	case .Construct_Wonder:
		{
			log.infof(
				"└─ %v spent %v coins to construct %v",
				move.acting_player,
				move.cost.total_coin_cost,
				move.wonder_name,
			)
			log.infof("└── (%v tucked)", move.card_name)

			log_object_construction(move, resolution_log)

			if resolution_log.go_again_triggered {
				if resolution_log.theology_triggered {
					log.infof("└─ Go again triggered from Theology.")
				} else {
					log.infof("└─ Go again triggered.")
				}
			}
		}
	case .Construct_Card:
		{
			log.infof(
				"└─ %v spent %v coins to construct %v.",
				move.acting_player,
				move.cost.total_coin_cost,
				move.card_name,
			)

			log_object_construction(move, resolution_log)

		}
	case .Discard_For_Coins:
		{
			log.infof(
				"└─ %v discarded %v for %v coins.",
				move.acting_player,
				move.card_name,
				resolution_log.gained_coins,
			)
		}
	case .Select_Progress_Token:
		{
			log.infof("└─ %v gained the %v progress token.", move.acting_player, move.token)
			if resolution_log.gained_coins > 0 {
				log.infof(
					"└─ %v gained %v coins.",
					move.acting_player,
					resolution_log.gained_coins,
				)
			}
		}
	case .Select_Card:
		{
			#partial switch move.choice_state {
			case .Choose_Brown_Card_To_Destroy, .Choose_Grey_Card_To_Destroy:
				{
					log.infof(
						"└─ %v's card %v was destroyed.",
						other_player_id(move.acting_player),
						move.card_name,
					)
				}
			case .Choose_Card_To_Revive:
				{
					log.infof("└─ %v revived the card %v.", move.acting_player, move.card_name)
					log_object_construction(move, resolution_log)
				}
			}
		}
	case .Select_Player:
		{
			if move.acting_player == move.chosen_player {
				log.infof("└─ %v has chosen to start.", move.acting_player)
			} else {
				log.infof(
					"└─ %v has chosen to let %v start.",
					move.acting_player,
					move.chosen_player,
				)
			}
		}
	}
}

log_object_construction :: proc(move: Move, resolution_log: Move_Resolution_Log) {
	if resolution_log.economy_triggered {
		log.infof(
			"└── (%v gained %v coins from Economy.)",
			other_player_id(move.acting_player),
			move.cost.traded_coin_cost,
		)
	}
	if resolution_log.gained_coins > 0 {
		log.infof("└─ %v gained %v coins.", move.acting_player, resolution_log.gained_coins)
		if resolution_log.urbanism_triggered {
			log.infof("└── (4 coins gained from Urbanism)")
		}
	}
	if resolution_log.military_track_change != 0 {
		absolute_track_change := resolution_log.military_track_change
		if resolution_log.military_track_change < 0 {absolute_track_change *= -1}
		log.infof(
			"└─ Military pawn moved %v space(s) towards %v",
			absolute_track_change,
			other_player_id(move.acting_player),
		)
		if resolution_log.strategy_triggered {
			log.infof("└── (1 shield from Strategy)")
		}
		if resolution_log.opponent_lost_coins > 0 {
			log.infof("└─ A military token was destroyed.")
		}
	}
	if resolution_log.opponent_lost_coins > 0 {
		log.infof(
			"└─ %v lost %v coins.",
			other_player_id(move.acting_player),
			resolution_log.opponent_lost_coins,
		)
	}
	if resolution_log.science_symbol_paired != nil {
		log.infof(
			"└─ %v paired the %v science symbol.",
			move.acting_player,
			resolution_log.science_symbol_paired,
		)
	}
}

