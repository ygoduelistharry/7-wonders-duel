package swd_ui

import "core:fmt"
import "core:mem"
import ui "my_ui"
import swd "swd_engine"
import rl "vendor:raylib"

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

	init_ui()

	for !rl.WindowShouldClose() {
		handle_input(&ui_state)
		if rl.IsWindowResized() {
			camera.zoom = min(
				f32(rl.GetScreenWidth()) / f32(STARTING_WINDOW_WIDTH),
				f32(rl.GetScreenHeight()) / f32(STARTING_WINDOW_HEIGHT),
			)
			camera.offset = {f32(rl.GetScreenWidth()) / 2, f32(rl.GetScreenHeight()) / 2}
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

camera: rl.Camera2D
init_ui :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT} | {.WINDOW_RESIZABLE})
	rl.InitWindow(STARTING_WINDOW_WIDTH, STARTING_WINDOW_HEIGHT, "7 Wonders Duel")
	rl.SetTargetFPS(MAX_FPS)
	camera.offset = {STARTING_WINDOW_WIDTH / 2, STARTING_WINDOW_HEIGHT / 2}
	camera.target = {STARTING_WINDOW_WIDTH / 2, STARTING_WINDOW_HEIGHT / 2}
	camera.zoom = 1
	ui.init()
	load_textures()
	load_fonts()
}


handle_input :: proc(ui_state: ^UIState) {
	#reverse for ui_element in ui_state.ui_element_list {
		if rl.CheckCollisionPointRec(
			ui_state.last_mouse_world_position,
			ui.get_hitbox(ui_element.ui_data),
		) {
			ui_state.ui_element_hovered_last_frame = ui_element
			break
		} else {
			ui_state.ui_element_hovered_last_frame = {}
		}
	}

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
	if rl.IsKeyReleased(.F) {
		swd.execute_random_move_safe(ui_state.game)
		ui_state.last_selected_object = nil
		ui_state.valid_moves_dirty = true
	}

	if rl.IsMouseButtonReleased(.LEFT) {
		fmt.print(ui_state.last_mouse_world_position)
		fmt.print(" : ")

		print_ui_element_name(ui_state.ui_element_hovered_last_frame)
		handle_click(ui_state.ui_element_hovered_last_frame, ui_state)
	}

	ui_state.last_mouse_world_position = rl.GetScreenToWorld2D(rl.GetMousePosition(), camera)
}

handle_click :: proc(ui_element_clicked: UIElement, ui_state: ^UIState) {
	selected_move: swd.Move
	switch ui_state.game.choice_state {
	case .Game_Over:
		{
			return
		}
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
			#partial switch ui_element_clicked.game_function {
			case .GameObject:
				{
					selected_object := ui_element_clicked.game_object

					if swd.game_object_is_card(selected_object) {
						for move in ui_state.valid_moves {
							if move.card_name == selected_object {
								ui_state.last_selected_object = selected_object
								break
							}
						}
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
	case .Choose_Progress_Token, .Choose_Unavailable_Progress_Token:
		{
			for move in ui_state.valid_moves {
				if move.token == ui_element_clicked.progress_token {
					selected_move = move
					break
				}
			}
		}
	case .Choose_Brown_Card_To_Destroy, .Choose_Grey_Card_To_Destroy, .Choose_Card_To_Revive:
		{
			for move in ui_state.valid_moves {
				if move.card_name == ui_element_clicked.game_object {
					selected_move = move
					break
				}
			}
		}
	case .Choose_First_Player:
		{
			for move in ui_state.valid_moves {
				if move.chosen_player == .P1 && ui_element_clicked.game_function == .SelectP1 {
					selected_move = move
					break
				}
				if move.chosen_player == .P2 && ui_element_clicked.game_function == .SelectP2 {
					selected_move = move
					break
				}
			}
		}
	}
	if selected_move.move_kind != .None {
		swd.execute_move_safe(selected_move, ui_state.game)
		ui_state.last_selected_object = nil
		ui_state.valid_moves_dirty = true
	}
}

draw_frame :: proc(ui_state: ^UIState) {
	rl.BeginDrawing()
	rl.ClearBackground(BACKGROUND_COLOUR)
	rl.DrawTexturePro(
		background,
		{0, 0, f32(background.width), f32(background.height)},
		{0, 0, f32(rl.GetScreenWidth()), f32(rl.GetScreenHeight())},
		{0, 0},
		0.0,
		rl.WHITE,
	)

	rl.BeginMode2D(camera)

	for element in ui_state.ui_element_list {ui.draw_element(element.ui_data)}

	rl.EndMode2D()
	rl.EndDrawing()
}

