from numpy.random import default_rng
import pandas as pd
import tkinter as tk


# from tkinter import ttk


class Game:  # Define a single instance of a game

    def __init__(self, game_count=1):
        # Create a list of lists, one list per age containing the card objects for that age:
        self.age_boards = [Age(age) for age in range(1, 4)]
        self.game_count = game_count
        self.players = [Player(0, 'human'), Player(1, 'human')]
        self.state_variables = StateVariables()
        self.display_game_state()

    def __repr__(self):
        return repr('Game Instance: ' + str(self.game_count))

        # TODO:
        #   Draft wonders

    def request_player_input(self):  # TODO when using AI, no need for player input, just needs to print AI choice.
        choice = input("PLAYER " + str(self.state_variables.turn_player + 1) + ": "
                       + "Select a card to [c]onstruct or [d]iscard for coins. "
                       + "(Format is 'X#' where X is c/d and # is card position)")  # TODO select by name or number?
        action, position = choice[0], choice[1:]

        if action != 'c' and action != 'd':
            print("Select a valid action! (construct or discard)")
            return self.request_player_input()

        if not position.isdigit():
            print("Card choice must be an integer!")
            return self.request_player_input()

        self.select_card(int(position), action)

    # Main gameplay loop - players alternate choosing cards from the board and performing actions with them.
    def select_card(self, position, action='c'):

        # Turn player variables
        player = self.state_variables.turn_player
        player_state = self.players[player]
        player_board = player_state.cards_in_play

        # Opponent player variables
        opponent = player ^ 1  # XOR operator (changes 1 to 0 and 0 to 1)
        opponent_state = self.players[opponent]
        opponent_board = opponent_state.cards_in_play

        # Current age variables
        age = self.state_variables.current_age
        slots_in_age = self.age_boards[age].card_positions

        # Checks for valid card choices
        if position >= len(slots_in_age) or position < 0:
            print('Select a card on the board!')
            return self.request_player_input()

        chosen_position = slots_in_age[position]

        if chosen_position.card_in_slot is None:
            print('This card has already been chosen!')
            return self.request_player_input()

        if chosen_position.card_selectable == 0:
            print('Card is covered, you cannot pick this card!')
            return self.request_player_input()

        # Discard or construct chosen card and remove card from board
        match action:
            case 'c':  # Add card to board.
                if self.card_constructable(player_state, opponent_state, chosen_position.card_in_slot) is True:
                    self.construct_card(player_state, opponent_state, chosen_position.card_in_slot)
                else:
                    print('You do not have the resources required to construct this card!')
                    return self.request_player_input()
            case 'd':  # Gain coins based on yellow building owned.
                yellow_card_count = len([card for card in player_board if card.card_type == 'Yellow'])
                player_state.coins += 2 + yellow_card_count
            case _:
                print('This is not a valid action!')
                return self.request_player_input()
        chosen_position.card_in_slot = None
        player_state.update()

        # Check for end of age (all cards drafted)
        if all(slots_in_age[slot].card_in_slot is None for slot in range(len(slots_in_age))):
            self.state_variables.progress_age()
        else:  # Otherwise, update all cards in current age and change turn turn_player
            self.age_boards[age].update_all()
            self.state_variables.change_turn_player()  # TODO This might not always be true if go again wonders chosen

        if self.state_variables.game_end:
            self.display_game_state()
            return print('Game is over!')  # TODO check victory and stuff

        # Continue game loop.
        self.display_game_state()
        self.request_player_input()

    # Takes 2 Player objects and 1 Card object and checks whether card is constructable given state and cost.
    # TODO check whether card is constructable given arbitrary player/opponent/card objects
    def card_constructable(self, player, opponent, card):
        pass

    # Takes 2 Player objects and 1 Card object and constructs the card if possible. If it cannot, returns False.
    # TODO function to construct card (pay resources, add card to player board, gain on buy benefit) Note!
    #   removal of card from game board is done elsewhere! (in self.select_card method).
    def construct_card(self, player, opponent, card):
        pass

    def valid_moves(self, player, opponent, age):  # TODO return list of valid moves for current player.
        pass

    # Displays the game state in a nice enough way.
    def display_game_state(self):
        player = self.state_variables.turn_player
        age = self.state_variables.current_age

        self.age_boards[age].display_board()
        print("Player 1 >" + repr(self.players[0]))
        print("Player 2 >" + repr(self.players[1]))
        print("Current turn player is Player " + str(player + 1))

    # TODO: Other functions:
    #   Turn logic (states etc.)
    #   I/O for player input
    #   Function to return cards selectable in current board state


class Card:  # Define a class for a single card. These attributes match the .csv headers
    def __init__(self, card_name=0, card_set=0, card_type=0, card_cost=0, card_age=0, card_effect_passive=0,
                 card_effect_when_played=0, card_prerequisite=0):
        self.card_name = card_name
        self.card_set = card_set
        self.card_type = card_type
        self.card_cost = card_cost
        self.card_effect_passive = card_effect_passive
        self.card_effect_when_played = card_effect_when_played
        self.card_age = card_age
        self.card_prerequisite = card_prerequisite

    def __repr__(self):
        return repr(self.card_name)


class CardSlot:  # Create a class for a card slot on board to define selectability, visibility, etc.
    def __init__(self, card_in_slot=None, card_board_position=None, game_age=None,
                 card_visible=1, card_selectable=0, covered_by=None, row=None):
        self.card_board_position = card_board_position
        self.game_age = game_age
        self.card_in_slot = card_in_slot
        self.card_visible = card_visible
        self.card_selectable = card_selectable
        if type(covered_by) is str:
            self.covered_by = [int(card) for card in str(covered_by).split(" ")]
        else:
            self.covered_by = []
        self.row = row

    def __repr__(self):  # How the cards are displayed to the players.
        if self.card_in_slot is None:
            return repr("")

        if self.card_visible == 0:
            return repr("#" + str(self.card_board_position)
                        + " Hidden by " + repr(self.covered_by)
                        )

        return repr("#" + str(self.card_board_position)
                    + " " + repr(self.card_in_slot)
                    )


