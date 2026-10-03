package seven_wonders_duel

import "core:fmt"
import "core:math"
import linalg "core:math/linalg"
import "core:mem"
import "core:slice"
import swd "swd_engine"
import rl "vendor:raylib"

STARTING_WINDOW_WIDTH, STARTING_WINDOW_HEIGHT :: 1920, 1080
get_screen_centre :: proc() -> [2]f32 {
	return {f32(rl.GetScreenWidth()) / 2, f32(rl.GetScreenHeight()) / 2}
}

MAX_FPS :: 120
BACKGROUND_COLOUR: rl.Color : {76, 53, 83, 255}

camera: rl.Camera2D
window_setup :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT} | {.WINDOW_RESIZABLE})
	rl.InitWindow(STARTING_WINDOW_WIDTH, STARTING_WINDOW_HEIGHT, "7 Wonders Duel")
	rl.SetTargetFPS(MAX_FPS)
	camera.offset = {STARTING_WINDOW_WIDTH / 2, STARTING_WINDOW_HEIGHT / 2}
	camera.target = {STARTING_WINDOW_WIDTH / 2, STARTING_WINDOW_HEIGHT / 2}
	camera.zoom = 1
}

MAX_UI_ELEMENTS :: 256
UILabel :: enum {
	None,
	Visual,
	Text,
	GameObject,
	ProgressToken,
	ShowDiscard,
	ShowLog,
	ShowMenu,
	DiscardForCoinConfirm,
	ConstructCardConfirm,
	SelectP1,
	SelectP2,
}
UIElement :: struct {
	label:           UILabel,
	dest_midpoint:   [2]f32,
	dest_size:       [2]f32,
	hitbox_midpoint: [2]f32,
	hitbox_size:     [2]f32,
	rotation:        f32,
	//texture data
	texture:         rl.Texture2D,
	source_rect:     rl.Rectangle,
	tint:            Maybe(rl.Color),
	//shader parameters
	border_width:    f32,
	border_colour:   rl.Color,
	corner_radius:   f32,
	//text
	text:            cstring,
	font:            rl.Font,
	font_size:       f32,
	text_colour:     rl.Color,
	//engine related objects
	game_object:     swd.Object_Name,
	progress_token:  swd.Progress_Token,
}
get_hitbox :: proc(ui_element: UIElement) -> rl.Rectangle {
	hitbox_topleft := ui_element.hitbox_midpoint - ui_element.hitbox_size / 2
	hitbox: rl.Rectangle = {
		x      = hitbox_topleft.x,
		y      = hitbox_topleft.y,
		width  = ui_element.hitbox_size.x,
		height = ui_element.hitbox_size.y,
	}
	return hitbox
}

SELECTION_COLOUR: rl.Color : rl.YELLOW
PLAYER_COLOUR: #sparse[swd.Player_ID]rl.Color = {
	.P1 = rl.BLUE,
	.P2 = rl.RED,
}

draw_element :: proc(ui_element: UIElement) {
	tint := ui_element.tint.? or_else rl.WHITE
	if ui_element.label == .None {return}
	if ui_element.label == .Text {
		text_size := rl.MeasureTextEx(ui_element.font, ui_element.text, ui_element.font_size, 0)
		text_position := ui_element.dest_midpoint - text_size / 2
		rl.DrawTextEx(
			ui_element.font,
			ui_element.text,
			text_position,
			ui_element.font_size,
			0,
			ui_element.text_colour,
		)
	} else {
		source_rect := ui_element.source_rect
		if source_rect == {0, 0, 0, 0} {
			source_rect = {0, 0, f32(ui_element.texture.width), f32(ui_element.texture.height)}
		}
		dest_rect: rl.Rectangle = {
			ui_element.dest_midpoint.x,
			ui_element.dest_midpoint.y,
			ui_element.dest_size.x,
			ui_element.dest_size.y,
		}
		if ui_element.border_width + ui_element.corner_radius > 0 {
			rl.BeginShaderMode(rounded_rect_shader)
			sub_rect_uv_bounds := get_sub_rect_uv_bounds(ui_element.texture, source_rect)
			corner_radius := ui_element.corner_radius
			border_width := ui_element.border_width
			border_colour := linalg.array_cast(ui_element.border_colour, f32) / 255.0
			rl.SetShaderValue(
				rounded_rect_shader,
				rounded_rect_shader_sprite_uv_bounds_loc,
				&sub_rect_uv_bounds,
				.VEC4,
			)
			rl.SetShaderValue(
				rounded_rect_shader,
				rounded_rect_shader_radius_loc,
				&corner_radius,
				.FLOAT,
			)
			rl.SetShaderValue(
				rounded_rect_shader,
				rounded_rect_shader_border_width_loc,
				&border_width,
				.FLOAT,
			)
			rl.SetShaderValue(
				rounded_rect_shader,
				rounded_rect_shader_border_color_loc,
				&border_colour,
				.VEC4,
			)
		}
		rl.DrawTexturePro(
			ui_element.texture,
			source_rect,
			dest_rect,
			ui_element.dest_size / 2,
			ui_element.rotation,
			tint,
		)
		if ui_element.border_width + ui_element.corner_radius > 0 {
			rl.EndShaderMode()
		}
	}
}

