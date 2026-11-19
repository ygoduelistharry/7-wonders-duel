package swd_ui

import "core:log"
import swd "swd_engine"

Agent :: enum {
	Randy_Savage,
}

load_ai_thread_data :: proc(game: ^swd.Game, agent: Agent) -> AI_Thread_Data {
	switch agent {
	case .Randy_Savage:
		{
			return {game = game, move_selector = swd.select_random_move, think_time_ms = 1500}
		}
	}
	log.warnf("Agent %v did not load correctly!", agent)
	return {}
}

