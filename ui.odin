package swd_ui

import "core:fmt"
import "core:math"
import "core:slice"
import ui "my_ui"
import swd "swd_engine"
import rl "vendor:raylib"


UIElement :: struct {
	ui_data:        ui.Data,
	//engine related data
	game_function:  GameFunction,
	game_object:    swd.Object_Name,
	progress_token: swd.Progress_Token,
}

print_ui_element_name :: proc(ui_element: UIElement) {
	#partial switch ui_element.game_function {
	case .GameObject:
		fmt.println(ui_element.game_object)
	case .ProgressToken:
		fmt.println(ui_element.progress_token)
	case:
		{fmt.println()}
	}
}

create_game_object_ui_element :: proc(
	game_object: swd.Object_Name,
	dest_midpoint: [2]f32,
	rotation: f32 = 0,
	tint: rl.Color = rl.WHITE,
	border_width: f32 = 0,
	border_colour: rl.Color = rl.WHITE,
) -> (
	element: UIElement,
) {
	element.ui_data = ui.Data {
		label           = .Visual,
		source_rect     = get_game_object_sub_texture_rect(game_object),
		hitbox_midpoint = dest_midpoint,
		dest_midpoint   = dest_midpoint,
		texture         = game_object_atlases[object_texture_info_db[game_object].game_object_back],
		corner_radius   = 50,
		tint            = tint,
		border_width    = border_width,
		border_colour   = border_colour,
	}
	if swd.game_object_is_card(game_object) {
		element.ui_data.dest_size = CARD_SIZE
		element.ui_data.hitbox_size = CARD_SIZE
	} else {
		element.ui_data.dest_size = WONDER_SIZE
		element.ui_data.hitbox_size = WONDER_SIZE
	}
	element.game_function = .GameObject
	element.game_object = game_object
	return
}

MAX_UI_ELEMENTS :: 256
UIState :: struct {
	game:                          ^swd.Game,
	last_mouse_world_position:     [2]f32,
	ui_element_hovered_last_frame: UIElement,
	ui_element_list:               [dynamic; MAX_UI_ELEMENTS]UIElement,
	valid_moves:                   [dynamic; 64]swd.Move,
	valid_moves_dirty:             bool,
	last_selected_object:          Maybe(swd.Object_Name),
	object_costs:                  #sparse[swd.Player_ID][swd.Object_Name]swd.Object_Real_Cost,
	cost_overlay_on:               bool,
}


update_ui_element_list :: proc(ui_state: ^UIState) {
	prev_element_count := len(ui_state.ui_element_list)
	clear(&ui_state.ui_element_list)
	append_wonder_draft_elements(ui_state)
	append_player_wonder_elements(ui_state)
	append_card_structure_elements(ui_state)
	append_military_track_elements(ui_state)
	append_player_coin_elements(ui_state)
	append_build_icon_elements(ui_state)
	append_player_card_elements(ui_state)
	append_player_info(ui_state)
	append_token_tooltips(ui_state)
	if len(ui_state.ui_element_list) != prev_element_count {
		fmt.print("--UIElement count last frame: ")
		fmt.println(len(ui_state.ui_element_list[:]))
	}
}


append_wonder_draft_elements :: proc(ui_state: ^UIState) {
	if ui_state.game.age != .DraftWonders {return}
	for wonder, i in ui_state.game.wonders_to_draft {
		if i in ui_state.game.wonder_ids_draftable {
			grid_pos: [2]f32
			switch i % 4 {
			case 0:
				{grid_pos = {-1, -1}}
			case 1:
				{grid_pos = {1, -1}}
			case 2:
				{grid_pos = {-1, 1}}
			case 3:
				{grid_pos = {1, 1}}
			}
			midpoint := CARD_STRUCTURE_MIDPOINT + grid_pos * (WONDER_SIZE / 2 + {2.0, 2.0})
			append(
				&ui_state.ui_element_list,
				create_game_object_ui_element(
					wonder,
					midpoint,
					border_width = 4,
					border_colour = PLAYER_COLOUR[ui_state.game.turn_player],
				),
			)
		}
	}
}