UIState :: struct {
	game:                          ^swd.Game,
	last_mouse_world_position:     [2]f32,
	ui_element_clicked_last_frame: UIElement,
	ui_element_list:               [dynamic; MAX_UI_ELEMENTS]UIElement,
	valid_moves:                   [dynamic; 64]swd.Move,
	valid_moves_dirty:             bool,
	last_selected_object:          Maybe(swd.Object_Name),
	object_costs:                  #sparse[swd.Player_ID][swd.Object_Name]swd.Object_Real_Cost,
	cost_overlay_on:               bool,
}
print_ui_element_name :: proc(ui_element: UIElement) {
	#partial switch ui_element.label {
	case .GameObject:
		fmt.println(ui_element.game_object)
	case .ProgressToken:
		fmt.println(ui_element.progress_token)
	case:
		{}
	}
}

handle_input :: proc(ui_state: ^UIState) {
	if rl.IsKeyReleased(.Q) {
		ui_state.game.age = .DraftWonders
		ui_state.valid_moves_dirty = true
	}
	if rl.IsKeyReleased(.W) {
		ui_state.game.age = .Age1
		ui_state.valid_moves_dirty = true
	}
	if rl.IsKeyReleased(.E) {
		ui_state.game.age = .Age2
		ui_state.valid_moves_dirty = true
	}
	if rl.IsKeyReleased(.R) {
		ui_state.game.age = .Age3
		ui_state.valid_moves_dirty = true
	}
	if rl.IsKeyReleased(.S) {
		ui_state.game.military_track -= 1
		ui_state.valid_moves_dirty = true
	}
	if rl.IsKeyReleased(.D) {
		ui_state.game.military_track += 1
		ui_state.valid_moves_dirty = true
	}
	if rl.IsKeyReleased(.TAB) {
		ui_state.cost_overlay_on = !ui_state.cost_overlay_on
	}

	ui_state.ui_element_clicked_last_frame = {}
	if rl.IsMouseButtonReleased(.LEFT) {
		fmt.println(ui_state.last_mouse_world_position)
		#reverse for ui_element in ui_state.ui_element_list {
			if rl.CheckCollisionPointRec(
				ui_state.last_mouse_world_position,
				get_hitbox(ui_element),
			) {
				ui_state.ui_element_clicked_last_frame = ui_element
				break
			}
		}
		print_ui_element_name(ui_state.ui_element_clicked_last_frame)
		handle_click(ui_state.ui_element_clicked_last_frame, ui_state)
	}

	ui_state.last_mouse_world_position = rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)
}

