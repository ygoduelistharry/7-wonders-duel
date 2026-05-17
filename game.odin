package seven_wonders_duel

import "core:fmt"
import "core:mem"
import swd "swd_engine"
import rl "vendor:raylib"

STARTING_WINDOW_WIDTH, STARTING_WINDOW_HEIGHT :: 1920, 1080
get_screen_centre :: proc() -> [2]f32 {
	return {auto_cast rl.GetScreenWidth() / 2, auto_cast rl.GetScreenHeight() / 2}
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

handle_input :: proc(game: ^swd.Game) {
	if rl.IsKeyReleased(.W) {
		testAge = .Age1
	}
	if rl.IsKeyReleased(.E) {
		testAge = .Age2
	}
	if rl.IsKeyReleased(.R) {
		testAge = .Age3
	}
	if rl.IsKeyReleased(.S) {
		game.military_track -= 1
	}
	if rl.IsKeyReleased(.D) {
		game.military_track += 1
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
draw_card_structure :: proc(midpoint: [2]f32, age: swd.Age, game: swd.Game) {
	if age == .DraftWonders {
		for wonder, i in game.wonders_to_draft {
			if i in game.wonder_ids_draftable {
				grid_pos: [2]int
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

			} else {continue}
		}
	} else {
		y_offset: f32 = CARD_SIZE.y * 1.0 / 2.8
		x_offset: f32 = CARD_SIZE.x * 1.0 / 2.0 + 3
		layout_grid := card_structure_grids[age]
		for i := 19; i >= 0; i -= 1 {
			grid_pos := layout_grid[i]
			slot := game.boards[age][i]
			texture_pos: [2]f32 =
				midpoint + {f32(grid_pos.x), f32(grid_pos.y)} * {x_offset, y_offset}
			if slot.card_in_slot == {} {continue}
			if slot.visible {
				draw_card_texture(slot.card_in_slot, texture_pos, CARD_SIZE)
			} else {
				card_back := object_texture_info_db[slot.card_in_slot].card_back
				draw_card_back(card_back, texture_pos, CARD_SIZE)
			}
		}
	}
}

MILITARY_TRACK_SCALE: f32 : 1.2
MILITARY_TRACK_SIZE: [2]f32 : {780 * MILITARY_TRACK_SCALE, 240 * MILITARY_TRACK_SCALE}
MILITARY_TOKEN_SIZE: [2]f32 : {44 * MILITARY_TRACK_SCALE, 88 * MILITARY_TRACK_SCALE}
CONFLICT_PAWN_SIZE: [2]f32 = {36 * MILITARY_TRACK_SCALE, 72 * MILITARY_TRACK_SCALE}
PROGRESS_TOKEN_DIAMETER: f32 : 72 * MILITARY_TRACK_SCALE
draw_military_track :: proc(midpoint: [2]f32, game: swd.Game) {
	rl.DrawTexturePro(
		military_track_texture,
		{0, 0, 3000, 900},
		{midpoint.x, midpoint.y, MILITARY_TRACK_SIZE.x, MILITARY_TRACK_SIZE.y},
		MILITARY_TRACK_SIZE / 2,
		0,
		rl.WHITE,
	)

	for token in game.military_tokens_available {
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

	pawn_offset: f32 = f32(game.military_track * 37) * MILITARY_TRACK_SCALE
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
	token_offset: f32 = -2 * token_spacing
	for token in game.progress_tokens_available {
		texture := progress_token_textures[token]
		rl.DrawTexturePro(
			texture,
			{0, 0, f32(texture.width), f32(texture.height)},
			{
				midpoint.x + token_offset,
				midpoint.y - 67 * MILITARY_TRACK_SCALE,
				PROGRESS_TOKEN_DIAMETER,
				PROGRESS_TOKEN_DIAMETER,
			},
			{PROGRESS_TOKEN_DIAMETER / 2, PROGRESS_TOKEN_DIAMETER / 2},
			180,
			rl.WHITE,
		)
		token_offset += token_spacing
	}
}

COIN_DIAMETER: f32 : 110
COIN_FONT_SIZE: i32 : 90
COIN_FONT_OUTLINE_SIZE: f32 : 4
coin_font: rl.Font
draw_player_coins :: proc(position: [2]f32, player: swd.Player_ID, game: swd.Game) {
	rl.DrawTexturePro(
		coin_texture,
		{0, 0, f32(coin_texture.width), f32(coin_texture.height)},
		{position.x, position.y, COIN_DIAMETER, COIN_DIAMETER},
		{COIN_DIAMETER / 2, COIN_DIAMETER / 2},
		0,
		rl.WHITE,
	)
	COIN_FONT_SIZE: i32 = 90
	offsets: [4][2]f32 = {
		{-COIN_FONT_OUTLINE_SIZE, -COIN_FONT_OUTLINE_SIZE},
		{COIN_FONT_OUTLINE_SIZE, -COIN_FONT_OUTLINE_SIZE},
		{-COIN_FONT_OUTLINE_SIZE, COIN_FONT_OUTLINE_SIZE},
		{COIN_FONT_OUTLINE_SIZE, COIN_FONT_OUTLINE_SIZE},
	}
	value: cstring = fmt.ctprintf("%d", game.player_states[player].coins)
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

draw_frame :: proc(game: swd.Game) {
	rl.BeginDrawing()
	rl.ClearBackground(BACKGROUND_COLOUR)
	rl.BeginMode2D(camera)

	card_structure_midpoint: [2]f32 = {STARTING_WINDOW_WIDTH / 2, 1.57 * CARD_SIZE.y + 5}
	draw_card_structure(card_structure_midpoint, testAge, game)

	military_track_midpoint: [2]f32 = {
		STARTING_WINDOW_WIDTH / 2,
		STARTING_WINDOW_HEIGHT - MILITARY_TRACK_SIZE.y / 2,
	}
	draw_military_track(military_track_midpoint, game)

	coin_x_offset := MILITARY_TRACK_SIZE.x / 2 + COIN_DIAMETER * 2
	coin_y := STARTING_WINDOW_HEIGHT - COIN_DIAMETER
	p1_coin_position: [2]f32 = {STARTING_WINDOW_WIDTH / 2 - coin_x_offset, coin_y}
	p2_coin_position: [2]f32 = {STARTING_WINDOW_WIDTH / 2 + coin_x_offset, coin_y}
	draw_player_coins(p1_coin_position, .P1, game)
	draw_player_coins(p2_coin_position, .P2, game)

	for col in 0 ..< 2 {
		gap: f32 = 5
		x := WONDER_SIZE.x / 2 + f32(col) * (WONDER_SIZE.x + gap) + 5
		for row in 0 ..< 2 {
			y := WONDER_SIZE.y / 2 + f32(row) * (WONDER_SIZE.y + gap) + 5
			draw_card_texture(.The_Appian_Way, {x, y}, WONDER_SIZE)
		}
	}

	for col in 0 ..< 4 {
		x := CARD_SIZE.x / 2 + f32(col) * CARD_SIZE.x + 50
		for row in 0 ..< 8 {
			y := WONDER_SIZE.y * 2 + 25 + f32(row + 2) * CARD_SIZE.y / 4
			draw_card_back(.Age1, {x, y}, CARD_SIZE)
		}
	}

	rl.EndMode2D()
	rl.EndDrawing()
}

testAge: swd.Age = .Age1

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

	window_setup()
	load_textures()

	for !rl.WindowShouldClose() {
		handle_input(&game)
		if rl.IsWindowResized() {
			camera.zoom = min(
				f32(rl.GetScreenWidth()) / f32(STARTING_WINDOW_WIDTH),
				f32(rl.GetScreenHeight()) / f32(STARTING_WINDOW_HEIGHT),
			)
			camera.offset = get_screen_centre()
		}
		draw_frame(game)
		free_all(context.temp_allocator)
	}
}
