package swd_engine

Science_Symbol :: enum u8 {
	Astrolabe,
	Scales,
	Sundial,
	Mortar_And_Pestle,
	Frame,
	Quill,
	Wheel,
}

Progress_Token :: enum u16 {
	Agriculture,
	Architecture,
	Economy,
	Law,
	Masonry,
	Mathematics,
	Philosophy,
	Strategy,
	Theology,
	Urbanism,
}
Progress_Tokens :: distinct bit_set[Progress_Token;u16]
@(rodata)
progress_token_description: [Progress_Token]string = {
	.Agriculture  = "Gain 6 coins. Worth 4 VP.",
	.Architecture = "Future Wonders built by you cost 2 fewer resources.",
	.Economy      = "You gain money spent by your opponent when they trade for resources",
	.Law          = "Worth 1 scientific symbol.",
	.Masonry      = "Blue cards built by you cost 2 fewer resources.",
	.Mathematics  = "Worth 3 VP per Progress token at end of game (including itself).",
	.Philosophy   = "Worth 7 VP",
	.Strategy     = "Red cards built by you provide +1 shield.",
	.Theology     = "Future Wonders built by you have 'Play Again'",
	.Urbanism     = "Gain 6 coins. When constructing a building for free via linking symbol, gain 4 coins.",
}

Linking_Symbol :: enum u32 {
	None,
	Stable,
	Garrison,
	Palisade,
	Archery_Range,
	Parade_Ground,
	Scriptorium,
	Pharmacist,
	School,
	Laboratory,
	Theatre,
	Statue,
	Altar,
	Temple,
	Baths,
	Rostrum,
	Tavern,
	Brewery,
}
Linking_Symbols :: distinct bit_set[Linking_Symbol;u32]

Military_Token :: enum u8 {
	P1_2,
	P1_5,
	P2_2,
	P2_5,
}
Military_Tokens :: distinct bit_set[Military_Token;u8]

Object_Colour :: enum u8 {
	Brown,
	Grey,
	Yellow,
	Green,
	Red,
	Blue,
	Purple,
	Wonder,
}

Resource :: enum u8 {
	Clay,
	Stone,
	Wood,
	Glass,
	Papyrus,
}
Resources :: distinct bit_set[Resource;u8]
Resource_Key_Value_Pair :: struct {
	resource: Resource,
	value:    int,
}
@(rodata)
brown_resources: Resources = {.Clay, .Stone, .Wood}
@(rodata)
grey_resources: Resources = {.Glass, .Papyrus}

object_kind_dot_product :: proc(r1, r2: [Object_Colour]int) -> int {
	sum: int
	for object in Object_Colour {
		sum += r1[object] * r2[object]
	}
	return sum
}
resource_dot_product :: proc(r1, r2: [Resource]int) -> (sum: int) {
	for resource in Resource {
		sum += r1[resource] * r2[resource]
	}
	return sum
}
dot :: proc {
	resource_dot_product,
	object_kind_dot_product,
}


Guild :: enum u8 {
	None,
	Builders_Guild,
	Moneylenders_Guild,
	Scientists_Guild,
	Shipowners_Guild,
	Merchants_Guild,
	Magistrates_Guild,
	Tacticians_Guild,
}
Guilds :: distinct bit_set[Guild;u8]


Player_ID :: enum i8 {
	P1 = -1,
	P2 = 1,
}
other_player_id :: proc(player_id: Player_ID) -> Player_ID {return Player_ID(-1 * int(player_id))}

Age :: enum u8 {
	DraftWonders,
	Age1,
	Age2,
	Age3,
}

Choice_State :: enum u16 {
	Game_Over,
	Choose_Wonder_To_Draft,
	Choose_Object_To_Construct_Or_Discard,
	Choose_Progress_Token,
	Choose_Unavailable_Progress_Token,
	Choose_Brown_Card_To_Destroy,
	Choose_Grey_Card_To_Destroy,
	Choose_Card_To_Revive,
	Choose_First_Player,
}

@(rodata)
choice_state_text: [Choice_State]string = {
	.Game_Over                             = "Game over.",
	.Choose_Wonder_To_Draft                = "Choose a wonder to draft.",
	.Choose_Object_To_Construct_Or_Discard = "Choose an object to construct or discard.",
	.Choose_Progress_Token                 = "Choose a progress token.",
	.Choose_Unavailable_Progress_Token     = "Choose a progress token.",
	.Choose_Brown_Card_To_Destroy          = "Choose a Brown card to destroy.",
	.Choose_Grey_Card_To_Destroy           = "Choose a Grey card to destroy.",
	.Choose_Card_To_Revive                 = "Choose a card to revive.",
	.Choose_First_Player                   = "Choose which player goes first.",
}

Move_Kind :: enum {
	None,
	Draft_Wonder,
	Construct_Card,
	Construct_Wonder,
	Discard_For_Coins,
	Select_Progress_Token,
	Select_Card,
	Select_Player,
}

Victory_Type :: enum {
	None,
	Military,
	Science,
	Civilian,
}

