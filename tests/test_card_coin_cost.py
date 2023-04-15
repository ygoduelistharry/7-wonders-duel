"""Tests the card coin cost calculation function for a range of player states and cards"""
from pytest import mark
from seven_wonders_duel import swd

test_game = swd.Game()
basic_resource_list = ['C','W','S','P','G']
pre_req_card_list = [card.prerequisite for card in test_game.all_cards if card.prerequisite]

#Set up test cards
test_card_list = [card.name for card in test_game.all_cards if card.prerequisite]
test_card_list.extend([
    'Logging Camp',
    'Stone Reserve',
    'Lumber Yard',
    'Caravansery'
])

test_cards = [card for card in test_game.all_cards if card.name in test_card_list]

#Set up test player states
player_types = [        #Player numbers:
    '0x',               #0
    '1x_gb',            #1
    '1x_wo',            #2
    '2x_gb',            #3
    '2x_wo',            #4
    '1x_gb_1x_wo',      #5
    '3x_gb',            #6
    '3x_wo',            #7
    '0x_all_prereqs'    #8
]
test_players = {
    player:swd.Player(n) for n, player in enumerate(player_types)
}

for r in basic_resource_list:
    for p in ['1x_gb','1x_gb_1x_wo']:
        test_players[p].grey_brown_resources[r] = 1
    for p in ['2x_gb']:
        test_players[p].grey_brown_resources[r] = 2
    for p in ['3x_gb']:
        test_players[p].grey_brown_resources[r] = 3
    for p in ['1x_wo','1x_gb_1x_wo']:
        test_players[p].wonder_resources[r] = 1
    for p in ['2x_wo']:
        test_players[p].wonder_resources[r] = 2
    for p in ['3x_wo']:
        test_players[p].wonder_resources[r] = 3

for p in ['0x_all_prereqs']:
    test_players[p].cards_in_play = [card for card in test_game.all_cards if card.name in pre_req_card_list]

player_pairings = [   #17 Player pairings to test
    ('0x','0x'),                #0,0
    ('0x','1x_gb'),             #0,1
    ('0x','1x_gb_1x_wo'),       #0,5
    ('0x','3x_gb'),             #0,6
    ('0x','3x_wo'),             #0,7
    ('1x_gb','0x'),             #1,0
    ('1x_gb','1x_gb'),          #1,1
    ('1x_gb','1x_gb_1x_wo'),    #1,5
    ('1x_gb','3x_gb'),          #1,6
    ('1x_gb','3x_wo'),          #1,7
    ('3x_gb','1x_gb'),          #6,1
    ('3x_gb','3x_gb'),          #6,6
    ('1x_wo','3x_gb'),          #2,6
    ('3x_wo','3x_gb'),          #7,6
    ('0x_all_prereqs','0x'),    #8,0
    ('0x_all_prereqs','3x_wo'), #8,7
    ('0x_all_prereqs','3x_gb')  #8,6
]

test_results = []
for p, o in player_pairings:
    for c in test_cards:
        test_results.append((p,o,c.name,swd.card_coin_cost(test_players[p],test_players[o],c)))

@mark.parametrize("card",test_cards,ids=[card.name for card in test_cards])
@mark.parametrize("player,opponent",[(test_players[p],test_players[o]) for p, o in player_pairings],
                  ids=[p+" vs "+o for p, o in player_pairings])
