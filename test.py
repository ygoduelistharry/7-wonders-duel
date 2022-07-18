import csv
from numpy.random import default_rng

class Card:
    '''Define a single card. Attributes match the .csv headers'''

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
        return str(self.card_name)

class CardSlot:
    '''Define a card slot on board to represent selectability, visibility, etc.'''

    def __init__(self, card_in_slot=None, card_board_position=None, game_age=None,
                 card_visible=1, card_selectable=0, covered_by=None, row=None):
        self.card_board_position = card_board_position
        self.game_age = game_age
        self.card_in_slot = card_in_slot
        self.card_visible = card_visible
        self.card_selectable = card_selectable
        if covered_by:
            self.covered_by = [int(card) for card in str(covered_by).split(" ")]
        else:
            self.covered_by = []
        self.row = row

    def __repr__(self):  # How the cards are displayed to the players.
        if self.card_in_slot is None:
            return str("")

        if self.card_visible == 0:
            return str("#" + repr(self.card_board_position)
                       + " Hidden " + repr(self.covered_by)
                       )

        return str("#" + repr(self.card_board_position) + " "
                   + repr(self.card_in_slot)
                   )

# BEFORE INSTANCE OF GAME
with open('card_list.csv', encoding='UTF-8') as card_list:
    all_cards = [Card(**card) for card in csv.DictReader(card_list)] # import cards from csv

age_1_cards = [card for card in all_cards if card.card_age=="1"]
age_2_cards = [card for card in all_cards if card.card_age=="2"]
age_3_cards = [card for card in all_cards if card.card_age=="3"]
guild_cards = [card for card in all_cards if card.card_age=="Guild"]

with open('age_layout.csv', encoding='UTF-8') as age_layout:
    age_layouts = [CardSlot(**slot) for slot in csv.DictReader(age_layout)] # import cards from csv

age_1_layout = [slot for slot in age_layouts if slot.game_age=="1"]
age_2_layout = [slot for slot in age_layouts if slot.game_age=="2"]
age_3_layout = [slot for slot in age_layouts if slot.game_age=="3"]

# WITHIN INSTANCE OF GAME
rng = default_rng()

__chosen_age_1_cards = list(rng.choice(age_1_cards, size=20,replace=False))
__chosen_age_2_cards = list(rng.choice(age_2_cards, size=20,replace=False))
__chosen_age_3_cards = list(rng.choice(age_3_cards, size=17,replace=False))
__chosen_guild_cards = list(rng.choice(guild_cards, size=3,replace=False))

#__age_1_board =

print(all_cards[0])

___a = [1,2,3]
___b = list(___a)
___b.append(4)

#rng.shuffle(all_cards)
