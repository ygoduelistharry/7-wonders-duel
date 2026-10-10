package swd_ui

import swd "swd_engine"
import rl "vendor:raylib"


// Raylib consts
STARTING_WINDOW_WIDTH, STARTING_WINDOW_HEIGHT :: 1920, 1080
STARTING_WINDOW_SIZE: [2]int : {STARTING_WINDOW_WIDTH, STARTING_WINDOW_HEIGHT}
MAX_FPS :: 120
BACKGROUND_COLOUR: rl.Color : {76, 53, 83, 255}

// Game UI consts
PLAYER_COLOUR: #sparse[swd.Player_ID]rl.Color = {
	.P1 = rl.BLUE,
	.P2 = rl.RED,
}
SELECTED_COLOUR: rl.Color : rl.YELLOW

CARD_SIZE: [2]f32 : {120, 190}
WONDER_SIZE: [2]f32 : {225 * 1.25, 135 * 1.25}
CARD_CORNER_RADIUS: f32 : 12
SELECTION_BORDER_WIDTH: f32 : 4

MILITARY_TRACK_SCALE: f32 : 1.2
MILITARY_TRACK_SIZE: [2]f32 : {780 * MILITARY_TRACK_SCALE, 240 * MILITARY_TRACK_SCALE}
MILITARY_TRACK_MIDPOINT: [2]f32 : {
	STARTING_WINDOW_WIDTH / 2,
	STARTING_WINDOW_HEIGHT - MILITARY_TRACK_SIZE.y / 2,
}
MILITARY_TOKEN_SIZE: [2]f32 : {44 * MILITARY_TRACK_SCALE, 88 * MILITARY_TRACK_SCALE}
CONFLICT_PAWN_SIZE: [2]f32 = {36 * MILITARY_TRACK_SCALE, 72 * MILITARY_TRACK_SCALE}
PROGRESS_TOKEN_DIAMETER: f32 : 72 * MILITARY_TRACK_SCALE

COIN_DIAMETER: f32 : 110
COIN_FONT_SIZE: f32 : 90
COIN_FONT_OUTLINE_SIZE: f32 : 4
COIN_FONT_COLOUR: rl.Color : rl.WHITE

CARD_STRUCTURE_MIDPOINT: [2]f32 : {STARTING_WINDOW_WIDTH / 2, 1.57 * CARD_SIZE.y + 5}


@(rodata)
CARD_STRUCTURE_GRIDS: [swd.Age][20][2]int = #partial {
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


// Game engine consts
GameFunction :: enum {
	None,
	GameObject,
	ProgressToken,
	ShowDiscard,
	ShowLog,
	ShowMenu,
	DiscardForCoinConfirm,
	ConstructCardConfirm,
	SelectP1,
	SelectP2,
}

