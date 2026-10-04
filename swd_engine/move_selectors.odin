package swd_engine

import "core:math/rand"

execute_random_move_safe :: proc(game: ^Game) -> (selected_move: Move) {
	valid_moves := get_valid_moves(game^)
	selected_move = rand.choice(valid_moves[:])
	execute_move_unsafe(selected_move, game)
	return
}

