"""Use the Seven Wonders Duel module to do stuff"""
import pickle
from seven_wonders_duel import swd

game = swd.Game()
print(game.state)
game.get_graph().draw('swd_statediagram.png', prog='dot')

pass

# Run a game sim:
# def run_sims(number_of_games = 1):
#     const_logs = {}
#     for n in range(number_of_games):
#         game = swd.Game(game_id=n, active=False, log=True, random_moves=True)
#         game.players[0].coins = 1000
#         game.players[1].coins = 1000
#         for x in range(60):
#             game.select_card(x%20)
#         const_logs.update(game.construction_log)
#     return const_logs

# Uncomment to run some sims and save the card construction logs!
#logs = run_sims(10000)

# with open('construction_logs_1.pkl', 'wb') as f:
#     pickle.dump(logs,f)

# with open('construction_logs_1.pkl', 'rb') as f:
#     construction_logs = pickle.load(f)

# masonry_check = {
#     k:v for k,v in construction_logs.items() if
#         "Masonry" in [token.name for token in construction_logs[k]['turn_player_tokens']]
#         and construction_logs[k]['card colour'] == "Blue"
#         and construction_logs[k]['cost'] > 0
# }

# forum_check = {
#     k:v for k,v in construction_logs.items()
#         if construction_logs[k]['turn_player_y']['P/G'] > 0
#         and construction_logs[k]['card cost']['P'] > 0
#         and construction_logs[k]['card cost']['G'] > 0
#         and construction_logs[k]['cost'] > 0
#         and construction_logs[k]['opp_player_gb']['P'] != construction_logs[k]['opp_player_gb']['G']
# }

pass