def test_check_card_coin_costs(player:swd.Player, opponent:swd.Player, card:swd.Card):
    '''Checks the coin cost of certain cards for various player and opponent board states.'''
    coin_cost = swd.card_coin_cost(player,opponent,card)

    #Base costs all assume an opponent who has nothing at all in play.
    #The cost increase is how much the cost would increase to the purchasing player if their opponent had 1 of each
    #resource from grey/brown cards.
    base_case_0x = { #card_name:(base cost, increase per opp gb)
        'Horse Breeders' :(4,2),
        'Barracks'       :(4,0),
        'Library'        :(6,3),
        'Dispensary'     :(6,3),
        'Statue'         :(4,2),
        'Temple'         :(4,2),
        'Aqueduct'       :(6,3),
        'Fortifications' :(8,4),
        'Siege Workshop' :(8,4),
        'Circus'         :(8,4),
        'University'     :(6,3),
        'Observatory'    :(6,3),
        'Gardens'        :(8,4),
        'Pantheon'       :(8,4),
        'Senate'         :(8,4),
        'Lighthouse'     :(6,3),
        'Arena'          :(6,3),
        'Logging Camp'   :(1,0),
        'Stone Reserve'  :(3,0),
        'Lumber Yard'    :(0,0),
        'Caravansery'    :(6,2)
        }

    base_case_1x = { #card_name:(base cost, increase per opp gb)
        'Horse Breeders' :(0,0),
        'Barracks'       :(4,0),
        'Library'        :(0,0),
        'Dispensary'     :(2,1),
        'Statue'         :(2,1),
        'Temple'         :(0,0),
        'Aqueduct'       :(4,2),
        'Fortifications' :(2,1),
        'Siege Workshop' :(4,2),
        'Circus'         :(4,2),
        'University'     :(0,0),
        'Observatory'    :(2,1),
        'Gardens'        :(4,2),
        'Pantheon'       :(2,1),
        'Senate'         :(2,1),
        'Lighthouse'     :(2,1),
        'Arena'          :(0,0),
        'Logging Camp'   :(1,0),
        'Stone Reserve'  :(3,0),
        'Lumber Yard'    :(0,0),
        'Caravansery'    :(2,0)
        }

    base_case_3x = { #card_name:(base cost, increase per opp gb)
        'Horse Breeders' :(0,0),
        'Barracks'       :(4,0),
        'Library'        :(0,0),
        'Dispensary'     :(0,0),
        'Statue'         :(0,0),
        'Temple'         :(0,0),
        'Aqueduct'       :(0,0),
        'Fortifications' :(0,0),
        'Siege Workshop' :(0,0),
        'Circus'         :(0,0),
        'University'     :(0,0),
        'Observatory'    :(0,0),
        'Gardens'        :(0,0),
        'Pantheon'       :(0,0),
        'Senate'         :(0,0),
        'Lighthouse'     :(0,0),
        'Arena'          :(0,0),
        'Logging Camp'   :(1,0),
        'Stone Reserve'  :(3,0),
        'Lumber Yard'    :(0,0),
        'Caravansery'    :(2,0)
        }

    base_case_all_prereqs = { #card_name:(base cost, increase per opp gb)
        'Horse Breeders' :(0,0),
        'Barracks'       :(0,0),
        'Library'        :(0,0),
        'Dispensary'     :(0,0),
        'Statue'         :(0,0),
        'Temple'         :(0,0),
        'Aqueduct'       :(0,0),
        'Fortifications' :(0,0),
        'Siege Workshop' :(0,0),
        'Circus'         :(0,0),
        'University'     :(0,0),
        'Observatory'    :(0,0),
        'Gardens'        :(0,0),
        'Pantheon'       :(0,0),
        'Senate'         :(0,0),
        'Lighthouse'     :(0,0),
        'Arena'          :(0,0),
        'Logging Camp'   :(1,0),
        'Stone Reserve'  :(3,0),
        'Lumber Yard'    :(0,0),
        'Caravansery'    :(6,2)
        }

    if player.player_number in [0]: #5/17 (5) pairings
        match opponent.player_number:
            case 0 | 7 :
                assert coin_cost == base_case_0x[card.name][0]
            case 1 | 5:
                assert coin_cost == base_case_0x[card.name][0]+1*base_case_0x[card.name][1]
            case 6:
                assert coin_cost == base_case_0x[card.name][0]+3*base_case_0x[card.name][1]
            case _:
                return

    if player.player_number in [1, 2]: #6/17 (11) pairings
        match opponent.player_number:
            case 0 | 7:
                assert coin_cost == base_case_1x[card.name][0]
            case 1 | 5:
                assert coin_cost == base_case_1x[card.name][0]+1*base_case_1x[card.name][1]
            case 6:
                assert coin_cost == base_case_1x[card.name][0]+3*base_case_1x[card.name][1]
            case _:
                return

    if player.player_number in [6, 7]: #3/17 (14) pairings
        assert coin_cost == base_case_3x[card.name][0]

    if player.player_number in [8]: #4/17 (17) pairings
        match opponent.player_number:
            case 0 | 7:
                assert coin_cost == base_case_all_prereqs[card.name][0]
            case 6:
                assert coin_cost == base_case_all_prereqs[card.name][0]+3*base_case_all_prereqs[card.name][1]
