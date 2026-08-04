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
UILabels :: enum {
	None,
	Visual,
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
	label:          UILabels,
	game_object:    swd.Object_Name,
	progress_token: swd.Progress_Token,
	hitbox:         rl.Rectangle,
}
UIState :: struct {
	game:                          ^swd.Game,
	last_mouse_world_position:     [2]f32,
	ui_element_clicked_last_frame: UIElement,
	ui_element_list:               [dynamic; MAX_UI_ELEMENTS]UIElement,
	ui_element_list_dirty:         bool,
	valid_moves:                   [dynamic; 64]swd.Move,
	valid_moves_dirty:             bool,
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
			if rl.CheckCollisionPointRec(ui_state.last_mouse_world_position, ui_element.hitbox) {
				ui_state.ui_element_clicked_last_frame = ui_element
				break
			}
		}
		print_ui_element_name(ui_state.ui_element_clicked_last_frame)
		handle_click(ui_state.ui_element_clicked_last_frame, ui_state)
	}

	ui_state.last_mouse_world_position = rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)
}

object_chosen: Maybe(swd.Object_Name)
handle_click :: proc(ui_element_clicked: UIElement, ui_state: ^UIState) {
	selected_move: swd.Move
	switch ui_state.game.choice_state {
	case .Choose_Wonder_To_Draft:
		{
			for move in ui_state.valid_moves {
				if move.move_kind != .Draft_Wonder {continue}
				if move.wonder_name == ui_element_clicked.game_object {
					selected_move = move
					break
				}
			}
		}
	case .Choose_Object_To_Construct_Or_Discard:
		{
			if object_chosen == nil {
				if ui_element_clicked.label != .GameObject {break}
				for move in ui_state.valid_moves {
					if move.wonder_name == ui_element_clicked.game_object {
						object_chosen = move.wonder_name
						break
					}
					if move.card_name == ui_element_clicked.game_object {
						object_chosen = move.card_name
						break
					}
				}
			} else {
				if swd.objects_db[object_chosen.?].colour == .Wonder {
					for move in ui_state.valid_moves {
						if move.wonder_name == object_chosen &&
						   move.card_name == ui_element_clicked.game_object {
							selected_move = move
							break
						}
					}
				} else if ui_element_clicked.label == .DiscardForCoinConfirm {
					for move in ui_state.valid_moves {
						if move.move_kind == .Discard_For_Coins &&
						   move.card_name == object_chosen.? {
							selected_move = move
							break
						}
					}
				} else if ui_element_clicked.label == .ConstructCardConfirm {
					for move in ui_state.valid_moves {
						if move.move_kind == .Construct_Card && move.card_name == object_chosen.? {
							selected_move = move
							break
						}
					}
				}
				object_chosen = nil
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
		swd.execute_move(selected_move, ui_state.game)
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

draw_card_structure :: proc(midpoint: [2]f32, age: swd.Age, ui_state: ^UIState) {
	if age == .DraftWonders {
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
				texture_mid_pos := midpoint + grid_pos * (WONDER_SIZE / 2 + {2.0, 2.0})
				texture_top_left_pos := texture_mid_pos - WONDER_SIZE / 2
				draw_card_texture(wonder, texture_mid_pos, WONDER_SIZE)
				if ui_state.ui_element_list_dirty {
					append(
						&ui_state.ui_element_list,
						UIElement {
							label = .GameObject,
							game_object = wonder,
							hitbox = {
								texture_top_left_pos.x,
								texture_top_left_pos.y,
								WONDER_SIZE.x,
								WONDER_SIZE.y,
							},
						},
					)
				}
			} else {continue}
		}
	} else {
		y_offset: f32 = CARD_SIZE.y * 1.0 / 2.8
		x_offset: f32 = CARD_SIZE.x * 1.0 / 2.0 + 3
		layout_grid := card_structure_grids[age]
		for i := 19; i >= 0; i -= 1 {
			grid_pos := layout_grid[i]
			slot := ui_state.game.boards[age][i]
			texture_mid_pos: [2]f32 =
				midpoint + {f32(grid_pos.x), f32(grid_pos.y)} * {x_offset, y_offset}
			texture_top_left_pos := texture_mid_pos - CARD_SIZE / 2
			if slot.card_in_slot == {} {continue}
			if slot.face_up {
				draw_card_texture(slot.card_in_slot, texture_mid_pos, CARD_SIZE)
				if ui_state.ui_element_list_dirty {
					append(
						&ui_state.ui_element_list,
						UIElement {
							label = .GameObject,
							game_object = slot.card_in_slot,
							hitbox = {
								texture_top_left_pos.x,
								texture_top_left_pos.y,
								CARD_SIZE.x,
								CARD_SIZE.y,
							},
						},
					)
				}
			} else {
				card_back := object_texture_info_db[slot.card_in_slot].card_back
				draw_card_back(card_back, texture_mid_pos, CARD_SIZE)
			}
		}
	}
}

MILITARY_TRACK_SCALE: f32 : 1.2
MILITARY_TRACK_SIZE: [2]f32 : {780 * MILITARY_TRACK_SCALE, 240 * MILITARY_TRACK_SCALE}
MILITARY_TOKEN_SIZE: [2]f32 : {44 * MILITARY_TRACK_SCALE, 88 * MILITARY_TRACK_SCALE}
CONFLICT_PAWN_SIZE: [2]f32 = {36 * MILITARY_TRACK_SCALE, 72 * MILITARY_TRACK_SCALE}
PROGRESS_TOKEN_DIAMETER: f32 : 72 * MILITARY_TRACK_SCALE
draw_military_track :: proc(midpoint: [2]f32, ui_state: ^UIState) {
	rl.DrawTexturePro(
		military_track_texture,
		{0, 0, 3000, 900},
		{midpoint.x, midpoint.y, MILITARY_TRACK_SIZE.x, MILITARY_TRACK_SIZE.y},
		MILITARY_TRACK_SIZE / 2,
		0,
		rl.WHITE,
	)

	for token in ui_state.game.military_tokens_available {
		texture: rl.Texture2D
		position: [2]f32
		rotation: f32
		switch token {
		case .P1_2:
			{
				texture = military_token_2_texture
				position = midpoint + {-145, 73} * MILITARY_TRACK_SCALE
				rotation = -90
			}
		case .P1_5:
			{
				texture = military_token_5_texture
				position = midpoint + {-260, 73} * MILITARY_TRACK_SCALE
				rotation = -90
			}
		case .P2_2:
			{
				texture = military_token_2_texture
				position = midpoint + {145, 73} * MILITARY_TRACK_SCALE
				rotation = 90
			}
		case .P2_5:
			{
				texture = military_token_5_texture
				position = midpoint + {260, 73} * MILITARY_TRACK_SCALE
				rotation = 90
			}
		}
		rl.DrawTexturePro(
			texture,
			{0, 0, f32(texture.width), f32(texture.height)},
			{position.x, position.y, MILITARY_TOKEN_SIZE.x, MILITARY_TOKEN_SIZE.y},
			MILITARY_TOKEN_SIZE / 2,
			rotation,
			rl.WHITE,
		)
	}

	pawn_offset: f32 = f32(ui_state.game.military_track * 37) * MILITARY_TRACK_SCALE
	rl.DrawTexturePro(
		conflict_pawn_texture,
		{0, 0, f32(conflict_pawn_texture.width), f32(conflict_pawn_texture.height)},
		{
			midpoint.x + pawn_offset,
			midpoint.y + 15 * MILITARY_TRACK_SCALE,
			CONFLICT_PAWN_SIZE.x,
			CONFLICT_PAWN_SIZE.y,
		},
		CONFLICT_PAWN_SIZE / 2,
		0,
		rl.WHITE,
	)

	token_spacing: f32 = PROGRESS_TOKEN_DIAMETER + 4 * MILITARY_TRACK_SCALE
	token_size: [2]f32 = {PROGRESS_TOKEN_DIAMETER, PROGRESS_TOKEN_DIAMETER}
	token_offset: f32 = -2 * token_spacing
	for token in ui_state.game.progress_tokens_available {
		texture := progress_token_textures[token]
		texture_mid_pos: [2]f32 = {
			midpoint.x + token_offset,
			midpoint.y - 67 * MILITARY_TRACK_SCALE,
		}
		rl.DrawTexturePro(
			texture,
			{0, 0, f32(texture.width), f32(texture.height)},
			{
				texture_mid_pos.x,
				texture_mid_pos.y,
				PROGRESS_TOKEN_DIAMETER,
				PROGRESS_TOKEN_DIAMETER,
			},
			token_size / 2,
			180,
			rl.WHITE,
		)
		if ui_state.ui_element_list_dirty {
			texture_top_left_pos := texture_mid_pos - token_size / 2
			hitbox_rect: rl.Rectangle = {
				texture_top_left_pos.x,
				texture_top_left_pos.y,
				PROGRESS_TOKEN_DIAMETER,
				PROGRESS_TOKEN_DIAMETER,
			}
			append(
				&ui_state.ui_element_list,
				UIElement{label = .ProgressToken, progress_token = token, hitbox = hitbox_rect},
			)
		}
		token_offset += token_spacing
	}
}

COIN_DIAMETER: f32 : 110
COIN_FONT_SIZE: i32 : 90
COIN_FONT_OUTLINE_SIZE: f32 : 4
coin_font: rl.Font
draw_player_coins :: proc(position: [2]f32, player: swd.Player_ID, ui_state: ^UIState) {
	rl.DrawTexturePro(
		coin_texture,
		{0, 0, f32(coin_texture.width), f32(coin_texture.height)},
		{position.x, position.y, COIN_DIAMETER, COIN_DIAMETER},
		{COIN_DIAMETER / 2, COIN_DIAMETER / 2},
		0,
		rl.WHITE,
	)
	if ui_state.ui_element_list_dirty {
		texture_top_left_pos := position - {COIN_DIAMETER / 2, COIN_DIAMETER / 2}
		hitbox_rect: rl.Rectangle = {
			texture_top_left_pos.x,
			texture_top_left_pos.y,
			COIN_DIAMETER,
			COIN_DIAMETER,
		}
		append(
			&ui_state.ui_element_list,
			UIElement{label = .DiscardForCoinConfirm, hitbox = hitbox_rect},
		)
	}
	COIN_FONT_SIZE: i32 = 90
	offsets: [4][2]f32 = {
		{-COIN_FONT_OUTLINE_SIZE, -COIN_FONT_OUTLINE_SIZE},
		{COIN_FONT_OUTLINE_SIZE, -COIN_FONT_OUTLINE_SIZE},
		{-COIN_FONT_OUTLINE_SIZE, COIN_FONT_OUTLINE_SIZE},
		{COIN_FONT_OUTLINE_SIZE, COIN_FONT_OUTLINE_SIZE},
	}
	value: cstring = fmt.ctprintf("%d", ui_state.game.player_states[player].coins)
	textSize := rl.MeasureTextEx(coin_font, value, f32(COIN_FONT_SIZE), 0)
	textPosition := position - textSize / 2
	textColour := rl.WHITE
	borderColour := rl.BLACK
	for offset in offsets {
		rl.DrawTextEx(
			coin_font,
			value,
			textPosition - offset,
			f32(COIN_FONT_SIZE),
			0,
			borderColour,
		)
	}
	rl.DrawTextEx(coin_font, value, textPosition, f32(COIN_FONT_SIZE), 0, textColour)
}

game_object_sort :: proc(i, j: swd.Object_Name) -> bool {
	return i32(i) < i32(j)
}

draw_player_wonders :: proc(ui_state: ^UIState) {
	gap: f32 = 5
	p1_wonders := swd.get_all_player_wonders(ui_state.game.player_states[.P1])
	slice.sort_by(p1_wonders[:], game_object_sort)
	for wonder, i in p1_wonders {
		row, col := math.divmod(i, 2)
		x := WONDER_SIZE.x / 2 + f32(col) * (WONDER_SIZE.x + gap) + 5
		y := WONDER_SIZE.y / 2 + f32(row) * (WONDER_SIZE.y + gap) + 5
		draw_card_texture(wonder, {x, y}, WONDER_SIZE)
		if ui_state.ui_element_list_dirty {
			ui_element := UIElement {
				label       = .GameObject,
				game_object = wonder,
				hitbox      = {x, y, WONDER_SIZE.x, WONDER_SIZE.y},
			}
			append(&ui_state.ui_element_list, ui_element)
		}
	}
	p2_wonders := swd.get_all_player_wonders(ui_state.game.player_states[.P2])
	slice.sort_by(p2_wonders[:], game_object_sort)
	for wonder, i in p2_wonders {
		row, col := math.divmod(i, 2)
		x := WONDER_SIZE.x / 2 + f32(col) * (WONDER_SIZE.x + gap) + 5
		x += STARTING_WINDOW_WIDTH - (2 * WONDER_SIZE.x + gap) - 5
		y := WONDER_SIZE.y / 2 + f32(row) * (WONDER_SIZE.y + gap) + 5
		draw_card_texture(wonder, {x, y}, WONDER_SIZE)
		if ui_state.ui_element_list_dirty {
			ui_element := UIElement {
				label       = .GameObject,
				game_object = wonder,
				hitbox      = {x, y, WONDER_SIZE.x, WONDER_SIZE.y},
			}
			append(&ui_state.ui_element_list, ui_element)
		}
	}
}

draw_frame :: proc(ui_state: ^UIState) {
	rl.BeginDrawing()
	rl.ClearBackground(BACKGROUND_COLOUR)
	rl.BeginMode2D(camera)

	if ui_state.ui_element_list_dirty {
		clear(&ui_state.ui_element_list)
	}
	if ui_state.valid_moves_dirty {
		ui_state.valid_moves_dirty = false
		ui_state.valid_moves = swd.get_valid_moves(ui_state.game^)
	}

	card_structure_midpoint: [2]f32 = {STARTING_WINDOW_WIDTH / 2, 1.57 * CARD_SIZE.y + 5}
	draw_card_structure(card_structure_midpoint, ui_state.game.age, ui_state)

	military_track_midpoint: [2]f32 = {
		STARTING_WINDOW_WIDTH / 2,
		STARTING_WINDOW_HEIGHT - MILITARY_TRACK_SIZE.y / 2,
	}
	draw_military_track(military_track_midpoint, ui_state)

	coin_x_offset := MILITARY_TRACK_SIZE.x / 2 + COIN_DIAMETER * 2
	coin_y := STARTING_WINDOW_HEIGHT - COIN_DIAMETER
	p1_coin_position: [2]f32 = {STARTING_WINDOW_WIDTH / 2 - coin_x_offset, coin_y}
	p2_coin_position: [2]f32 = {STARTING_WINDOW_WIDTH / 2 + coin_x_offset, coin_y}
	draw_player_coins(p1_coin_position, .P1, ui_state)
	draw_player_coins(p2_coin_position, .P2, ui_state)

	draw_player_wonders(ui_state)

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

