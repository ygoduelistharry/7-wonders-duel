import numpy as np

import pandas as pd

import tkinter as tk


##### VIEW BELOW ####

##### MODEL BELOW ####

class Game:  # Define a single instance of a game

    def __init__(self, game_count=1):
        # Create a list of lists, one list per age containing the card objects for that age:
        self.age_boards = [Age(age) for age in range(1, 4)]
        self.game_count = game_count
        self.players = [Player(0, 'human'), Player(1, 'human')]
        self.game_state = GameState()

    def __repr__(self):
        return repr('Game Instance: ' + str(self.game_count))

        # TODO: Set up players
        #   First turn player
        #   Draft wonders
        #   Set up state

    def draft(self, player, age, position):  # TODO: consider making it based on game state
        if self.game_state.current_age != age:
            return print('Can only choose cards from current age!')
        if self.age_boards[age].card_positions[position].card_selectable == 0:
            return print('Card is covered, you cannot pick this card!')

        # Add card to players board, remove card from board, update visible and selectable cards
        self.players[player].cards_in_play.append(self.age_boards[age].card_positions[position].card_in_slot)
        self.age_boards[age].card_positions[position].card_in_slot = None
        self.age_boards[age].update_all()

        print(self.players[0])
        print(self.players[1])
        print(self.age_boards[age])

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
                 card_visible=1, card_selectable=0, covered_by=None):
        self.card_board_position = card_board_position
        self.game_age = game_age
        self.card_in_slot = card_in_slot
        self.card_visible = card_visible
        self.card_selectable = card_selectable
        if type(covered_by) is str:
            self.covered_by = [int(card) for card in str(covered_by).split(" ")]
        else:
            self.covered_by = []

    def __repr__(self):
        return repr('Age: ' + str(self.game_age)
                    + ', Position: ' + str(self.card_board_position)
                    + ', Card: ' + str(self.card_in_slot)
                    )


class Player:  # Create a class for play to track tableau cards, money, etc.
    def __init__(self, player_number=0, player_type='human'):
        self.player_number = player_number
        self.player_type = player_type
        self.gold = 7
        self.cards_in_play = []
        self.wonders_in_hand = []
        self.wonders_in_play = []
        self.vp = 0
        self.clay = 0
        self.wood = 0
        self.stone = 0
        self.paper = 0
        self.glass = 0
        self.victory_tokens = []

    def __repr__(self):
        return repr(self.cards_in_play)  # TODO show more info about player than this


class GameState:  # Create a class to manage the game state.
    def __init__(self, turn_player=0, current_age=0, military_track=0):
        self.turn_player = turn_player  # TODO Change later to determine first player randomly.
        self.current_age = current_age  # Start in first age.
        self.military_track = military_track  # Start military track at 0.


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
        self.card_positions = self.prepare_age_board(age)

    def __repr__(self):
        return repr(self.card_positions)  # TODO show more info about age than this

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
