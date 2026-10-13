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
	opponent := game.player_states[Player_ID(-1 * int(p_id))]

	// check for free linking symbol
	if object.cost.free_construction_symbol in player.linking_symbols {
		return {linking_symbol_used = true, can_afford = true}
	}

	building_coin_cost := object.cost.coins

	// check how many of each resource we need to trade for after using up "fixed" resource production.
	// this is effectively just brown and grey buildings
	// we also split the resource deficit into brown and grey to account for "varaible" resource production.
	extra_brown_res_required, extra_grey_res_required: int
	extra_res_required: [Resource]int
	for &value, resource in extra_res_required {
		value = max(0, object.cost.resources[resource] - player.resource_production[resource])
		if resource in brown_resources {extra_brown_res_required += value}
		if resource in grey_resources {extra_grey_res_required += value}
	}

	generic_brown_res_available := player.generic_brown_res_production
	generic_grey_res_available := player.generic_grey_res_production

	extra_brown_res_required = max(0, extra_brown_res_required - generic_brown_res_available)
	extra_grey_res_required = max(0, extra_grey_res_required - generic_grey_res_available)

	// do an early check for masonry and architecture
	total_extra_res_required := extra_brown_res_required + extra_grey_res_required
	generic_res_available := 0
	if (object.colour == .Blue && .Masonry in player.progress_tokens) ||
	   (object.colour == .Wonder && .Architecture in player.progress_tokens) {
		total_extra_res_required -= 2
		generic_res_available = 2
	}
	// if we can cover our production without considering trading then we are done. if not...
	if total_extra_res_required <= 0 {
		return {building_coin_cost, 0, false, building_coin_cost <= player.coins}
	}


	// if we have no varaible resource production, no need to sort.
	if generic_brown_res_available + generic_grey_res_available + generic_res_available <= 0 {
		traded_coin_cost := dot(player.resource_trade_price, extra_res_required)
		return {
			building_coin_cost + traded_coin_cost,
			traded_coin_cost,
			false,
			building_coin_cost + traded_coin_cost <= player.coins,
		}
	}
	// if we do, we need to know what the best way to spend "variable" resource production is
	resource_costs: [5]Resource_Key_Value_Pair = {
		{.Clay, player.resource_trade_price[.Clay]},
		{.Stone, player.resource_trade_price[.Stone]},
		{.Wood, player.resource_trade_price[.Wood]},
		{.Glass, player.resource_trade_price[.Glass]},
		{.Papyrus, player.resource_trade_price[.Papyrus]},
	}
	// sort resources from most to least expensive
	slice.sort_by(
		resource_costs[:],
		proc(i, j: Resource_Key_Value_Pair) -> bool {return i.value > j.value},
	)

	//iterate over the resource costs and decrement our avaialbe varaible resources until they are gone
	for kvp in resource_costs {
		// if kvp.value == 0 {continue}
		if kvp.resource in brown_resources {
			for extra_res_required[kvp.resource] > 0 && generic_brown_res_available > 0 {
				extra_res_required[kvp.resource] -= 1
				generic_brown_res_available -= 1
			}
		}
		if kvp.resource in grey_resources {
			for extra_res_required[kvp.resource] > 0 && generic_grey_res_available > 0 {
				extra_res_required[kvp.resource] -= 1
				generic_grey_res_available -= 1
			}
		}
		for extra_res_required[kvp.resource] > 0 && generic_res_available > 0 {
			extra_res_required[kvp.resource] -= 1
			generic_res_available -= 1
		}
	}
	traded_coin_cost := dot(player.resource_trade_price, extra_res_required)
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

