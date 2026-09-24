package seven_wonders_duel

import "core:fmt"
import "core:math"
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
	//engine related objects
	game_object:     swd.Object_Name,
	progress_token:  swd.Progress_Token,
	//text
	text:            cstring,
	font:            rl.Font,
	font_size:       f32,
	text_colour:     rl.Color,
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
draw_element :: proc(ui_element: UIElement) {
	if ui_element.label == .None {return}
	if ui_element.label == .GameObject {
		draw_card_texture(ui_element.game_object, ui_element.dest_midpoint, ui_element.dest_size)
	} else if ui_element.label == .Text {
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
		rl.DrawTexturePro(
			ui_element.texture,
			source_rect,
			dest_rect,
			ui_element.dest_size / 2,
			ui_element.rotation,
			rl.WHITE,
		)
	}
}
UIState :: struct {
	game:                          ^swd.Game,
	last_mouse_world_position:     [2]f32,
	ui_element_clicked_last_frame: UIElement,
	ui_element_list:               [dynamic; MAX_UI_ELEMENTS]UIElement,
	ui_element_list_dirty:         bool,
	valid_moves:                   [dynamic; 64]swd.Move,
	valid_moves_dirty:             bool,
	last_selected_object:          Maybe(swd.Object_Name),
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
		ui_state.ui_element_list_dirty = true
		ui_state.game.age = .DraftWonders
	}
	if rl.IsKeyReleased(.W) {
		ui_state.ui_element_list_dirty = true
		ui_state.game.age = .Age1
	}
	if rl.IsKeyReleased(.E) {
		ui_state.ui_element_list_dirty = true
		ui_state.game.age = .Age2
	}
	if rl.IsKeyReleased(.R) {
		ui_state.ui_element_list_dirty = true
		ui_state.game.age = .Age3
	}
	if rl.IsKeyReleased(.S) {
		ui_state.ui_element_list_dirty = true
		ui_state.game.military_track -= 1
	}
	if rl.IsKeyReleased(.D) {
		ui_state.ui_element_list_dirty = true
		ui_state.game.military_track += 1
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
						ui_state.ui_element_list_dirty = true
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
						ui_state.ui_element_list_dirty = true
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
		ui_state.ui_element_list_dirty = true
		ui_state.valid_moves_dirty = true
	}
}


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

CARD_SIZE: [2]f32 : {120, 190}
WONDER_SIZE: [2]f32 : {225 * 1.25, 135 * 1.25}

game_object_sort :: proc(i, j: swd.Object_Name) -> bool {
	return i32(i) < i32(j)
}


CARD_STRUCTURE_MIDPOINT: [2]f32 : {STARTING_WINDOW_WIDTH / 2, 1.57 * CARD_SIZE.y + 5}
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
				UIElement {
					label = .GameObject,
					game_object = wonder,
					hitbox_midpoint = midpoint,
					hitbox_size = WONDER_SIZE,
					dest_midpoint = midpoint,
					dest_size = WONDER_SIZE,
				},
			)
		}
	}
}