append_card_structure_elements :: proc(ui_state: ^UIState) {
	if ui_state.game.age == .DraftWonders {return}
	y_offset: f32 = CARD_SIZE.y * 1.0 / 2.8
	x_offset: f32 = CARD_SIZE.x * 1.0 / 2.0 + 3
	layout_grid := CARD_STRUCTURE_GRIDS[ui_state.game.age]
	turn_player := ui_state.game.turn_player
	for i := 19; i >= 0; i -= 1 {
		grid_pos := layout_grid[i]
		slot := ui_state.game.boards[ui_state.game.age][i]
		midpoint: [2]f32 =
			CARD_STRUCTURE_MIDPOINT + {f32(grid_pos.x), f32(grid_pos.y)} * {x_offset, y_offset}
		show_cost: bool
		card := slot.card_in_slot
		if card == nil {continue}
		if slot.face_up {
			border_colour: rl.Color
			border_width: f32
			if slot.selectable {
				border_width = 4.0
				if ui_state.cost_overlay_on {show_cost = true}
			}
			if ui_state.last_selected_object == card {
				border_colour = rl.YELLOW
			} else {
				border_colour = PLAYER_COLOUR[turn_player]
			}
			append(
				&ui_state.ui_element_list,
				create_game_object_ui_element(
					card.?,
					midpoint,
					border_width = border_width,
					border_colour = border_colour,
				),
			)
			if show_cost {
				append(
					&ui_state.ui_element_list,
					UIElement {
						ui_data = ui.Data {
							label = .Visual,
							texture = coin_texture,
							dest_midpoint = midpoint,
							dest_size = 40,
						},
					},
				)
				append(
					&ui_state.ui_element_list,
					UIElement {
						ui_data = ui.Data {
							label = .Text,
							dest_midpoint = midpoint,
							text = fmt.ctprintf(
								"%d",
								ui_state.object_costs[turn_player][card.?].total_coin_cost,
							),
							font = main_font,
							font_size = 30,
							text_colour = rl.WHITE,
						},
					},
				)
			}
		} else {
			back := object_texture_info_db[card.?].game_object_back
			back_texture := card_back_textures[back]
			append(
				&ui_state.ui_element_list,
				UIElement {
					ui_data = ui.Data {
						label = .Visual,
						texture = back_texture,
						dest_midpoint = midpoint,
						dest_size = CARD_SIZE,
						hitbox_midpoint = midpoint,
						hitbox_size = CARD_SIZE,
						corner_radius = 50,
					},
				},
			)
		}
	}
}


append_military_track_elements :: proc(ui_state: ^UIState) {
	//the track itself
	append(
		&ui_state.ui_element_list,
		UIElement {
			ui_data = ui.Data {
				label = .Visual,
				texture = military_track_texture,
				dest_midpoint = MILITARY_TRACK_MIDPOINT,
				dest_size = MILITARY_TRACK_SIZE,
			},
		},
	)
	//military tokens on the track
	token_texture: rl.Texture2D
	token_midpoint: [2]f32
	token_rotation: f32
	for token in ui_state.game.military_tokens_available {
		switch token {
		case .P1_2:
			{
				token_texture = military_token_2_texture
				token_midpoint = MILITARY_TRACK_MIDPOINT + {-145, 73} * MILITARY_TRACK_SCALE
				token_rotation = -90
			}
		case .P1_5:
			{
				token_texture = military_token_5_texture
				token_midpoint = MILITARY_TRACK_MIDPOINT + {-260, 73} * MILITARY_TRACK_SCALE
				token_rotation = -90
			}
		case .P2_2:
			{
				token_texture = military_token_2_texture
				token_midpoint = MILITARY_TRACK_MIDPOINT + {145, 73} * MILITARY_TRACK_SCALE
				token_rotation = 90
			}
		case .P2_5:
			{
				token_texture = military_token_5_texture
				token_midpoint = MILITARY_TRACK_MIDPOINT + {260, 73} * MILITARY_TRACK_SCALE
				token_rotation = 90
			}
		}
		append(
			&ui_state.ui_element_list,
			UIElement {
				ui_data = ui.Data {
					label = .Visual,
					texture = token_texture,
					dest_midpoint = token_midpoint,
					dest_size = MILITARY_TOKEN_SIZE,
					rotation = token_rotation,
				},
			},
		)
	}
	//draw the conflict pawn
	pawn_offset: f32 = f32(ui_state.game.military_track * 37) * MILITARY_TRACK_SCALE
	append(
		&ui_state.ui_element_list,
		UIElement {
			ui_data = ui.Data {
				label = .Visual,
				texture = conflict_pawn_texture,
				dest_midpoint = MILITARY_TRACK_MIDPOINT + {pawn_offset, 15 * MILITARY_TRACK_SCALE},
				dest_size = CONFLICT_PAWN_SIZE,
			},
		},
	)
	//available progress tokens
	token_spacing: f32 = PROGRESS_TOKEN_DIAMETER + 4 * MILITARY_TRACK_SCALE
	token_size: [2]f32 = {PROGRESS_TOKEN_DIAMETER, PROGRESS_TOKEN_DIAMETER}
	token_offset: [2]f32 = {-2 * token_spacing, -67 * MILITARY_TRACK_SCALE}

	for token_taken, i in ui_state.game.progress_token_taken {
		if token_taken {continue}
		token_to_draw := ui_state.game.progress_tokens_available[i]
		token_midpoint = MILITARY_TRACK_MIDPOINT + token_offset + {f32(i) * token_spacing, 0}
		append(
			&ui_state.ui_element_list,
			UIElement {
				progress_token = token_to_draw,
				game_function = .ProgressToken,
				ui_data = ui.Data {
					label = .Visual,
					texture = progress_token_textures[token_to_draw],
					dest_midpoint = token_midpoint,
					dest_size = token_size,
					hitbox_midpoint = token_midpoint,
					hitbox_size = token_size,
					rotation = 180,
				},
			},
		)
	}
}

