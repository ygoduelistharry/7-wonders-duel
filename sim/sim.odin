package swd_sim

import swd "../swd_engine"
import "base:runtime"
import "core:fmt"
import "core:prof/spall"
import "core:sync"
import "core:time"


ENABLE_SPALL :: #config(ENABLE_SPALL, false)
when ENABLE_SPALL {
	spall_ctx: spall.Context
	@(thread_local)
	spall_buffer: spall.Buffer

	@(instrumentation_enter)
	spall_enter :: proc "contextless" (
		proc_address, call_site_return_address: rawptr,
		loc: runtime.Source_Code_Location,
	) {
		spall._buffer_begin(&spall_ctx, &spall_buffer, "", "", loc)
	}

	@(instrumentation_exit)
	spall_exit :: proc "contextless" (
		proc_address, call_site_return_address: rawptr,
		loc: runtime.Source_Code_Location,
	) {
		spall._buffer_end(&spall_ctx, &spall_buffer)
	}
}

main :: proc() {
	fmt.printfln("Running random simulations!")
	fmt.printfln("%v", size_of(swd.Move))
	fmt.printfln("%v", size_of(bool))
	run_count := 100_000
	game: swd.Game
	selected_move: swd.Move
	start_tick := time.tick_now()

	when ENABLE_SPALL {
		spall_ctx = spall.context_create("trace_test.spall")
		defer spall.context_destroy(&spall_ctx)

		buffer_backing := make([]u8, spall.BUFFER_DEFAULT_SIZE)
		defer delete(buffer_backing)

		spall_buffer = spall.buffer_create(buffer_backing, u32(sync.current_thread_id()))
		defer spall.buffer_destroy(&spall_ctx, &spall_buffer)
	}

	for _ in 0 ..< run_count {
		game = swd.create_new_game(123)
		for game.completed == false {
			selected_move = swd.select_random_move(&game)
			swd.execute_move_unsafe(&selected_move, &game)
		}
	}
	fmt.printfln("%v runs completed in %v.", run_count, time.tick_since(start_tick))
}

