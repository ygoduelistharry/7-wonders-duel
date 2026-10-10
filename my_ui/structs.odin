package my_ui

import rl "vendor:raylib"

Data :: struct {
	label:           Label,
	dest_midpoint:   [2]f32,
	dest_size:       [2]f32,
	hitbox_midpoint: [2]f32,
	hitbox_size:     [2]f32,
	rotation:        f32,
	//texture data
	texture:         Maybe(rl.Texture2D),
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
}