append_player_wonder_elements :: proc(ui_state: ^UIState) {
	gap: f32 = 5
	for player_id in swd.Player_ID {
		for wonder, i in ui_state.game.player_states[player_id].wonders {
			row, col := math.divmod(i, 2)
			x := WONDER_SIZE.x / 2 + f32(col) * (WONDER_SIZE.x + gap) + 5
			if player_id == .P2 {x += STARTING_WINDOW_WIDTH - (2 * WONDER_SIZE.x + gap) - 5}
			y := WONDER_SIZE.y / 2 + f32(row) * (WONDER_SIZE.y + gap) + 5
			wonder_cost := ui_state.object_costs[player_id][wonder]


			//possible states
			card_selected := ui_state.last_selected_object != nil
			can_afford := wonder_cost.can_afford
			turn_player_owns_wonder := ui_state.game.turn_player == player_id
			wonder_built := int(ui_state.game.player_states[player_id].cards_tucked[i]) != 0
			seven_wonders_built := swd.count_constructed_wonders(ui_state.game^) >= 7

			//drawing options
			tint := rl.WHITE
			border_width: f32 = 0.0

			switch {
			case (seven_wonders_built && !wonder_built),
			     (card_selected && (!turn_player_owns_wonder || !can_afford)):
				{
					tint = rl.GRAY
				}
			case (card_selected && turn_player_owns_wonder && can_afford):
				{
					border_width = 4.0
				}
			}

			append(
				&ui_state.ui_element_list,
				create_game_object_ui_element(
					wonder,
					{x, y},
					tint = tint,
					border_width = border_width,
				),
			)

			switch {
			case wonder_built:
				{
					append(
						&ui_state.ui_element_list,
						UIElement {
							ui_data = ui.Data {
								label = .Visual,
								texture = built_icon_texture,
								dest_midpoint = {x, y},
								dest_size = 50,
							},
						},
					)
				}
			case !seven_wonders_built && ui_state.cost_overlay_on:
				{
					append(
						&ui_state.ui_element_list,
						UIElement {
							ui_data = ui.Data {
								label = .Visual,
								texture = coin_texture,
								dest_midpoint = {x, y},
								dest_size = 40,
							},
						},
					)
					append(
						&ui_state.ui_element_list,
						UIElement {
							ui_data = ui.Data {
								label = .Text,
								dest_midpoint = {x, y},
								text = fmt.ctprintf("%d", wonder_cost.total_coin_cost),
								font = main_font,
								font_size = 30,
								text_colour = rl.WHITE,
							},
						},
					)
				}
			}
		}
	}
}


