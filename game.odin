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

Card_Atlas :: enum {
	Wonders,
	Age1,
	Age2,
	Age3,
	Guilds,
}
Card_Atlases :: [Card_Atlas]rl.Texture2D

load_object_atlases :: proc() -> (atlases: Card_Atlases) {
	atlases[.Wonders] = rl.LoadTexture("images/wonders.jpg")
	atlases[.Age1] = rl.LoadTexture("images/age1.jpg")
	atlases[.Age2] = rl.LoadTexture("images/age2.jpg")
	atlases[.Age3] = rl.LoadTexture("images/age3.jpg")
	atlases[.Guilds] = rl.LoadTexture("images/guilds.jpg")
	for &atlas in atlases {
		rl.SetTextureFilter(atlas, .BILINEAR)
	}
	return atlases
}

Card_Atlas_Key :: struct {
	atlas:         Card_Atlas,
	grid_position: [2]int,
}
object_atlas_keys: [swd.Object_Name]Card_Atlas_Key = {
	.The_Colossus          = {.Wonders, {0, 0}},
	.Circus_Maximus        = {.Wonders, {0, 1}},
	.The_Hanging_Gardens   = {.Wonders, {0, 2}},
	.The_Pyramids          = {.Wonders, {0, 3}},
	.The_Great_Lighthouse  = {.Wonders, {0, 4}},
	.The_Statue_of_Zeus    = {.Wonders, {0, 5}},
	.The_Mausoleum         = {.Wonders, {0, 6}},
	.The_Appian_Way        = {.Wonders, {0, 7}},
	.Piraeus               = {.Wonders, {0, 8}},
	.The_Great_Library     = {.Wonders, {0, 9}},
	.The_Temple_of_Artemis = {.Wonders, {1, 0}},
	.The_Sphinx            = {.Wonders, {1, 1}},
	.Glassworks            = {.Age1, {0, 0}},
	.Clay_Pit              = {.Age1, {0, 1}},
	.Quarry                = {.Age1, {0, 2}},
	.Logging_Camp          = {.Age1, {0, 3}},
	.Stable                = {.Age1, {0, 4}},
	.Garrison              = {.Age1, {0, 5}},
	.Palisade              = {.Age1, {0, 6}},
	.Guard_Tower           = {.Age1, {0, 7}},
	.Scriptorium           = {.Age1, {0, 8}},
	.Tavern                = {.Age1, {0, 9}},
	.Apothecary            = {.Age1, {1, 0}},
	.Pharmacist            = {.Age1, {1, 1}},
	.Workshop              = {.Age1, {1, 2}},
	.Theatre               = {.Age1, {1, 3}},
	.Clay_Reserve          = {.Age1, {1, 4}},
	.Wood_Reserve          = {.Age1, {1, 5}},
	.Altar                 = {.Age1, {1, 6}},
	.Stone_Reserve         = {.Age1, {1, 7}},
	.Clay_Pool             = {.Age1, {1, 8}},
	.Lumber_Yard           = {.Age1, {1, 9}},
	.Stone_Pit             = {.Age1, {2, 0}},
	.Baths                 = {.Age1, {2, 1}},
	.Press                 = {.Age1, {2, 2}},
	.Statue                = {.Age2, {0, 0}},
	.Rostrum               = {.Age2, {0, 1}},
	.Dispensary            = {.Age2, {0, 2}},
	.Parade_Ground         = {.Age2, {0, 3}},
	.Shelf_Quarry          = {.Age2, {0, 4}},
	.Drying_Room           = {.Age2, {0, 5}},
	.Barracks              = {.Age2, {0, 6}},
	.Brickyard             = {.Age2, {0, 7}},
	.Brewery               = {.Age2, {0, 8}},
	.Caravansery           = {.Age2, {0, 9}},
	.Laboratory            = {.Age2, {1, 0}},
	.Courthouse            = {.Age2, {1, 1}},
	.Aqueduct              = {.Age2, {1, 2}},
	.Horse_Breeders        = {.Age2, {1, 3}},
	.Archery_Range         = {.Age2, {1, 4}},
	.Sawmill               = {.Age2, {1, 5}},
	.Forum                 = {.Age2, {1, 6}},
	.Walls                 = {.Age2, {1, 7}},
	.School                = {.Age2, {1, 8}},
	.Library               = {.Age2, {1, 9}},
	.Temple                = {.Age2, {2, 0}},
	.Glassblower           = {.Age2, {2, 1}},
	.Customs_House         = {.Age2, {2, 2}},
	.Palace                = {.Age3, {0, 1}},
	.Circus                = {.Age3, {0, 0}},
	.University            = {.Age3, {0, 2}},
	.Town_Hall             = {.Age3, {0, 3}},
	.Port                  = {.Age3, {0, 4}},
	.Chamber_of_Commerce   = {.Age3, {0, 5}},
	.Arsenal               = {.Age3, {0, 6}},
	.Armory                = {.Age3, {0, 7}},
	.Lighthouse            = {.Age3, {0, 8}},
	.Fortifications        = {.Age3, {0, 9}},
	.Obelisk               = {.Age3, {1, 0}},
	.Senate                = {.Age3, {1, 1}},
	.Pantheon              = {.Age3, {1, 2}},
	.Gardens               = {.Age3, {1, 3}},
	.Arena                 = {.Age3, {1, 4}},
	.Study                 = {.Age3, {1, 5}},
	.Observatory           = {.Age3, {1, 6}},
	.Academy               = {.Age3, {1, 7}},
	.Siege_Workshop        = {.Age3, {1, 8}},
	.Pretorium             = {.Age3, {1, 9}},
	.Tacticians_Guild      = {.Guilds, {0, 0}},
	.Merchants_Guild       = {.Guilds, {0, 1}},
	.Moneylenders_Guild    = {.Guilds, {0, 2}},
	.Builders_Guild        = {.Guilds, {0, 3}},
	.Magistrates_Guild     = {.Guilds, {0, 4}},
	.Scientists_Guild      = {.Guilds, {0, 5}},
	.Shipowners_Guild      = {.Guilds, {0, 6}},
}