append_card_structure_elements :: proc(ui_state: ^UIState) {
	if ui_state.game.age == .DraftWonders {return}
	y_offset: f32 = CARD_SIZE.y * 1.0 / 2.8
	x_offset: f32 = CARD_SIZE.x * 1.0 / 2.0 + 3
	layout_grid := card_structure_grids[ui_state.game.age]
	for i := 19; i >= 0; i -= 1 {
		grid_pos := layout_grid[i]
		slot := ui_state.game.boards[ui_state.game.age][i]
		midpoint: [2]f32 =
			CARD_STRUCTURE_MIDPOINT + {f32(grid_pos.x), f32(grid_pos.y)} * {x_offset, y_offset}
		if slot.card_in_slot == {} {continue}
		if slot.face_up {
			append(
				&ui_state.ui_element_list,
				UIElement {
					label = .GameObject,
					game_object = slot.card_in_slot,
					dest_midpoint = midpoint,
					dest_size = CARD_SIZE,
					hitbox_midpoint = midpoint,
					hitbox_size = CARD_SIZE,
				},
			)
		} else {
			back := object_texture_info_db[slot.card_in_slot].card_back
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
	for wonder, i in ui_state.game.player_states[.P1].wonders {
		row, col := math.divmod(i, 2)
		x := WONDER_SIZE.x / 2 + f32(col) * (WONDER_SIZE.x + gap) + 5
		y := WONDER_SIZE.y / 2 + f32(row) * (WONDER_SIZE.y + gap) + 5
		append(
			&ui_state.ui_element_list,
			UIElement {
				label = .GameObject,
				game_object = wonder,
				dest_midpoint = {x, y},
				dest_size = WONDER_SIZE,
				hitbox_midpoint = {x, y},
				hitbox_size = WONDER_SIZE,
			},
		)
		if int(ui_state.game.player_states[.P1].cards_tucked[i]) != 0 {
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
	}
	for wonder, i in ui_state.game.player_states[.P2].wonders {
		row, col := math.divmod(i, 2)
		x := WONDER_SIZE.x / 2 + f32(col) * (WONDER_SIZE.x + gap) + 5
		x += STARTING_WINDOW_WIDTH - (2 * WONDER_SIZE.x + gap) - 5
		y := WONDER_SIZE.y / 2 + f32(row) * (WONDER_SIZE.y + gap) + 5
		append(
			&ui_state.ui_element_list,
			UIElement {
				label = .GameObject,
				game_object = wonder,
				dest_midpoint = {x, y},
				dest_size = WONDER_SIZE,
				hitbox_midpoint = {x, y},
				hitbox_size = WONDER_SIZE,
			},
		)
		if int(ui_state.game.player_states[.P2].cards_tucked[i]) != 0 {
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
	}
}

append_player_card_elements :: proc(ui_state: ^UIState) {

}

COIN_DIAMETER: f32 : 110
COIN_FONT_SIZE: f32 : 90
COIN_FONT_OUTLINE_SIZE: f32 : 4
COIN_FONT_COLOUR: rl.Color : rl.WHITE
main_font: rl.Font
append_player_coin_elements :: proc(ui_state: ^UIState) {
	coin_x_offset := MILITARY_TRACK_SIZE.x / 3 + 20
	coin_y := STARTING_WINDOW_HEIGHT - 2.3 * COIN_DIAMETER
	p1_label: UILabel = .Visual
	p2_label: UILabel = .Visual
	switch ui_state.game.turn_player {
	case .P1:
		{p1_label = .DiscardForCoinConfirm}
	case .P2:
		{p2_label = .DiscardForCoinConfirm}
	}

	p1_coin_position: [2]f32 = {STARTING_WINDOW_WIDTH / 2 - coin_x_offset, coin_y}
	append(
		&ui_state.ui_element_list,
		UIElement {
			label = p1_label,
			texture = coin_texture,
			dest_midpoint = p1_coin_position,
			dest_size = {COIN_DIAMETER, COIN_DIAMETER},
			hitbox_midpoint = p1_coin_position,
			hitbox_size = {COIN_DIAMETER, COIN_DIAMETER},
		},
	)
	append(
		&ui_state.ui_element_list,
		UIElement {
			label = .Text,
			text = fmt.ctprintf("%d", ui_state.game.player_states[.P1].coins),
			font = main_font,
			font_size = COIN_FONT_SIZE,
			text_colour = COIN_FONT_COLOUR,
			dest_midpoint = p1_coin_position,
		},
	)

	p2_coin_position: [2]f32 = {STARTING_WINDOW_WIDTH / 2 + coin_x_offset, coin_y}
	append(
		&ui_state.ui_element_list,
		UIElement {
			label = p2_label,
			texture = coin_texture,
			dest_midpoint = p2_coin_position,
			dest_size = {COIN_DIAMETER, COIN_DIAMETER},
			hitbox_midpoint = p2_coin_position,
			hitbox_size = {COIN_DIAMETER, COIN_DIAMETER},
		},
	)
	append(
		&ui_state.ui_element_list,
		UIElement {
			label = .Text,
			text = fmt.ctprintf("%d", ui_state.game.player_states[.P2].coins),
			font = main_font,
			font_size = COIN_FONT_SIZE,
			text_colour = COIN_FONT_COLOUR,
			dest_midpoint = p2_coin_position,
		},
	)
}

append_build_icon_elements :: proc(ui_state: ^UIState) {
	if ui_state.last_selected_object == nil {return}
	icon_x_offset := MILITARY_TRACK_SIZE.x / 3 + 20
	icon_y := STARTING_WINDOW_HEIGHT - 3.5 * COIN_DIAMETER
	icon_position: [2]f32
	switch ui_state.game.turn_player {
	case .P1:
		{icon_position = {STARTING_WINDOW_WIDTH / 2 - icon_x_offset, icon_y}}
	case .P2:
		{icon_position = {STARTING_WINDOW_WIDTH / 2 + icon_x_offset, icon_y}}
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
		},
	)
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
	if !ui_state.ui_element_list_dirty {return}
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

	if ui_state.valid_moves_dirty {
		ui_state.valid_moves_dirty = false
		ui_state.valid_moves = swd.get_valid_moves(ui_state.game^)
	}

	update_ui_element_list(ui_state)
	for element in ui_state.ui_element_list {draw_element(element)}

	for col in 0 ..< 4 {
		x := CARD_SIZE.x / 2 + f32(col) * CARD_SIZE.x + 50
		for row in 0 ..< 8 {
			y := WONDER_SIZE.y * 2 + 25 + f32(row + 2) * CARD_SIZE.y / 4
			draw_card_back(.Age1, {x, y}, CARD_SIZE)
		}
	}

	ui_state.valid_moves_dirty = false

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
		game                  = &game,
		ui_element_list_dirty = true,
		valid_moves_dirty     = true,
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
		draw_frame(&ui_state)
		free_all(context.temp_allocator)
	}
}