append_player_card_elements :: proc(ui_state: ^UIState) {
	card_names: [dynamic; 30]swd.Object_Name
	for player in swd.Player_ID {
		card_names = ui_state.game.player_states[player].cards_constructed
		slice.sort_by(card_names[:], proc(i, j: swd.Object_Name) -> bool {
			return int(i) < int(j)
		})

		x_base: f32
		switch player {
		case .P1:
			{
				x_base = CARD_SIZE.x / 2 + 50
			}
		case .P2:
			{
				x_base = STARTING_WINDOW_WIDTH - CARD_SIZE.x * 3.5 - 50
			}
		}

		last_col := -1
		curr_col := 0
		row := 0

		for card in card_names {
			switch int(card) {
			case 0 ..< 19:
				{curr_col = 0}
			case 19 ..< 40:
				{curr_col = 1}
			case 40 ..< 54:
				{curr_col = 2}
			case 54 ..< len(swd.Object_Name) + 1:
				{curr_col = 3}
			}
			if curr_col != last_col {
				row = 0
				last_col = curr_col
			} else {row += 1}
			x := x_base + f32(curr_col) * CARD_SIZE.x
			y := WONDER_SIZE.y * 2 + 25 + f32(row + 2) * CARD_SIZE.y / 4
			append(&ui_state.ui_element_list, create_game_object_ui_element(card, {x, y}))
		}
	}
}

append_player_coin_elements :: proc(ui_state: ^UIState) {
	coin_x_offset := MILITARY_TRACK_SIZE.x / 3 + 20
	coin_y := STARTING_WINDOW_HEIGHT - 2.3 * COIN_DIAMETER

	for player in swd.Player_ID {
		coin_position: [2]f32
		switch player {
		case .P1:
			{
				coin_position = {STARTING_WINDOW_WIDTH / 2 - coin_x_offset, coin_y}
			}
		case .P2:
			{
				coin_position = {STARTING_WINDOW_WIDTH / 2 + coin_x_offset, coin_y}
			}
		}
		game_function: GameFunction
		border_width: f32
		if ui_state.game.turn_player == player {
			game_function = .DiscardForCoinConfirm
			border_width = 4.0
		}
		append(
			&ui_state.ui_element_list,
			UIElement {
				game_function = game_function,
				ui_data = ui.Data {
					label = .Visual,
					texture = coin_texture,
					dest_midpoint = coin_position,
					dest_size = {COIN_DIAMETER, COIN_DIAMETER},
					hitbox_midpoint = coin_position,
					hitbox_size = {COIN_DIAMETER, COIN_DIAMETER},
					border_width = border_width,
					border_colour = PLAYER_COLOUR[player],
					corner_radius = f32(coin_texture.height / 2),
				},
			},
		)
		append(
			&ui_state.ui_element_list,
			UIElement {
				ui_data = ui.Data {
					label = .Text,
					text = fmt.ctprintf("%d", ui_state.game.player_states[player].coins),
					font = main_font,
					font_size = COIN_FONT_SIZE,
					text_colour = COIN_FONT_COLOUR,
					dest_midpoint = coin_position,
				},
			},
		)
	}
}

append_build_icon_elements :: proc(ui_state: ^UIState) {
	icon_x_offset := MILITARY_TRACK_SIZE.x / 3 + 20
	icon_y := STARTING_WINDOW_HEIGHT - 3.5 * COIN_DIAMETER
	turn_player := ui_state.game.turn_player
	icon_position: [2]f32
	for player in swd.Player_ID {
		switch player {
		case .P1:
			{icon_position = {STARTING_WINDOW_WIDTH / 2 - icon_x_offset, icon_y}}
		case .P2:
			{icon_position = {STARTING_WINDOW_WIDTH / 2 + icon_x_offset, icon_y}}
		}
		build_cost: swd.Object_Real_Cost
		turn_player_coins := ui_state.game.player_states[turn_player].coins
		tint := rl.GRAY
		border_width: f32 = 0.0
		text_colour := rl.RED
		display_cost: bool
		if player == turn_player && ui_state.last_selected_object != nil {
			build_cost = ui_state.object_costs[player][ui_state.last_selected_object.?]
			display_cost = true
			if build_cost.can_afford {
				tint = rl.WHITE
				border_width = 4.0
				text_colour = rl.WHITE
			}
		}
		append(
			&ui_state.ui_element_list,
			UIElement {
				game_function = .ConstructCardConfirm,
				ui_data = ui.Data {
					label = .Visual,
					texture = build_icon_texture,
					dest_midpoint = icon_position,
					dest_size = {COIN_DIAMETER, COIN_DIAMETER},
					hitbox_midpoint = icon_position,
					hitbox_size = {COIN_DIAMETER, COIN_DIAMETER},
					tint = tint,
					border_width = border_width,
					border_colour = PLAYER_COLOUR[turn_player],
					corner_radius = f32(build_icon_texture.height / 2),
				},
			},
		)
		if display_cost {
			append(
				&ui_state.ui_element_list,
				UIElement {
					ui_data = ui.Data {
						label = .Text,
						text = fmt.ctprintf("-%d", build_cost.total_coin_cost),
						font = main_font,
						font_size = 70,
						text_colour = text_colour,
						dest_midpoint = icon_position,
					},
				},
			)
		}
	}
}