class Player:  # Create a class for play to track tableau cards, money, etc.
    def __init__(self, player_number=0, player_type='human'):
        # Private:
        self.player_number = player_number
        self.player_type = player_type

        # Update as card is chosen through Game.construct_card method:
        self.coins = 7
        self.cards_in_play = []
        self.wonders_in_hand = []
        self.wonders_in_play = []

        # Passive variables can be updated anytime based on cards_in_play via self.update() method.
        self.vp = 0
        self.clay = 0
        self.wood = 0
        self.stone = 0
        self.paper = 0
        self.glass = 0
        self.victory_tokens = []

    def __repr__(self):
        return repr(" Coins: " + str(self.coins)
                    + ", Board: " + repr(self.cards_in_play))

    def update(self):
        pass


class StateVariables:  # Create a class to manage the state variables.
    def __init__(self, turn_player=None, current_age=0, military_track=0):
        self.rng = default_rng()
        if turn_player is None:
            self.turn_player = self.rng.integers(low=0, high=2)  # Randomly select first player if none specified.
        self.current_age = current_age  # Start in first age.
        self.military_track = military_track  # Start military track at 0.
        self.game_end = False

    def change_turn_player(self):
        self.turn_player = self.turn_player ^ 1  # XOR operation to change 0 to 1 and 1 to 0

    def progress_age(self):
        if self.current_age < 2:
            self.current_age = self.current_age + 1
        else:
            self.game_end = True

        # TODO for progress age function: check military track for turn player and deal with end of game.


class Age:
    # Import card layout for each age:
    age_layouts = pd.read_csv('age_layout.csv', dtype={
        'game_age': 'category',
    })

    # Import full card list:
    card_list = pd.read_csv('card_list.csv', dtype={
        'card_set': 'category',  # Set as category to speed up filter
        'card_type': 'category',
        'card_age': 'category',
    })

    age_1_card_count = 20
    age_2_card_count = 20
    age_3_card_count = 17
    age_guild_card_count = 3

    def __init__(self, age):
        self.age = age
        self.card_positions = self.prepare_age_board(age)
        self.number_of_rows = max(self.card_positions[slot].row for slot in range(len(self.card_positions)))

    def __repr__(self):
        repr('Age ' + str(self.age + 1))

    # Init functions:
    def prepare_age_board(self, age):  # Takes dataframe of all cards and creates list of card objects representing
        # the board for the appropriate age.
        age = str(age)  # Convert to string if required
        age_layout = self.age_layouts.loc[self.age_layouts['game_age'] == age]. \
            reset_index(drop=True)  # Filter for age & reset index
        age_cards = self.card_list.loc[self.card_list['card_age'] == age]  # Filter for age

        match age:
            case '1':  # Select random cards for age 1
                age_cards = age_cards.sample(self.age_1_card_count).reset_index(drop=True)
            case '2':  # Select random cards for age 2
                age_cards = age_cards.sample(self.age_2_card_count).reset_index(drop=True)
            case '3':  # Select guild cards and cards for age 3
                guilds_chosen = self.card_list.loc[self.card_list['card_age'] == 'Guild'].sample(
                    self.age_guild_card_count)
                age_cards = age_cards.sample(self.age_3_card_count)
                age_cards = age_cards.append(guilds_chosen)  # Add guild cards and normal cards together
                age_cards = age_cards.sample(frac=1).reset_index(drop=True)  # Shuffle cards together
            case _:
                return

        # Unpack age layout dataframe in card slot objects
        card_positions = [CardSlot(**value)
                          for index, value
                          in age_layout.iterrows()]

        # Place card objects into card slots
        for slot in range(len(card_positions)):
            card_positions[slot].card_in_slot = Card(**age_cards.loc[slot])

        return card_positions

    def update_all(self):
        for slot in range(len(self.card_positions)):
            self.update_slot(slot)  # Update each slot for visibility and selectability.

    def update_slot(self, slot):
        if self.card_positions[slot].covered_by:  # Checks whether there are still cards covering this card.
            # Apparently the pythonic way to check a list is not empty is to see if the list is true... ¯\_(ツ)_/¯
            for covering_card in self.card_positions[slot].covered_by:  # Loops through list of
                # covering cards. Does it backwards to avoid index errors.
                if self.card_positions[covering_card].card_in_slot is None:  # Checks if covering card has been taken.
                    self.card_positions[slot].covered_by.remove(covering_card)  # If covering card has been taken,
                    # remove it from list of covering cards.

        if not self.card_positions[slot].covered_by:  # If no more covering cards, make card visible and selectable.
            self.card_positions[slot].card_selectable = 1
            self.card_positions[slot].card_visible = 1

    def display_board(self):
        cards = self.card_positions
        rows = self.number_of_rows
        for row in reversed(range(rows + 1)):
            print("Row " + str(row + 1) + ": " + repr([card for card in cards if card.row == row]))


class View:
    def __init__(self, game):
        self.game = game
        self.root = tk.Tk()
        self.root.title('7 Wonders Duel! ' + repr(game))
        self.root.geometry("640x480")
        self.refresh_all()
        self.root.mainloop()

    def __setattr__(self, key, value):  # Forces 'game' to be an object from the Game class.
        if key == 'game':
            if not isinstance(value, Game):
                raise ValueError('View object must take a Game object to view!')
        else:
            super(View, self).__setattr__(key, value)

    def refresh_all(self):
        pass