handle_click :: proc(ui_element_clicked: UIElement, ui_state: ^UIState) {
	selected_move: swd.Move
	switch ui_state.game.choice_state {
	case .Choose_Wonder_To_Draft:
		{
			for move in ui_state.valid_moves {
				if move.wonder_name == ui_element_clicked.game_object {
					selected_move = move
					break
				}
			}
		}
	case .Choose_Object_To_Construct_Or_Discard:
		{
			#partial switch ui_element_clicked.label {
			case .GameObject:
				{
					selected_object := ui_element_clicked.game_object

					if swd.game_object_is_card(selected_object) {
						ui_state.last_selected_object = selected_object
					}

					if swd.game_object_is_wonder(selected_object) {
						for move in ui_state.valid_moves {
							if move.wonder_name == selected_object &&
							   move.card_name == ui_state.last_selected_object {
								selected_move = move
								break
							}
						}
					}
				}
			case .DiscardForCoinConfirm:
				{
					for move in ui_state.valid_moves {
						if move.card_name == ui_state.last_selected_object &&
						   move.move_kind == .Discard_For_Coins {
							selected_move = move
							break
						}
					}
				}
			case .ConstructCardConfirm:
				{
					for move in ui_state.valid_moves {
						if move.card_name == ui_state.last_selected_object &&
						   move.move_kind == .Construct_Card {
							selected_move = move
							break
						}
					}
				}
			case:
				{
					if ui_state.last_selected_object != nil {
						ui_state.last_selected_object = nil
					}
				}
			}
		}
	case .Choose_Progress_Token:
		{}
	case .Choose_Unavailable_Progress_Token:
		{}
	case .Choose_Brown_Card_To_Destroy:
		{}
	case .Choose_Grey_Card_To_Destroy:
		{}
	case .Choose_Card_To_Revive:
		{}
	case .Choose_First_Player:
		{}
	}
	if selected_move.move_kind != .None {
		swd.execute_move_safe(selected_move, ui_state.game)
		ui_state.last_selected_object = nil
		ui_state.valid_moves_dirty = true
	}
}


CARD_SIZE: [2]f32 : {120, 190}
WONDER_SIZE: [2]f32 : {225 * 1.25, 135 * 1.25}
create_game_object_ui_element :: proc(
	game_object: swd.Object_Name,
	dest_midpoint: [2]f32,
	rotation: f32 = 0,
	tint: rl.Color = rl.WHITE,
	border_width: f32 = 0,
	border_colour: rl.Color = rl.WHITE,
) -> UIElement {
	dest_size: [2]f32
	element := UIElement {
		label           = .GameObject,
		game_object     = game_object,
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
		element.dest_size = CARD_SIZE
		element.hitbox_size = CARD_SIZE
	} else {
		element.dest_size = WONDER_SIZE
		element.hitbox_size = WONDER_SIZE
	}
	return element
}

create_text_ui_element :: proc(
	text: cstring,
	size: f32,
	dest_midpoint: [2]f32,
	colour: rl.Color,
	font: Maybe(rl.Font) = nil,
) -> (
	element: UIElement,
) {
	element.label = .Text
	element.dest_midpoint = dest_midpoint
	element.text = text
	element.font_size = size
	element.text_colour = colour
	element.font = font.? or_else main_font
	return
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


CARD_STRUCTURE_MIDPOINT: [2]f32 : {STARTING_WINDOW_WIDTH / 2, 1.57 * CARD_SIZE.y + 5}
card_structure_grids: [swd.Age][20][2]int = #partial {
	.Age1 = {
		{-5, 2},
		{-3, 2},
		{-1, 2},
		{1, 2},
		{3, 2},
		{5, 2},
		{-4, 1},
		{-2, 1},
		{0, 1},
		{2, 1},
		{4, 1},
		{-3, 0},
		{-1, 0},
		{1, 0},
		{3, 0},
		{-2, -1},
		{0, -1},
		{2, -1},
		{-1, -2},
		{1, -2},
	},
	.Age2 = {
		{-1, 2},
		{1, 2},
		{-2, 1},
		{0, 1},
		{2, 1},
		{-3, 0},
		{-1, 0},
		{1, 0},
		{3, 0},
		{-4, -1},
		{-2, -1},
		{0, -1},
		{2, -1},
		{4, -1},
		{-5, -2},
		{-3, -2},
		{-1, -2},
		{1, -2},
		{3, -2},
		{5, -2},
	},
	.Age3 = {
		{-1, 3},
		{1, 3},
		{-2, 2},
		{0, 2},
		{2, 2},
		{-3, 1},
		{-1, 1},
		{1, 1},
		{3, 1},
		{-2, 0},
		{2, 0},
		{-3, -1},
		{-1, -1},
		{1, -1},
		{3, -1},
		{-2, -2},
		{0, -2},
		{2, -2},
		{-1, -3},
		{1, -3},
	},
}