append_player_info :: proc(ui_state: ^UIState) {
	turn_player_text: cstring
	text_x_offset := MILITARY_TRACK_SIZE.x / 2 + COIN_DIAMETER * 1.75
	text_y := STARTING_WINDOW_HEIGHT - COIN_DIAMETER * 0.5
	text_midpoint: [2]f32
	text_colour: rl.Color
	switch ui_state.game.turn_player {
	case .P1:
		{
			turn_player_text = "P1's Turn!"
			text_midpoint = {STARTING_WINDOW_WIDTH / 2 - text_x_offset, text_y}
			text_colour = rl.BLUE
		}
	case .P2:
		{
			turn_player_text = "P2's Turn!"
			text_midpoint = {STARTING_WINDOW_WIDTH / 2 + text_x_offset, text_y}
			text_colour = rl.RED
		}
	}
	append(
		&ui_state.ui_element_list,
		UIElement {
			ui_data = ui.Data {
				label = .Text,
				text = turn_player_text,
				font = main_font,
				font_size = 60,
				text_colour = text_colour,
				dest_midpoint = text_midpoint,
			},
		},
	)
	icon_size: f32 = 120.0
	x_offset: f32 = icon_size / 2 + 10
	y_offset: f32 = STARTING_WINDOW_HEIGHT - icon_size / 2 - 10
	border_width: f32 = 0.0
	if ui_state.game.choice_state == .Choose_First_Player {
		border_width = 20.0
	}
	border_colour := rl.YELLOW
	append(
		&ui_state.ui_element_list,
		UIElement {
			game_function = .SelectP1,
			ui_data = ui.Data {
				label = .Visual,
				dest_size = {icon_size, icon_size},
				dest_midpoint = {x_offset, y_offset},
				hitbox_size = {icon_size, icon_size},
				hitbox_midpoint = {x_offset, y_offset},
				texture = player_icon_textures[.P1],
				border_width = border_width,
				border_colour = border_colour,
			},
		},
	)
	append(
		&ui_state.ui_element_list,
		UIElement {
			game_function = .SelectP2,
			ui_data = ui.Data {
				label = .Visual,
				dest_size = {icon_size, icon_size},
				dest_midpoint = {STARTING_WINDOW_WIDTH - x_offset, y_offset},
				hitbox_size = {icon_size, icon_size},
				hitbox_midpoint = {STARTING_WINDOW_WIDTH - x_offset, y_offset},
				texture = player_icon_textures[.P2],
				border_width = border_width,
				border_colour = border_colour,
			},
		},
	)
}

append_token_tooltips :: proc(ui_state: ^UIState) {
	if ui_state.ui_element_hovered_last_frame.game_function == .ProgressToken {
		token := ui_state.ui_element_hovered_last_frame.progress_token
		for element in ui.create_text_box_fixed_width_elements(
			swd.progress_token_description[token],
			main_font,
			20,
			2,
			rl.WHITE,
			ui_state.ui_element_hovered_last_frame.ui_data.dest_midpoint - {0, 60},
			250,
			v_box_origin = .BOTTOM,
			fill_colour = {0, 0, 0, 128},
			border_width = 2,
			border_colour = rl.DARKPURPLE,
			corner_radius = 8,
		) {
			append(&ui_state.ui_element_list, UIElement{ui_data = element})
		}
	}
}

