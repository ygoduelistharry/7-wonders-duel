package seven_wonders_duel

import "core:fmt"
import "core:mem"
import swd "swd_engine"
import rl "vendor:raylib"

STARTING_WINDOW_WIDTH, STARTING_WINDOW_HEIGHT :: 1920, 1080
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

load_object_textures :: proc() -> (textures: Card_Atlases) {
	textures[.Wonders] = rl.LoadTexture("images/wonders.jpg")
	textures[.Age1] = rl.LoadTexture("images/age1.jpg")
	textures[.Age2] = rl.LoadTexture("images/age2.jpg")
	textures[.Age3] = rl.LoadTexture("images/age3.jpg")
	textures[.Guilds] = rl.LoadTexture("images/guilds.jpg")
	return textures
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

load_progress_token_textures :: proc() -> (textures: [swd.Progress_Token]rl.Texture2D) {
	textures[.Agriculture] = rl.LoadTexture("image/argiculture.png")
	textures[.Architechture] = rl.LoadTexture("image/architechture.png")
	textures[.Economy] = rl.LoadTexture("image/economy.png")
	textures[.Law] = rl.LoadTexture("image/law.png")
	textures[.Masonry] = rl.LoadTexture("image/masonry.png")
	textures[.Mathematics] = rl.LoadTexture("image/mathematics.png")
	textures[.Philosophy] = rl.LoadTexture("image/philosophy.png")
	textures[.Strategy] = rl.LoadTexture("image/strategy.png")
	textures[.Theology] = rl.LoadTexture("image/theology.png")
	textures[.Urbanism] = rl.LoadTexture("image/urbanism.png")
	return textures
}

window_setup :: proc() {
	rl.SetConfigFlags({.VSYNC_HINT})
	rl.InitWindow(STARTING_WINDOW_WIDTH, STARTING_WINDOW_HEIGHT, "7 Wonders Duel")
	rl.SetTargetFPS(MAX_FPS)
}

handle_input :: proc() {}


get_card_sub_texture_rect :: proc(name: swd.Object_Name) -> rl.Rectangle {
	key := object_atlas_keys[name]
	width, height: f32
	switch key.atlas {
	case .Wonders:
		{width, height = 858, 551}
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
	return {f32(col) * width, f32(row) * height, width, height}
}

draw_card :: proc(
	name: swd.Object_Name,
	atlases: Card_Atlases,
	dest_rect: rl.Rectangle,
	rotation: f32 = 0,
	tint: rl.Color = rl.WHITE,
) {
	texture := atlases[object_atlas_keys[name].atlas]
	source_rect := get_card_sub_texture_rect(name)
	rl.DrawTexturePro(
		texture,
		source_rect,
		dest_rect,
		{source_rect.width, source_rect.height} / 2,
		rotation,
		tint,
	)
}

draw_frame :: proc(game: swd.Game) {
	rl.BeginDrawing()
	rl.ClearBackground(BACKGROUND_COLOUR)
	for slot in game.boards[game.age] {
		// draw_card(slot.card_in_slot)
	}
	rl.EndDrawing()
}

game_object_textures: Card_Atlases

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
	game_object_textures = load_object_textures()
	progress_token_textures := load_progress_token_textures()

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(BACKGROUND_COLOUR)

		draw_card(.Builders_Guild, game_object_textures, {500, 500, 130, 200})
		draw_card(.The_Appian_Way, game_object_textures, {700, 700, 400, 260})
		rl.EndDrawing()
		handle_input()
		// draw_frame()
	}

}
