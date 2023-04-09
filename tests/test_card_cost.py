""" Card cost test functions for Seven Wonders Duel module"""
import seven_wonders_duel as swd

test_game = swd.Game(1)

def check_card_costs():
    check_cost_sum = []
    for card in test_game.all_cards:
        if len(card.card_cost_string) == sum(card.card_costs.values()):
            check_cost_sum.append(True)
        else:
            check_cost_sum.append(False)

    return {
        'Cards checked':len(check_cost_sum),
        'Cards with correct cost sum':check_cost_sum.count(True),
        'Cards with incorrect cost sum':check_cost_sum.count(False)
    }

def test_check_card_costs():
    assert {
        'Cards checked':73,
        'Cards with correct cost sum':73,
        'Cards with incorrect cost sum':0
    }