Token_Textures :: [swd.Progress_Token]rl.Texture2D
load_progress_token_textures :: proc() -> (textures: Token_Textures) {
	textures[.Agriculture] = rl.LoadTexture("images/Argiculture.png")
	textures[.Architechture] = rl.LoadTexture("images/Architechture.png")
	textures[.Economy] = rl.LoadTexture("images/Economy.png")
	textures[.Law] = rl.LoadTexture("images/Law.png")
	textures[.Masonry] = rl.LoadTexture("images/Masonry.png")
	textures[.Mathematics] = rl.LoadTexture("images/Mathematics.png")
	textures[.Philosophy] = rl.LoadTexture("images/Philosophy.png")
	textures[.Strategy] = rl.LoadTexture("images/Strategy.png")
	textures[.Theology] = rl.LoadTexture("images/Theology.png")
	textures[.Urbanism] = rl.LoadTexture("images/Urbanism.png")
	return textures
}

card_atlases: Card_Atlases
token_textures: Token_Textures

get_card_sub_texture_rect :: proc(name: swd.Object_Name) -> rl.Rectangle {
	key := object_atlas_keys[name]
	width, height: f32
	switch key.atlas {
	case .Wonders:
		{width, height = 858, 460}
	case .Guilds:
		{width, height = 557, 858}
	case .Age1:
		{width, height = 551, 858}
	case .Age2:
		{width, height = 551, 858}
	case .Age3:
		{width, height = 549, 858}
	}
	row, col := key.grid_position[0], key.grid_position[1]
	pos: [2]f32 = {f32(col) * width, f32(row) * height}
	if key.atlas == .Wonders {pos.y += 60}
	return {pos.x, pos.y, width, height}
}


draw_card_texture :: proc(
	name: swd.Object_Name,
	position: [2]f32,
	size: [2]f32,
	rotation: f32 = 0,
	tint: rl.Color = rl.WHITE,
) {
	texture := card_atlases[object_atlas_keys[name].atlas]
	source_rect := get_card_sub_texture_rect(name)
	rl.DrawTexturePro(
		texture,
		source_rect,
		{position.x, position.y, size.x, size.y},
		{size.x, size.y} / 2,
		rotation,
		tint,
	)
}

military_track_texture: rl.Texture2D

camera: rl.Camera2D
window_setup :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT} | {.WINDOW_RESIZABLE})
	rl.InitWindow(STARTING_WINDOW_WIDTH, STARTING_WINDOW_HEIGHT, "7 Wonders Duel")
	rl.SetTargetFPS(MAX_FPS)
	camera.offset = {STARTING_WINDOW_WIDTH / 2, STARTING_WINDOW_HEIGHT / 2}
	camera.target = {STARTING_WINDOW_WIDTH / 2, STARTING_WINDOW_HEIGHT / 2}
	camera.zoom = 1
}

handle_input :: proc() {}

CARD_SIZE: [2]f32 : {120, 190}
WONDER_SIZE: [2]f32 : {225 * 1.3, 135 * 1.3}

draw_frame :: proc(game: swd.Game) {
	rl.BeginDrawing()
	rl.ClearBackground(BACKGROUND_COLOUR)
	rl.BeginMode2D(camera)
	vert_offset: f32 = 1.0 / 2.8
	for col in 0 ..< 6 {
		x := STARTING_WINDOW_WIDTH / 2 - CARD_SIZE.x * 2.5 + f32(col) * CARD_SIZE.x
		for row in 0 ..< 7 {
			y := 5 + CARD_SIZE.y * 0.5 + f32(row) * CARD_SIZE.y * vert_offset
			draw_card_texture(.Builders_Guild, {x, y}, CARD_SIZE)
		}
	}
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
		for row in 0 ..< 10 {
			y := WONDER_SIZE.y * 2 + 75 + f32(row + 2) * CARD_SIZE.y / 4
			draw_card_texture(.Builders_Guild, {x, y}, CARD_SIZE)
		}
	}
	military_track_width: f32 = 780.0
	military_track_height: f32 = 240.0
	rl.DrawTexturePro(
		military_track_texture,
		{0, 0, 3000, 900},
		{
			STARTING_WINDOW_WIDTH / 2,
			STARTING_WINDOW_HEIGHT / 2 + 175,
			military_track_width,
			military_track_height,
		},
		{military_track_width / 2, military_track_height / 2},
		0,
		rl.WHITE,
	)
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

	window_setup()
	card_atlases = load_object_atlases()
	token_textures = load_progress_token_textures()
	military_track_texture = rl.LoadTexture("images/military_track.png")

	for !rl.WindowShouldClose() {
		if rl.IsWindowResized() {
			camera.zoom = min(
				f32(rl.GetScreenWidth()) / f32(STARTING_WINDOW_WIDTH),
				f32(rl.GetScreenHeight()) / f32(STARTING_WINDOW_HEIGHT),
			)
			camera.offset = get_screen_centre()
		}
		draw_frame(game)
	}
}
