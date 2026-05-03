"""Card cost test functions for Seven Wonders Duel module"""
from pytest import mark
from seven_wonders_duel import swd

test_game = swd.Game(1)

def check_card_cost(card:swd.Card):
    return sum(card.costs.values())

@mark.parametrize("c",test_game.all_cards,ids=[c.name for c in test_game.all_cards])
def test_check_card_resource_costs(c:swd.Card):
    assert check_card_cost(c) == len(c.cost_string)
