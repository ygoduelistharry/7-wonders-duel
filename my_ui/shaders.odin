package my_ui

import rl "vendor:raylib"

rounded_rect_shader: rl.Shader
rounded_rect_shader_sprite_uv_bounds_loc: i32
rounded_rect_shader_radius_loc: i32
rounded_rect_shader_border_width_loc: i32
rounded_rect_shader_border_color_loc: i32

load_shaders :: proc() {
	rounded_rect_shader = rl.LoadShader("", "my_ui/shaders/rounded_rectangle.frag")
	rounded_rect_shader_sprite_uv_bounds_loc = rl.GetShaderLocation(
		rounded_rect_shader,
		"spriteUVBounds",
	)
	rounded_rect_shader_radius_loc = rl.GetShaderLocation(rounded_rect_shader, "radius")
	rounded_rect_shader_border_width_loc = rl.GetShaderLocation(rounded_rect_shader, "borderWidth")
	rounded_rect_shader_border_color_loc = rl.GetShaderLocation(rounded_rect_shader, "borderColor")
}

get_sub_rect_uv_bounds :: proc(texture: rl.Texture, source_rect: rl.Rectangle) -> [4]f32 {
	return {
		source_rect.x / f32(texture.width),
		source_rect.y / f32(texture.height),
		(source_rect.x + source_rect.width) / f32(texture.width),
		(source_rect.y + source_rect.height) / f32(texture.height),
	}
}

