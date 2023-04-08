""" Test functions for Seven Wonders Duel module"""

import pytest
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



def sim_game_discard_only():
    '''Players alternate between buying cards until game ends'''
    rng = swd.default_rng()
    for _ in range(60):
        age = test_game.common_variables.current_age
        slots = test_game.age_boards[str(age)].card_slots
        choices = [card.card_board_position for card in slots if card.card_selectable == 1 and card.card_in_slot is not None]
        choice = rng.choice(choices, size=1)[0]
        test_game.select_card(choice,'d')

    return {
        'Turn count':test_game.turn_count,
        'Current age':test_game.common_variables.current_age,
        'P1 card count':len(test_game.players[0].cards_in_play),
        'P2 card count':len(test_game.players[1].cards_in_play),
        'P1 coin count':test_game.players[0].coins,
        'P2 coin count':test_game.players[1].coins
    }

def test_sim_game_discard_only():
    assert sim_game_discard_only() == {
        'Turn count':60,
        'Current age':3,
        'P1 card count':0,
        'P2 card count':0,
        'P1 coin count':67,
        'P2 coin count':67
    }

def test_check_card_costs():
    assert {
        'Cards checked':73,
        'Cards with correct cost sum':73,
        'Cards with incorrect cost sum':0
    }
