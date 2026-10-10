package my_ui

import "core:fmt"
import "core:math/linalg"
import "core:strings"
import rl "vendor:raylib"

init :: proc() {
	load_shaders()
}

draw_element :: proc(ui_element: Data) {
	tint := ui_element.tint.? or_else rl.WHITE
	if ui_element.label == .None {return}
	if ui_element.label == .Text {
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
		return
	}
	if texture, ok := ui_element.texture.?; ok {
		dest_rect: rl.Rectangle = {
			ui_element.dest_midpoint.x,
			ui_element.dest_midpoint.y,
			ui_element.dest_size.x,
			ui_element.dest_size.y,
		}
		source_rect := ui_element.source_rect
		if source_rect == {0, 0, 0, 0} {
			source_rect = {0, 0, f32(texture.width), f32(texture.height)}
		}
		if ui_element.border_width + ui_element.corner_radius > 0 {
			rl.BeginShaderMode(rounded_rect_shader)
			sub_rect_uv_bounds := get_sub_rect_uv_bounds(texture, source_rect)
			corner_radius := ui_element.corner_radius
			border_width := ui_element.border_width
			border_colour := linalg.array_cast(ui_element.border_colour, f32) / 255.0
			rl.SetShaderValue(
				rounded_rect_shader,
				rounded_rect_shader_sprite_uv_bounds_loc,
				&sub_rect_uv_bounds,
				.VEC4,
			)
			rl.SetShaderValue(
				rounded_rect_shader,
				rounded_rect_shader_radius_loc,
				&corner_radius,
				.FLOAT,
			)
			rl.SetShaderValue(
				rounded_rect_shader,
				rounded_rect_shader_border_width_loc,
				&border_width,
				.FLOAT,
			)
			rl.SetShaderValue(
				rounded_rect_shader,
				rounded_rect_shader_border_color_loc,
				&border_colour,
				.VEC4,
			)
		}
		rl.DrawTexturePro(
			texture,
			source_rect,
			dest_rect,
			ui_element.dest_size / 2,
			ui_element.rotation,
			tint,
		)
		if ui_element.border_width + ui_element.corner_radius > 0 {
			rl.EndShaderMode()
		}
	} else {
		dest_rect: rl.Rectangle = {
			ui_element.dest_midpoint.x - ui_element.dest_size.x / 2,
			ui_element.dest_midpoint.y - ui_element.dest_size.y / 2,
			ui_element.dest_size.x,
			ui_element.dest_size.y,
		}
		roundness :=
			2 * ui_element.corner_radius / min(ui_element.dest_size.x, ui_element.dest_size.y)
		rl.DrawRectangleRounded(dest_rect, roundness, 10, tint)
		rl.DrawRectangleRoundedLinesEx(
			dest_rect,
			roundness,
			10,
			ui_element.border_width,
			ui_element.border_colour,
		)
	}
}

get_hitbox :: proc(ui_element: Data) -> rl.Rectangle {
	hitbox_topleft := ui_element.hitbox_midpoint - ui_element.hitbox_size / 2
	hitbox: rl.Rectangle = {
		x      = hitbox_topleft.x,
		y      = hitbox_topleft.y,
		width  = ui_element.hitbox_size.x,
		height = ui_element.hitbox_size.y,
	}
	return hitbox
}

create_text_ui_element :: proc(
	text: string,
	font_size: f32,
	dest_midpoint: [2]f32,
	colour: rl.Color,
	font: rl.Font,
) -> (
	element: Data,
) {
	element.label = .Text
	element.dest_midpoint = dest_midpoint
	element.hitbox_midpoint = dest_midpoint
	element.text = fmt.ctprint(text)
	element.font_size = font_size
	element.text_colour = colour
	element.font = font
	element.hitbox_size = rl.MeasureTextEx(element.font, fmt.ctprint(text), font_size, 0)
	return
}

create_rectangle_ui_element :: proc(
	dest_midpoint: [2]f32,
	size: [2]f32,
	colour: rl.Color = rl.MAGENTA,
	border_width: f32 = 0,
	border_colour: rl.Color = rl.MAGENTA,
	corner_radius: f32 = 0,
) -> (
	element: Data,
) {
	element.label = .Visual
	element.dest_midpoint = dest_midpoint
	element.dest_size = size
	element.tint = colour
	element.border_width = border_width
	element.border_colour = border_colour
	element.corner_radius = corner_radius
	return
}

