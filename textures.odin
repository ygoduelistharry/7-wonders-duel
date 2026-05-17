package seven_wonders_duel

import swd "swd_engine"
import rl "vendor:raylib"

Card_Back :: enum {
	Wonders,
	Age1,
	Age2,
	Age3,
	Guilds,
}

Card_Atlases :: [Card_Back]rl.Texture2D
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

Object_Texture_Info :: struct {
	card_back:      Card_Back,
	atlas_position: [2]int,
}
object_texture_info_db: [swd.Object_Name]Object_Texture_Info = {
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

Card_Back_Textures :: [Card_Back]rl.Texture2D
load_card_back_textures :: proc() -> (textures: Card_Back_Textures) {
	textures[.Age1] = rl.LoadTexture("images/age1_back.png")
	textures[.Age2] = rl.LoadTexture("images/age2_back.png")
	textures[.Age3] = rl.LoadTexture("images/age3_back.png")
	textures[.Guilds] = rl.LoadTexture("images/guilds_back.png")
	textures[.Wonders] = rl.LoadTexture("images/wonders_back.png")
	for &texture in textures {
		rl.SetTextureFilter(texture, .BILINEAR)
	}
	return textures
}

Progress_Token_Textures :: [swd.Progress_Token]rl.Texture2D
load_progress_token_textures :: proc() -> (textures: Progress_Token_Textures) {
	textures[.Agriculture] = rl.LoadTexture("images/agriculture.png")
	textures[.Architechture] = rl.LoadTexture("images/architecture.png")
	textures[.Economy] = rl.LoadTexture("images/economy.png")
	textures[.Law] = rl.LoadTexture("images/law.png")
	textures[.Masonry] = rl.LoadTexture("images/masonry.png")
	textures[.Mathematics] = rl.LoadTexture("images/mathematics.png")
	textures[.Philosophy] = rl.LoadTexture("images/philosophy.png")
	textures[.Strategy] = rl.LoadTexture("images/strategy.png")
	textures[.Theology] = rl.LoadTexture("images/theology.png")
	textures[.Urbanism] = rl.LoadTexture("images/urbanism.png")
	for &texture in textures {
		rl.SetTextureFilter(texture, .BILINEAR)
	}
	return textures
}

card_atlases: Card_Atlases
card_back_textures: Card_Back_Textures
progress_token_textures: Progress_Token_Textures
military_track_texture: rl.Texture2D
conflict_pawn_texture: rl.Texture2D
military_token_2_texture: rl.Texture2D
military_token_5_texture: rl.Texture2D
coin_texture: rl.Texture2D

load_textures :: proc() {
	card_atlases = load_object_atlases()
	card_back_textures = load_card_back_textures()
	progress_token_textures = load_progress_token_textures()

	military_track_texture = rl.LoadTexture("images/military_track.png")
	rl.SetTextureFilter(military_track_texture, .BILINEAR)

	conflict_pawn_texture = rl.LoadTexture("images/conflict_pawn.png")
	rl.SetTextureFilter(conflict_pawn_texture, .BILINEAR)

	military_token_2_texture = rl.LoadTexture("images/military_2.png")
	rl.SetTextureFilter(military_token_2_texture, .BILINEAR)

	military_token_5_texture = rl.LoadTexture("images/military_5.png")
	rl.SetTextureFilter(military_token_5_texture, .BILINEAR)

	coin_texture = rl.LoadTexture("images/coin.png")
	rl.SetTextureFilter(coin_texture, .BILINEAR)

	coin_font = rl.LoadFontEx("fonts/FiraCode-Medium.ttf", 240, nil, 0)

	rounded_corners_shader = rl.LoadShader("", "shaders/rounded_corners.frag")
}


get_card_sub_texture_rect :: proc(name: swd.Object_Name) -> rl.Rectangle {
	key := object_texture_info_db[name]
	width, height: f32
	switch key.card_back {
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
	row, col := key.atlas_position[0], key.atlas_position[1]
	pos: [2]f32 = {f32(col) * width, f32(row) * height}
	if key.card_back == .Wonders {pos.y += 60}
	return {pos.x, pos.y, width, height}
}


rounded_corners_shader: rl.Shader
draw_card_texture :: proc(
	name: swd.Object_Name,
	position: [2]f32,
	size: [2]f32,
	rotation: f32 = 0,
	tint: rl.Color = rl.WHITE,
) {
	atlas := card_atlases[object_texture_info_db[name].card_back]
	source_rect := get_card_sub_texture_rect(name)
	normalised_source_rect_bounds: [4]f32 = {
		source_rect.x / f32(atlas.width),
		source_rect.y / f32(atlas.height),
		(source_rect.x + source_rect.width) / f32(atlas.width),
		(source_rect.y + source_rect.height) / f32(atlas.height),
	}
	rl.SetShaderValue(
		rounded_corners_shader,
		rl.GetShaderLocation(rounded_corners_shader, "spriteUVBounds"),
		&normalised_source_rect_bounds,
		.VEC4,
	)
	rl.BeginShaderMode(rounded_corners_shader)
	rl.DrawTexturePro(
		atlas,
		source_rect,
		{position.x, position.y, size.x, size.y},
		{size.x, size.y} / 2,
		rotation,
		tint,
	)
	rl.EndShaderMode()
}

draw_card_back :: proc(
	card_back: Card_Back,
	position: [2]f32,
	size: [2]f32,
	rotation: f32 = 0,
	tint: rl.Color = rl.WHITE,
) {
	texture := card_back_textures[card_back]
	normalised_source_rect_bounds: [4]f32 = {0, 0, 1, 1}
	rl.SetShaderValue(
		rounded_corners_shader,
		rl.GetShaderLocation(rounded_corners_shader, "spriteUVBounds"),
		&normalised_source_rect_bounds,
		.VEC4,
	)
	rl.BeginShaderMode(rounded_corners_shader)
	rl.DrawTexturePro(
		texture,
		{0, 0, f32(texture.width), f32(texture.height)},
		{position.x, position.y, size.x, size.y},
		{size.x, size.y} / 2,
		rotation,
		tint,
	)
	rl.EndShaderMode()
}
