package swd_engine

import "core:math/rand"
import "core:time"

select_random_move :: proc(game: ^Game, think_time_ms: int = 0) -> (selected_move: Move) {
	if think_time_ms > 0 {
		time.sleep(time.Millisecond * time.Duration(think_time_ms))
	}
	set_valid_moves(game)
	selected_move = rand.choice(game.valid_move_buffer[:])
	return
}