//TODO rewrite below allocation-less
string_to_word_wrapped_string_list :: proc(
	text: string,
	font: rl.Font,
	font_size: f32,
	max_line_width: f32,
	allocator := context.allocator,
) -> (
	[dynamic]string,
	bool,
) {
	words := strings.split(text, " ")
	defer delete(words)
	word_widths := make([dynamic]f32)
	defer delete(word_widths)
	space_width := rl.MeasureTextEx(font, " ", font_size, 0).x
	max_word_width: f32
	for word in words {
		word_width :=
			rl.MeasureTextEx(font, strings.clone_to_cstring(word, context.temp_allocator), font_size, 0).x
		append(&word_widths, word_width)
		max_word_width = max(word_width, max_word_width)
	}

	lines := make([dynamic]string, allocator)
	if max_word_width > max_line_width {return nil, false}

	curr_line_width: f32
	curr_line := strings.builder_make()
	defer strings.builder_destroy(&curr_line)
	for word_width, i in word_widths {
		word := words[i]
		if curr_line_width == 0 {
			strings.write_string(&curr_line, word)
			curr_line_width += word_width
			continue
		}
		if curr_line_width + word_width + space_width <= max_line_width {
			strings.write_string(&curr_line, " ")
			strings.write_string(&curr_line, word)
			curr_line_width += word_width + space_width
		} else {
			append(&lines, strings.clone(strings.to_string(curr_line), allocator))
			strings.builder_reset(&curr_line)
			strings.write_string(&curr_line, word)
			curr_line_width = word_width
		}
	}
	if curr_line_width > 0 {
		append(&lines, strings.clone(strings.to_string(curr_line), allocator))
	}

	return lines, true
}


create_text_box_fixed_width_elements :: proc(
	text: string,
	font: rl.Font,
	font_size, line_spacing: f32,
	text_colour: rl.Color,
	box_origin_pos: [2]f32,
	width: f32,
	height: Maybe(f32) = nil,
	padding: f32 = 5.0,
	fill_colour: rl.Color = rl.MAGENTA,
	h_text_alignment: HorizontalPos = .LEFT,
	v_text_alignment: VerticalPos = .TOP,
	h_box_origin: HorizontalPos = .CENTRE,
	v_box_origin: VerticalPos = .CENTRE,
	border_width: f32 = 0,
	border_colour: rl.Color = rl.MAGENTA,
	corner_radius: f32 = 0,
	allocator := context.temp_allocator,
) -> [dynamic]Data {
	elements := make([dynamic]Data, allocator)
	word_wrapped_lines, box_width_sufficient := string_to_word_wrapped_string_list(
		text,
		font,
		font_size,
		width - 2 * padding,
		allocator = allocator,
	)

	line_count: int
	if box_width_sufficient {
		line_count = len(word_wrapped_lines)
	}

	box_height := padding * 2
	full_text_height := f32(line_count) * font_size + f32(line_count - 1) * line_spacing
	if h, height_specified := height.?; height_specified {
		box_height = h
	} else {
		box_height += full_text_height
	}

	dest_midpoint := box_origin_pos
	switch h_box_origin {
	case .LEFT:
		{dest_midpoint.x += width / 2}
	case .RIGHT:
		{dest_midpoint.x -= width / 2}
	case .CENTRE:
		{}
	}
	switch v_box_origin {
	case .TOP:
		{dest_midpoint.y += box_height / 2}
	case .BOTTOM:
		{dest_midpoint.y -= box_height / 2}
	case .CENTRE:
		{}
	}
	box_size: [2]f32 = {width, box_height}
	append(
		&elements,
		create_rectangle_ui_element(
			dest_midpoint,
			box_size,
			fill_colour,
			border_width,
			border_colour,
			corner_radius,
		),
	)

	if !box_width_sufficient {return elements}

	top_line_midpoint_y_pos: f32
	if height == nil {
		top_line_midpoint_y_pos = dest_midpoint.y - box_height / 2 + padding + font_size / 2
	} else {
		switch v_text_alignment {
		case .TOP:
			{
				top_line_midpoint_y_pos =
					dest_midpoint.y - box_height / 2 + padding + font_size / 2
			}
		case .BOTTOM:
			{
				top_line_midpoint_y_pos =
					dest_midpoint.y + box_height / 2 - padding - full_text_height + font_size / 2
			}
		case .CENTRE:
			{
				top_line_midpoint_y_pos = dest_midpoint.y - full_text_height / 2 + font_size / 2
			}
		}
	}

	for line, i in word_wrapped_lines {
		y_pos := top_line_midpoint_y_pos + f32(i) * (font_size + line_spacing)
		half_line_width := rl.MeasureTextEx(font, fmt.ctprint(line), font_size, 0).x / 2
		half_box_width := width / 2
		x_pos: f32
		switch h_text_alignment {
		case .LEFT:
			{x_pos = dest_midpoint.x - half_box_width + padding + half_line_width}
		case .RIGHT:
			{x_pos = dest_midpoint.x + half_box_width - padding - half_line_width}
		case .CENTRE:
			{x_pos = dest_midpoint.x}
		}
		append(
			&elements,
			create_text_ui_element(line, font_size, {x_pos, y_pos}, text_colour, font),
		)
	}
	return elements
}