append_card_structure_elements :: proc(ui_state: ^UIState) {
	if ui_state.game.age == .DraftWonders {return}
	y_offset: f32 = CARD_SIZE.y * 1.0 / 2.8
	x_offset: f32 = CARD_SIZE.x * 1.0 / 2.0 + 3
	layout_grid := card_structure_grids[ui_state.game.age]
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
						label = .Visual,
						texture = coin_texture,
						dest_midpoint = midpoint,
						dest_size = 40,
					},
				)
				append(
					&ui_state.ui_element_list,
					UIElement {
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
				)
			}
		} else {
			back := object_texture_info_db[card.?].game_object_back
			back_texture := card_back_textures[back]
			append(
				&ui_state.ui_element_list,
				UIElement {
					label = .Visual,
					texture = back_texture,
					dest_midpoint = midpoint,
					dest_size = CARD_SIZE,
					hitbox_midpoint = midpoint,
					hitbox_size = CARD_SIZE,
					corner_radius = 50,
				},
			)
		}
	}
}

MILITARY_TRACK_SCALE: f32 : 1.2
MILITARY_TRACK_SIZE: [2]f32 : {780 * MILITARY_TRACK_SCALE, 240 * MILITARY_TRACK_SCALE}
MILITARY_TRACK_MIDPOINT: [2]f32 : {
	STARTING_WINDOW_WIDTH / 2,
	STARTING_WINDOW_HEIGHT - MILITARY_TRACK_SIZE.y / 2,
}
MILITARY_TOKEN_SIZE: [2]f32 : {44 * MILITARY_TRACK_SCALE, 88 * MILITARY_TRACK_SCALE}
CONFLICT_PAWN_SIZE: [2]f32 = {36 * MILITARY_TRACK_SCALE, 72 * MILITARY_TRACK_SCALE}
PROGRESS_TOKEN_DIAMETER: f32 : 72 * MILITARY_TRACK_SCALE
append_military_track_elements :: proc(ui_state: ^UIState) {
	//the track itself
	append(
		&ui_state.ui_element_list,
		UIElement {
			label = .Visual,
			texture = military_track_texture,
			dest_midpoint = MILITARY_TRACK_MIDPOINT,
			dest_size = MILITARY_TRACK_SIZE,
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
				label = .Visual,
				texture = token_texture,
				dest_midpoint = token_midpoint,
				dest_size = MILITARY_TOKEN_SIZE,
				rotation = token_rotation,
			},
		)
	}
	//draw the conflict pawn
	pawn_offset: f32 = f32(ui_state.game.military_track * 37) * MILITARY_TRACK_SCALE
	append(
		&ui_state.ui_element_list,
		UIElement {
			label = .Visual,
			texture = conflict_pawn_texture,
			dest_midpoint = MILITARY_TRACK_MIDPOINT + {pawn_offset, 15 * MILITARY_TRACK_SCALE},
			dest_size = CONFLICT_PAWN_SIZE,
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
				label = .ProgressToken,
				progress_token = token_to_draw,
				texture = progress_token_textures[token_to_draw],
				dest_midpoint = token_midpoint,
				dest_size = token_size,
				hitbox_midpoint = token_midpoint,
				hitbox_size = token_size,
				rotation = 180,
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
							label = .Visual,
							texture = built_icon_texture,
							dest_midpoint = {x, y},
							dest_size = 50,
						},
					)
				}
			case !seven_wonders_built && ui_state.cost_overlay_on:
				{
					append(
						&ui_state.ui_element_list,
						UIElement {
							label = .Visual,
							texture = coin_texture,
							dest_midpoint = {x, y},
							dest_size = 40,
						},
					)
					append(
						&ui_state.ui_element_list,
						UIElement {
							label = .Text,
							dest_midpoint = {x, y},
							text = fmt.ctprintf("%d", wonder_cost.total_coin_cost),
							font = main_font,
							font_size = 30,
							text_colour = rl.WHITE,
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
			case 1 ..< 20:
				{curr_col = 0}
			case 20 ..< 41:
				{curr_col = 1}
			case 41 ..< 55:
				{curr_col = 2}
			case 55 ..< len(swd.Object_Name) + 1:
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

COIN_DIAMETER: f32 : 110
COIN_FONT_SIZE: f32 : 90
COIN_FONT_OUTLINE_SIZE: f32 : 4
COIN_FONT_COLOUR: rl.Color : rl.WHITE
main_font: rl.Font
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
		label: UILabel = .Visual
		border_width: f32
		if ui_state.game.turn_player == player {
			label = .DiscardForCoinConfirm
			border_width = 4.0
		}
		append(
			&ui_state.ui_element_list,
			UIElement {
				label = label,
				texture = coin_texture,
				dest_midpoint = coin_position,
				dest_size = {COIN_DIAMETER, COIN_DIAMETER},
				hitbox_midpoint = coin_position,
				hitbox_size = {COIN_DIAMETER, COIN_DIAMETER},
				border_width = border_width,
				border_colour = PLAYER_COLOUR[player],
				corner_radius = f32(coin_texture.height / 2),
			},
		)
		append(
			&ui_state.ui_element_list,
			UIElement {
				label = .Text,
				text = fmt.ctprintf("%d", ui_state.game.player_states[player].coins),
				font = main_font,
				font_size = COIN_FONT_SIZE,
				text_colour = COIN_FONT_COLOUR,
				dest_midpoint = coin_position,
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
				label = .ConstructCardConfirm,
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
		)
		if display_cost {
			append(
				&ui_state.ui_element_list,
				UIElement {
					label = .Text,
					text = fmt.ctprintf("-%d", build_cost.total_coin_cost),
					font = main_font,
					font_size = 70,
					text_colour = text_colour,
					dest_midpoint = icon_position,
				},
			)
		}
	}
}

append_turn_player_text :: proc(ui_state: ^UIState) {
	turn_player_text: cstring
	text_x_offset := MILITARY_TRACK_SIZE.x / 2 + COIN_DIAMETER * 2.75
	text_y := STARTING_WINDOW_HEIGHT - COIN_DIAMETER
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
			label = .Text,
			text = turn_player_text,
			font = main_font,
			font_size = 60,
			text_colour = text_colour,
			dest_midpoint = text_midpoint,
		},
	)
}

