"""Use the Seven Wonders Duel module to do stuff"""
from seven_wonders_duel import swd

game1 = swd.Game(1,1)
game1.players[0].coins = 1000
game1.players[1].coins = 1000
for x in range(60):
    game1.select_card(x%20)
game1.request_player_input(display=True)
