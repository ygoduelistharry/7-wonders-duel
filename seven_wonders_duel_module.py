import numpy as np

import pandas as pd


class Card:  # Define a class for a single card. These attributes match the .csv headers
    def __init__(self, card_name=0, card_set=0, card_type=0, card_cost=0, card_age=0,
                 card_passive=0, card_on_play=0, card_prior=0,
                 card_board_position=0, card_visible=0, card_selectable=0):
        self.card_name = card_name
        self.card_set = card_set
        self.card_type = card_type
        self.card_cost = card_cost
        self.card_passive = card_passive
        self.card_on_play = card_on_play
        self.card_age = card_age
        self.card_prior = card_prior
        self.card_board_position = card_board_position
        self.card_visible = card_visible
        self.card_selectable = card_selectable

    def flip(self):
        if self.card_visible == 1:
            self.card_visible = 0
        else:
            self.card_visible = 1


class Deck:  # Create a deck from a dataframe of cards with an arbitrary number of attributes
    # (class from 'pandas' module)
    def __init__(self, card_list):
        self.card_list = card_list
        self.cards = []  # Initalise list of cards which will become the deck
        self.build()  # Calls the function to build the deck

    def build(self):  # Builds the deck
        card_num = 0
        while card_num < self.card_list.__len__():
            self.cards.append(Card())
            # Adds a card object to the deck for each card in datatable

            for class_argument in self.card_list.columns.values:  # List of attributes to define a card object
                setattr(self.cards[card_num], class_argument, getattr(self.card_list.iloc[card_num], class_argument))
            # When a card object created, it sets the attributes of the card to the matching attributes from datatable

            card_num += 1


class Player:  # Create a class for play to track tableau cards, money, etc.
    def __init__(self, player_number=0):
        self.player_number = player_number
        self.gold = 7
        self.cards = []
        self.wonders_in_hand = []
        self.wonders_in_play = []
        self.vp = 0
        self.clay = 0
        self.wood = 0
        self.stone = 0
        self.paper = 0
        self.glass = 0


def prepare_age(age, card_list, age_layout):  # Takes dataframe of all cards and initialises board for appropriate age

    age = str(age)  # Convert to string if required
    age_board = card_list.query('card_age==@age')

    if age == "1" or "2":
        age_board = age_board.sample(20).reset_index(drop=True)  # Select 20 random cards for age 1 or 2

    if age == "3":
        guilds_chosen = card_list.query('card_age=="Guild"').sample(3)  # Select 3 guild cards for age 3
        age_board = age_board.sample(17).reset_index(drop=True)  # Select 17 cards for age 3
        age_board = age_board.append(guilds_chosen)  # Add guild cards and normal cards together
        age_board = age_board.sample(frac=1).reset_index(drop=True)  # Shuffle cards together

    age_board = pd.concat([age_board, age_layout], axis=1)  # Add layout data to board

    return age_board
