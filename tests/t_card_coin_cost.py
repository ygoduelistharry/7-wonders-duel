"""Tests the card coin cost calculation function for a range of player states and cards"""
from pytest import mark
from seven_wonders_duel import swd

test_game = swd.Game()
basic_resource_list = ['C','W','S','P','G']
pre_req_cards = [card.card_name for card in test_game.all_cards if card.card_prerequisite]

#Set up test cards
test_cards = pre_req_cards
for cards in [
    'Logging Camp',
    'Stone Reserve',
    'Lumber Yard',
    'Caravansery'
]:
    test_cards.append(cards)

#Set up test players
player_types = [
    '0x',
    '1x_gb',
    '1x_wo',
    '2x_gb',
    '2x_wo',
    '1x_gb_1x_wo',
    '3x_gb',
    '3x_wo',
    '0x_all_prereqs'
]
test_players = {
    player:swd.Player() for player in player_types
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
    test_players[p].cards_in_play = pre_req_cards
