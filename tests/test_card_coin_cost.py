"""Tests the card coin cost calculation function for a range of player states and cards"""
from pytest import mark
from seven_wonders_duel import swd

test_players = [swd.Player(n) for n in range(100)]

print(test_players[0])
