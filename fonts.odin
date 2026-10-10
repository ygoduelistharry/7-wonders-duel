package swd_ui

import rl "vendor:raylib"

main_font: rl.Font
load_fonts :: proc() {
	main_font = rl.LoadFontEx("fonts/FiraCode-Medium.ttf", 240, nil, 0)
}

