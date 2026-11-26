package swd_engine

import "core:slice"


Object_Real_Cost :: struct {
	total_coin_cost:     int,
	traded_coin_cost:    int,
	linking_symbol_used: bool,
	can_afford:          bool,
}

Object_Base_Cost :: struct {
	coins:                    int,
	resources:                [Resource]int,
	free_construction_symbol: Linking_Symbol,
}

get_object_cost :: proc(
	object_name: Object_Name,
	game: Game,
	player_id: Maybe(Player_ID) = nil,
) -> Object_Real_Cost {
	p_id := player_id.? or_else game.turn_player
	object := objects_db[object_name]
	player := game.player_states[p_id]

	// check for free linking symbol
	if object.cost.free_construction_symbol in player.linking_symbols {
		return {linking_symbol_used = true, can_afford = true}
	}

	building_coin_cost := object.cost.coins

	// check how many of each resource we need to trade for after using up "fixed" resource production.
	// this is effectively just brown and grey buildings
	// we also split the resource deficit into brown and grey to account for "varaible" resource production.
	extra_res_req: [Resource]int
	#unroll for res in Resource {
		extra_res_req[res] = max(0, object.cost.resources[res] - player.resource_production[res])
	}
	extra_brown_res_req := extra_res_req[.Clay] + extra_res_req[.Stone] + extra_res_req[.Wood]
	extra_grey_res_req := extra_res_req[.Papyrus] + extra_res_req[.Glass]

	generic_brown_res_available := player.generic_brown_res_production
	generic_grey_res_available := player.generic_grey_res_production

	extra_brown_res_req = max(0, extra_brown_res_req - generic_brown_res_available)
	extra_grey_res_req = max(0, extra_grey_res_req - generic_grey_res_available)

	// do an early check for masonry and architecture
	total_extra_res_req := extra_brown_res_req + extra_grey_res_req
	generic_res_available := 0
	if (object.colour == .Blue && .Masonry in player.progress_tokens) ||
	   (object.colour == .Wonder && .Architecture in player.progress_tokens) {
		total_extra_res_req -= 2
		generic_res_available = 2
	}
	// if we can cover our production without considering trading then we are done. if not...
	if total_extra_res_req <= 0 {
		return {building_coin_cost, 0, false, building_coin_cost <= player.coins}
	}


	// if we have no varaible resource production, no need to sort.
	if generic_brown_res_available + generic_grey_res_available + generic_res_available <= 0 {
		traded_coin_cost := dot(player.resource_trade_price, extra_res_req)
		return {
			building_coin_cost + traded_coin_cost,
			traded_coin_cost,
			false,
			building_coin_cost + traded_coin_cost <= player.coins,
		}
	}

	// if we do, we need to know what the best way to spend "variable" resource production is:
	// get resources sorted by trade price in desc order
	sorted_resources := get_resources_sorted_by_value_desc(player.resource_trade_price)

	// iterate over the resource costs and decrement our avaialbe varaible resources until they are gone
	for res in sorted_resources {
		if res in brown_resources {
			for extra_res_req[res] > 0 && generic_brown_res_available > 0 {
				extra_res_req[res] -= 1
				generic_brown_res_available -= 1
			}
		}
		if res in grey_resources {
			for extra_res_req[res] > 0 && generic_grey_res_available > 0 {
				extra_res_req[res] -= 1
				generic_grey_res_available -= 1
			}
		}
		for extra_res_req[res] > 0 && generic_res_available > 0 {
			extra_res_req[res] -= 1
			generic_res_available -= 1
		}
	}

	traded_coin_cost := dot(player.resource_trade_price, extra_res_req)
	return {
		building_coin_cost + traded_coin_cost,
		traded_coin_cost,
		false,
		building_coin_cost + traded_coin_cost <= player.coins,
	}
}

get_all_object_costs :: proc(
	game: Game,
	player: Maybe(Player_ID),
) -> (
	object_costs: [Object_Name]Object_Real_Cost,
) {
	p_id := player.? or_else game.turn_player
	for object in Object_Name {
		object_costs[object] = get_object_cost(object, game, p_id)
	}
	return
}

get_resources_sorted_by_value_desc :: #force_inline proc(values: [Resource]int) -> [5]Resource {
	//optimal 5 element sorting network
	p0 := (u32(values[.Clay]) << 8) | u32(Resource.Clay)
	p1 := (u32(values[.Stone]) << 8) | u32(Resource.Stone)
	p2 := (u32(values[.Wood]) << 8) | u32(Resource.Wood)
	p3 := (u32(values[.Glass]) << 8) | u32(Resource.Glass)
	p4 := (u32(values[.Papyrus]) << 8) | u32(Resource.Papyrus)

	if p0 < p3 {p0, p3 = p3, p0}
	if p1 < p4 {p1, p4 = p4, p1}

	if p0 < p2 {p0, p2 = p2, p0}
	if p1 < p3 {p1, p3 = p3, p1}

	if p0 < p1 {p0, p1 = p1, p0}
	if p2 < p4 {p2, p4 = p4, p2}

	if p1 < p2 {p1, p2 = p2, p1}
	if p3 < p4 {p3, p4 = p4, p3}

	if p2 < p3 {p2, p3 = p3, p2}

	return {
		Resource(u8(p0)),
		Resource(u8(p1)),
		Resource(u8(p2)),
		Resource(u8(p3)),
		Resource(u8(p4)),
	}
}

