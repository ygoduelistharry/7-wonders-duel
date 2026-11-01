package swd_ui

import rl "vendor:raylib"

main_font: rl.Font
log_font: rl.Font
coin_font: rl.Font
action_confirm_font: rl.Font
cost_info_font: rl.Font
tooltip_font: rl.Font
extra_required_characters := "┌└─│"
load_fonts :: proc() {
	runes := make([dynamic]rune, context.temp_allocator)
	for i in 32 ..= 126 {
		append(&runes, rune(i))
	}
	for char in extra_required_characters {
		append(&runes, char)
	}
	codepoints := raw_data(runes)
	codepoint_coint := i32(len(runes))

	main_font = rl.LoadFontEx("fonts/FiraCode-Medium.ttf", 240, codepoints, codepoint_coint)
	log_font = rl.LoadFontEx(
		"fonts/FiraCode-Medium.ttf",
		LOG_FONT_SIZE,
		codepoints,
		codepoint_coint,
	)
	coin_font = rl.LoadFontEx(
		"fonts/FiraCode-Medium.ttf",
		COIN_FONT_SIZE,
		codepoints,
		codepoint_coint,
	)
	action_confirm_font = rl.LoadFontEx(
		"fonts/FiraCode-Medium.ttf",
		ACTION_CONFIRM_FONT_SIZE,
		codepoints,
		codepoint_coint,
	)
	cost_info_font = rl.LoadFontEx(
		"fonts/FiraCode-Medium.ttf",
		COST_INFO_FONT_SIZE,
		codepoints,
		codepoint_coint,
	)
	tooltip_font = rl.LoadFontEx(
		"fonts/FiraCode-Medium.ttf",
		TOOLTIP_FONT_SIZE,
		codepoints,
		codepoint_coint,
	)
}

