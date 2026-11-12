package swd_engine

import "core:math/rand"

select_random_move :: proc(game: ^Game) -> (selected_move: Move) {
	valid_moves := get_valid_moves(game^)
	selected_move = rand.choice(valid_moves[:])
	return
}