update_ui_element_list :: proc(ui_state: ^UIState) {
	clear(&ui_state.ui_element_list)
	append_wonder_draft_elements(ui_state)
	append_player_wonder_elements(ui_state)
	append_card_structure_elements(ui_state)
	append_military_track_elements(ui_state)
	append_player_coin_elements(ui_state)
	append_build_icon_elements(ui_state)
	append_player_card_elements(ui_state)
	append_turn_player_text(ui_state)
}

draw_frame :: proc(ui_state: ^UIState) {
	rl.BeginDrawing()
	rl.ClearBackground(BACKGROUND_COLOUR)
	rl.BeginMode2D(camera)

	for element in ui_state.ui_element_list {draw_element(element)}


	rl.EndMode2D()
	rl.EndDrawing()
}

main :: proc() {
	// tracking allocator
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				fmt.eprintf("=== %v allocation(s) not freed: ===\n", len(track.allocation_map))
				for _, entry in track.allocation_map {
					fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
				}
			}
			if len(track.bad_free_array) > 0 {
				fmt.eprintf("=== %v incorrect frees: ===\n", len(track.bad_free_array))
				for entry in track.bad_free_array {
					fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	game := swd.create_new_game(rng_seed = 1778252334733313400)
	ui_state: UIState = {
		game              = &game,
		valid_moves_dirty = true,
		cost_overlay_on   = true,
	}

	window_setup()
	load_textures()
	load_shaders()

	for !rl.WindowShouldClose() {
		handle_input(&ui_state)
		if rl.IsWindowResized() {
			camera.zoom = min(
				f32(rl.GetScreenWidth()) / f32(STARTING_WINDOW_WIDTH),
				f32(rl.GetScreenHeight()) / f32(STARTING_WINDOW_HEIGHT),
			)
			camera.offset = get_screen_centre()
		}
		if ui_state.valid_moves_dirty {
			for player in swd.Player_ID {
				ui_state.object_costs[player] = swd.get_all_object_costs(ui_state.game^, player)
			}
			ui_state.valid_moves = swd.get_valid_moves(ui_state.game^)
			ui_state.valid_moves_dirty = false
		}

		update_ui_element_list(&ui_state)
		draw_frame(&ui_state)
		free_all(context.temp_allocator)
	}
}

