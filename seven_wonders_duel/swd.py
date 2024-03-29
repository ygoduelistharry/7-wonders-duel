"""Classes and functions to run Seven Wonders Duel game logic"""
import os
import csv
from fractions import Fraction
from math import floor
from dataclasses import dataclass
from ast import literal_eval as leval
from numpy.random import default_rng
from transitions import State
from transitions.extensions import GraphMachine
from sty import fg, bg, rs
from enum import Enum, auto

# Random helper stuff not directly related to game logic:
os.chdir(os.path.dirname(os.path.abspath(__file__)))

def csv_to_class(csv_file:str, to_class, string=False):
    """Converts a .csv to a list of class objects of type to_class.  Class must take only kwargs as variables.
    The .csv headers must match the kwargs of the to_class.

    Args:
        csv_file (str): .csv filename.
        to_class (_type_): Class objects to be generated.
        string (bool, optional): Set string=True to retain kwargs as strings. Defaults to False.
        Uses ast.literal_eval() to convert all kwargs to non-string types. 

    Returns:
        (list): list of generated 'to_class' objects
    """

    with open(csv_file, encoding='UTF-8') as file:
        kwarg_dict_list = list(csv.DictReader(file))
    file.close()

    if string is False:
        for kwarg_dict in kwarg_dict_list:
            for key, value in kwarg_dict.items():
                try:
                    kwarg_dict[key] = leval(value)
                except SyntaxError:
                    pass
                except ValueError:
                    pass

    return [to_class(**kwargs) for kwargs in kwarg_dict_list]


# Game objects and logic starts here:
@dataclass
class Constructable:
    """Common attributes of a constructable object, i.e. Card or Wonder"""
    colour_key = {
        'Brown': bg(100, 50, 0) + fg.white,
        'Grey': bg.grey + fg.black,
        'Red': bg.red + fg.white,
        'Green': bg(0, 128, 0) + fg.white,
        'Yellow': bg.yellow + fg.black,
        'Blue': bg.blue + fg.white,
        'Purple': bg(128, 0, 128) + fg.white,
        'Wonder': bg.black + fg.yellow
    }
    name:                   str = ''
    set:                    str = ''
    cost_string:            str = ''
    passive_string:         str = ''
    on_play_string:         str = ''
    victory_point_string:   str = ''

    def __post_init__(self):
        self.costs = {
            'C':0, #Clay
            'W':0, #Wood
            'S':0, #Stone
            'P':0, #Paper
            'G':0, #Glass
            '$':0  #Coins
        }
        if self.cost_string:
            for resource in self.cost_string:
                self.costs[resource] += 1

        self.passives = {
            'C':0,      #Clay
            'W':0,      #Wood
            'S':0,      #Stone
            'P':0,      #Paper
            'G':0,      #Glass
            'P/G':0,    #Forum / Piraeus
            'W/C/S':0,  #Caravansery / The Great Lighthouse
            '1':0,      #Victory Symbol (Frame)
            '2':0,      #Victory Symbol (Wheel)
            '3':0,      #Victory Symbol (Quill & Ink)
            '4':0,      #Victory Symbol (Mortal & Pestle)
            '5':0,      #Victory Symbol (Sundial)
            '6':0,      #Victory Symbol (Astrolabe)
            '7':0       #Victory Symbol (Scales)
        }
        if '/' in str(self.passive_string):
            self.passives[self.passive_string] += 1
        else:
            for symbol in str(self.passive_string):
                self.passives[symbol] += 1

        self.on_plays = {
            'M':0,                  #Military Shields
            '$':0,                  #Coins
            '$ per Grey':0,         #Coin per Grey Building
            '$ per Brown':0,        #Coin per Brown Building
            '$ per Grey/Brown':0,   #Coin per Grey & Brown Building (Shipowners Guild)
            '$ per Red':0,          #Coin per Red Building
            '$ per Yellow':0,       #Coin per Yellow Building
            '$ per Blue':0,         #Coin per Blue Building
            '$ per Green':0,        #Coin per Green Building
            '$ per Wonder':0,       #Coin per Wonder
            'x':0                   #Opponent loses x coins
        }
        if '$ per ' in str(self.on_play_string):
            coin_per_obj = self.on_play_string.partition(' per ')
            self.on_plays['$ per ' + coin_per_obj[2]] += len(coin_per_obj[0])
        else:
            for resource in self.on_play_string:
                self.on_plays[resource] += 1

        self.victory_points = {
            'VP':0,                 #Victory Points
            'VP per Grey':0,        #Victory Points per Grey Building
            'VP per Brown':0,       #Victory Points per Brown Building
            'VP per Grey/Brown':0,  #Victory Points per Grey & Brown Building (Shipowners Guild)
            'VP per Red':0,         #Victory Points per Red Building
            'VP per Yellow':0,      #Victory Points per Yellow Building
            'VP per Blue':0,        #Victory Points per Blue Building
            'VP per Green':0,       #Victory Points per Green Building
            'VP per Wonder':0,      #Victory Points per Wonder
            'VP per $':0            #Victory Points per Coin
        }
        if ' per ' in str(self.victory_point_string):
            vp_per_obj = self.victory_point_string.partition(' per ')
            self.victory_points['VP per ' + vp_per_obj[2]] += Fraction(vp_per_obj[0])
        elif self.victory_point_string:
            self.victory_points['VP'] += int(self.victory_point_string)

@dataclass
class Card(Constructable):
    """Define a single card. Attributes match the .csv headers."""
    age:               str = ''
    colour:            str = ''
    prerequisite:      str = ''

    def __repr__(self):
        return str(Card.colour_key[self.colour]
                   + self.name
                   + rs.all)

@dataclass
class Wonder(Constructable):
    '''Define a single wonder. Attributes match the .csv headers.'''
    wonder_effect:     str = ''
    go_again:          bool = False

    def __repr__(self):
        return str(Wonder.colour_key['Wonder']
                   + self.name
                   + rs.all)

@dataclass
class Token:
    """Define a progress token. Attributes match the .csv headers"""
    colour_key = {'Token': bg(0, 128, 0) + fg.black}
    name:           str = ''
    token_effect:   str = ''

    def __repr__(self):
        return str(Token.colour_key['Token']
                   + self.name
                   + rs.all)

class Player:
    '''Define a class for play to track tableau cards, money, etc.'''

    def __init__(self, player_number=0, player_type='human'):
        # Private:
        self.player_number = player_number
        self.player_type = player_type

        # Update as card is chosen through Game.construct_card method:
        self.coins = 7
        self.cards_in_play:     list[Card] = []
        self.wonders_in_hand:   list[Wonder] = []
        self.wonders_in_play:   list[Wonder] = []
        self.tokens_in_play:    list[Token] = []

        # Passive variables can be updated anytime based on cards_in_play via self.update() method.
        self.grey_brown_resources = {
            'C':0, #Clay
            'W':0, #Wood
            'S':0, #Stone
            'P':0, #Paper
            'G':0, #Glass
        }

        self.wonder_resources = {
            'C':0,      #Clay
            'W':0,      #Wood
            'S':0,      #Stone
            'P':0,      #Paper
            'G':0,      #Glass
            'P/G':0,    #Piraeus
            'W/C/S':0,  #The Great Lighthouse
        }

        self.yellow_resources = {
            'C':0,      #Clay
            'W':0,      #Wood
            'S':0,      #Stone
            'P':0,      #Paper
            'G':0,      #Glass
            'P/G':0,    #Forum
            'W/C/S':0,  #Caravansery
        }

        self.victory_symbols = {
            '1':0, #Victory Symbol (Frame)
            '2':0, #Victory Symbol (Wheel)
            '3':0, #Victory Symbol (Quill & Ink)
            '4':0, #Victory Symbol (Mortal & Pestle)
            '5':0, #Victory Symbol (Sundial)
            '6':0, #Victory Symbol (Astrolabe)
            '7':0  #Victory Symbol (Law)
        }

    def __repr__(self):
        return str(" Coins: " + repr(self.coins)
                   + "\nCards: " + repr(self.cards_in_play)
                   + "\nWonders: " + repr(self.wonders_in_play)
                   + "\nTokens:" + repr(self.tokens_in_play)
                )

    def has_card(self, card_name:str):
        '''Checks if player has a card named card_name.'''
        if any(card.name == card_name for card in self.cards_in_play):
            return True
        return False

    def has_wonder(self, wonder_name:str):
        '''Checks if player has a wonder named wonder_name.'''
        if any(wonder.name == wonder_name for wonder in self.wonders_in_play):
            return True
        return False

class CardSlot:
    '''Define a card slot on board to represent selectability, visibility, etc.'''
    # TODO covered_by doesnt work when covered by 0 only (age 2 pos 2, age 3 pos 2).
    # TODO Changed .csv to "0" instead of 0 to fix above, but would like to fix here.
    def __init__(self, card_in_slot:Card=None, card_board_position=None, game_age=None,
                 card_visible=1, card_selectable=0, covered_by=None, row=None):
        self.card_board_position    = card_board_position
        self.row                    = row
        self.game_age               = game_age
        self.card_in_slot           = card_in_slot
        self.card_visible           = card_visible
        self.card_selectable        = card_selectable
        if covered_by:
            self.covered_by = [int(card) for card in str(covered_by).split(" ")]
        else:
            self.covered_by = []

    def __repr__(self):  # How the cards in structure are displayed to the players.
        if self.card_in_slot is None:
            return str("")

        if self.card_visible == 0:
            return str("#" + repr(self.card_board_position)
                       + " Hidden " + repr(self.covered_by)
                       )

        return str("#" + repr(self.card_board_position) + " "
                   + repr(self.card_in_slot)
                   )

class Age:
    '''Class to define a game age and represent the unique board layouts.'''

    all_card_slots = csv_to_class('age_layout.csv', CardSlot)

    ages = [1,2,3]
    age_card_counts = {
        '1':{'1':20},
        '2':{'2':20},
        '3':{'3':17,'Guild':3}
    }
    age_layouts = {}

    for age in ages:
        age_layout = []
        for slot in all_card_slots:
            if slot.game_age == age:
                age_layout.append(slot)
        age_layouts[str(age)] = age_layout

    # Generates a dict of lists holding initial card slot details for each age.
    # Couldn't use nested dict/list comprehension because inner comprehesions cant access outer scope to iterate over,
    # namely all_card_slots.

    def __init__(self, age):
        self.rng = default_rng()
        self.age = age
        self.card_slots = self.prepare_age_board(age)

    def __repr__(self):
        return str('Age ' + str(self.age))

    # Init functions:

    def prepare_age_board(self, age):
        '''Generates a game board for a specified age'''
        # Randomly select cards from card pool(s) based on age, card type, and quantity specified in age_card_counts.
        age_cards = [] # Will be a list of card objects selected randomly from all_cards.

        for card_type, count in self.age_card_counts[str(age)].items():
            card_pool = [card for card in Game.all_cards if str(card.age)==card_type]
            chosen_cards = list(self.rng.choice(card_pool, size=count, replace=False))
            age_cards.extend(chosen_cards)

        self.rng.shuffle(age_cards) # Shuffle required when multiple card types are selected (i.e. 3rd Age).

        initial_age_board = self.age_layouts[str(age)] # Selects appropriate list of CardSlot objects for age.

        if len(initial_age_board) != len(age_cards):
            return print('Number of card slots in chosen age does not match the number of cards selected!')

        # Place card objects into card slots
        for position, card in enumerate(age_cards):
            initial_age_board[position].card_in_slot = card

        return initial_age_board

    def update_all_slots(self):
        '''Updates all slots on board as per update_slot method'''
        for slot in range(len(self.card_slots)):
            self.update_slot(slot)  # Update each slot for visibility and selectability.

    def update_slot(self, slot):
        '''Updates card in a single slot for visibility, selectability, etc.'''
        if self.card_slots[slot].covered_by:  # Checks whether there are still cards covering this card.
            # Apparently the pythonic way to check a list is not empty is to see if the list is true... ¯\_(ツ)_/¯
            for covering_card in self.card_slots[slot].covered_by:  # Loops through list of
                # covering cards. Does it backwards to avoid index errors.
                if self.card_slots[covering_card].card_in_slot is None:  # Checks if covering card has been taken.
                    self.card_slots[slot].covered_by.remove(covering_card)  # If covering card has been taken,
                    # remove it from list of covering cards.

        if not self.card_slots[slot].covered_by:  # If no more covering cards, make card visible and selectable.
            self.card_slots[slot].card_selectable = 1
            self.card_slots[slot].card_visible = 1

    def display_board(self):
        '''Prints visual representation of cards remaining on the board for this age'''
        cards = self.card_slots
        rows = max(self.card_slots[slot].row for slot in range(len(self.card_slots)))
        for row in reversed(range(int(rows) + 1)):
            print("Row", str(row + 1), ":", [card for card in cards if int(card.row) == row])

class Action(Enum):
    """Define enum of valid actions for a Move"""
    DRAFT_WONDER = auto()
    CONSTRUCT_CARD = auto()
    DISCARD_CARD = auto()
    CONSTRUCT_WONDER = auto()

@dataclass
class Move:
    """Define a move"""
    action:     Action
    wonder:     Wonder = None
    card:       Card = None
    special:    Card | Token = None
    cost:       int = 0

    def __repr__(self):
        match self.action:
            case Action.DRAFT_WONDER:
                return str("Draft " + self.wonder.name)
            case Action.CONSTRUCT_CARD:
                return str("Construct " + self.card.name)
            case Action.DISCARD_CARD:
                return str("Discard " + self.card.name)
            case Action.CONSTRUCT_WONDER:
                if self.special is None:
                    return str("Construct " + self.wonder.name + ", discarding " + self.card.name)
                else:
                    return str("Construct " + self.wonder.name + ", discarding " + self.card.name +
                               ", selecting " + self.special.name)


class Game:
    '''Define a single instance of a game.'''
    all_cards = csv_to_class('card_list.csv',Card)
    all_wonders = csv_to_class('wonder_list.csv',Wonder)
    all_tokens = csv_to_class('token_list.csv',Token)

    # Define states and transitions to model players decision making during game.
    # To be passed to a Machine() object from 'transitions' module.
    states = [
        'start_phase',
        State('draft_phase', on_enter='_set_valid_moves'),
        State('game_phase', on_enter='_set_valid_moves'),
        State('_turn_end', on_enter='_resolve_turn'),
        State('game_end', on_enter='_set_victor')
    ]

    def create_transitions(model):
        add_t = model.state_machine.add_transition

        add_t('begin_draft_phase', 'start_phase', 'draft_phase')

        add_t('make_move', 'draft_phase', '=', conditions=['is_valid_move'], before=['_draft_wonder','_record_move'], after='begin_game_phase')
        add_t('begin_game_phase', 'draft_phase', 'game_phase', conditions=['all_wonders_drafted'])

        add_t('make_move', 'game_phase', '_turn_end', conditions=['is_valid_move'], before=['_play_card','_record_move'])

        add_t('continue_game', '_turn_end', 'game_phase', unless=['end_game_triggered'])
        add_t('finish_game', '_turn_end', 'game_end', conditions=['end_game_triggered'])

    model_config = dict(auto_transitions=False, show_conditions=True, show_state_attributes=True)

    def __init__(self, game_id=1, first_turn_player_index=None, log=False):
        self.rng = default_rng()
        self.state_machine = GraphMachine(self, states=Game.states, initial='start_phase',**Game.model_config)
        self.create_transitions()
        self.age_boards = {
            '1':Age(1),
            '2':Age(2),
            '3':Age(3)
        }
        self.game_id = game_id
        self.players = [Player(0, 'human'), Player(1, 'human')]
        self.turn_count = 1
        if first_turn_player_index is None:
            self.turn_player_index = self.rng.integers(low=0, high=1, endpoint=True)
            # Randomly select first player if none specified.
        self.current_age = 1 # Start in first age.
        self.military_track = 0 # Start military track at 0. Player 0 is -ve direction, player 1 is +ve direction.
        wonders = list(Game.all_wonders)
        self.rng.shuffle(wonders)
        self.first_draft_wonders = wonders[0:4]
        self.second_draft_wonders = wonders[4:8]
        self.unavailable_wonders = wonders[8:]
        tokens = list(Game.all_tokens)
        self.rng.shuffle(tokens)
        self.available_tokens = tokens[0:5] # Choose 3 random tokens.
        self.unavailable_tokens = tokens[5:] # Store the rest for The Great Library.
        self.discard_pile:list[Card] = [] # Create a discard pile for The Mausoleum.
        self.game_ended = False
        #TODO remove log and construction log
        self.log = log
        self.construction_log = {}
        self.move_sequence = []
        self.display_game_state()
        self.valid_moves:list[Move] = None

    def __repr__(self):
        return repr('Game Instance: ' + str(self.game_id))

    def _set_valid_moves(self):
        match self.state:
            case 'draft_phase':
                self.valid_moves = self._get_valid_moves_draft_phase()
            case 'game_phase':
                self.valid_moves = self._get_valid_moves_game_phase()

    def _get_valid_moves_draft_phase(self) -> list[Move]:
        if self.state is not 'draft_phase':
            return print("Not in the draft phase!")
        if self.first_draft_wonders:
            return [Move(Action.DRAFT_WONDER, wonder) for wonder in self.first_draft_wonders]
        elif self.second_draft_wonders:
            return [Move(Action.DRAFT_WONDER, wonder) for wonder in self.second_draft_wonders]
        else:
            return print("There are no wonders left! Why are we still in the draft phase..?")

    def _get_valid_moves_game_phase(self) -> list[Move]:
        if self.state is not 'game_phase':
            return print("Not in the game phase!")
        turn_player = self.get_player()
        non_turn_player = self.get_player(False)

        selectable_cards = [slot.card_in_slot for slot in self.get_slots_in_age() if slot.card_selectable]
        selectable_card_costs = [object_coin_cost(turn_player, non_turn_player, card) for card in selectable_cards]
        constructable_cards = [c for c in zip(selectable_cards, selectable_card_costs) if c[1] <= turn_player.coins]

        selectable_wonder_costs = [object_coin_cost(turn_player, non_turn_player, wonder) for wonder in turn_player.wonders_in_hand]
        if len(turn_player.wonders_in_play) + len(non_turn_player.wonders_in_play) < 7:
            constructable_wonders = [
                w for w in zip(turn_player.wonders_in_hand, selectable_wonder_costs) if w[1] <= turn_player.coins
            ]
        else:
            constructable_wonders = []

        discard_moves = [Move(Action.DISCARD_CARD, card=card) for card in selectable_cards]
        construct_moves = [Move(Action.CONSTRUCT_CARD, card=card[0], cost=card[1]) for card in constructable_cards]
        wonder_moves = []

        for wonder in constructable_wonders:
            match wonder[0].wonder_effect:
                case '':
                    wonder_moves.append(
                        [
                            Move(Action.CONSTRUCT_WONDER, wonder[0], card, None, wonder[1]) for card in selectable_cards
                        ]
                    )
                case 'DestroyGrey':
                    destroyable_cards = [card for card in self.get_player(False).cards_in_play if card.colour == 'Grey']
                    wonder_moves.append(
                        [
                            Move(Action.CONSTRUCT_WONDER, wonder[0], card, special, wonder[1])
                            for card in selectable_cards
                            for special in destroyable_cards
                        ]
                    )
                case 'DestroyBrown':
                    destroyable_cards = [card for card in self.get_player(False).cards_in_play if card.colour == 'Brown']
                    wonder_moves.append(
                        [
                            Move(Action.CONSTRUCT_WONDER, wonder[0], card, special, wonder[1])
                            for card in selectable_cards
                            for special in destroyable_cards
                        ]
                    )
                case 'GainToken':
                    wonder_moves.append(
                        [
                            Move(Action.CONSTRUCT_WONDER, wonder[0], card, special, wonder[1])
                            for card in selectable_cards
                            for special in self.unavailable_tokens
                        ]
                    )
                case 'ReviveCard':
                    wonder_moves.append(
                        [
                            Move(Action.CONSTRUCT_WONDER, wonder[0], card, special, wonder[1])
                            for card in selectable_cards
                            for special in self.discard_pile
                        ]
                    )

        return discard_moves + construct_moves + wonder_moves

    def is_valid_move(self, move:Move) -> bool:
        if self.valid_moves is None:
            self._set_valid_moves()
        if move in self.valid_moves:
            return True
        else:
            return False

    def _draft_wonder(self, move:Move):
        '''Draft a wonder for the turn player'''
        if self.first_draft_wonders:
            wonder_choices = self.first_draft_wonders
        elif self.second_draft_wonders:
            wonder_choices = self.second_draft_wonders
        else:
            print("No wonders to draft. Not sure how we got here..")
            return

        self.get_player().wonders_in_hand.append(move.wonder)
        wonder_choices.remove(move.wonder)
        self._record_move(move)
        if len(wonder_choices) in [1,4]:
            self.change_turn_player()
        return

    def _play_card(self, move:Move):
        match move.action:
            case Action.DISCARD_CARD:
                self._discard_card(move)
            case Action.CONSTRUCT_CARD:
                self._construct_card(move)
            case Action.CONSTRUCT_WONDER:
                self._construct_wonder(move)
            case Action.DRAFT_WONDER:
                print("Not a valid action for this phase!")
                return
        self._record_move()
        return        

    def _record_move(self, move:Move):
        self.move_sequence.append(move)
        return

    def _discard_card(self, move:Move):
        yellow_card_count = len([c for c in self.get_player(True).cards_in_play if c.colour == 'Yellow'])
        self.get_player(True).coins += 2 + yellow_card_count
        self.discard_pile.append(move.card)
        for slot in self.get_slots_in_age():
            if slot.card_in_slot == move.card:
                slot.card_in_slot = None
        return
    
    def _construct_card(self, move:Move):

        return

    def _construct_wonder(self, move:Move):
        return

    def get_slots_in_age(self, age:int=None) -> list[CardSlot]:
        '''Returns list of CardSlot objects in age. If no age provided, returns list of CardSlots in current age'''
        if age is None:
            age = self.current_age

        return self.age_boards[str(age)].card_slots

    def get_player(self, is_turn_player:bool = True) -> Player:
        '''Returns current turn/non-turn player object'''
        if is_turn_player:
            return self.players[self.turn_player_index]
        if not is_turn_player:
            return self.players[self.turn_player_index ^ 1]


    # TODO: Draft wonders function
    def request_player_input(self, display=True):
        # TODO When using AI, no need for player input.
        '''Function to begin requesting player input.'''

        if self.active is False:
            return

        if display is True:
            self.display_game_state()

        choice = input("PLAYER " + str(self.turn_player_index + 1) + ": "
                       + "Select a card or [w]onder to [c]onstruct, or [d]iscard card for coins. "
                       + "(Format is 'XY' where X is c/d/w and Y is card position)")  # TODO Select by name or number?
        action, position = choice[0], choice[1:]

        if action == 'q':
            print("Game has been quit")
            return

        if action not in ['c','d','w']:
            print("Select a valid action! ([c]onstruct card, construct [w]onder, or [d]iscard)")
            return self.request_player_input(display=False)

        if not position.isdigit():
            print("Card choice must be an integer!")
            return self.request_player_input(display=False)

        self.select_card(int(position), action)
        return self.request_player_input(display=False)

    # Main gameplay loop - get_valid_moves() -> select_card() -> turn_end()
    def select_card(self, position, action='c', valid_move_list=None):
        '''Function to select card on baord and perform the appropriate action'''
        # Checks for valid card choices
        #TODO if move choice is in valid_move_list, skip all the checks

        if position >= len(self.get_slots_in_age()) or position < 0:
            print('Select a card on the board!')
            return

        chosen_slot = self.get_slots_in_age()[position]
        chosen_card = chosen_slot.card_in_slot

        if chosen_card is None:
            print('This card has already been chosen!')
            return

        if chosen_slot.card_selectable == 0:
            print('Card is covered, you cannot pick this card!')
            return

        # Discard or construct chosen card and remove card from board
        match action: # TODO add select Wonder option
            case 'c':  # Add card to board.
                cost = object_coin_cost(self.get_player(True), self.get_player(False), chosen_card)

                # Log for debugging cost calculation function.
                if self.log is True:
                    self.construction_log[f'Game {self.game_id}, Turn {self.turn_count}'] = {
                        'card name':chosen_card.name,
                        'card colour':chosen_card.colour,
                        'card cost':chosen_card.costs,
                        'cost':cost,
                        'turn_player_gb':self.get_player(True).grey_brown_resources.copy(),
                        'turn_player_w':self.get_player(True).wonder_resources.copy(),
                        'turn_player_y':self.get_player(True).yellow_resources.copy(),
                        'opp_player_gb':self.get_player(False).grey_brown_resources.copy(),
                        'turn_player_tokens':self.get_player(True).tokens_in_play.copy(),
                        'opp_player_tokens':self.get_player(False).tokens_in_play.copy()
                    }

                if cost <= self.get_player(True).coins:
                    self.get_player(True).coins += - cost
                    print(f"Player {self.turn_player_index+1} paid {cost} coins.")
                    # Account for Economy token.
                    if cost > 0 and 'Economy' in [t.name for t in self.get_player(False).tokens_in_play]:
                        self.get_player(False).coins += cost - chosen_card.costs['$']
                    self.construct_card(chosen_card)
                else:
                    print('You do not have the resources/coins required to construct this card!')
                    return
            case 'd':  # Gain coins based on yellow buildings owned.
                yellow_card_count = len([c for c in self.get_player(True).cards_in_play if c.colour == 'Yellow'])
                self.get_player(True).coins += 2 + yellow_card_count
                self.discard_pile.append(chosen_card)
            case _:
                print('This is not a valid action!')
                return

        # Remove card from board
        chosen_slot.card_in_slot = None

        self.turn_end()
        return

    def turn_end(self):
        '''Run end of turn functions'''

        # Check for science/military win and end game if required
        self.check_alt_victory()

        # Update age card slots
        self.age_boards[str(self.current_age)].update_all_slots()

        # Check for end of age and progress if required
        if all(self.get_slots_in_age()[s].card_in_slot is None for s in range(len(self.get_slots_in_age()))):
            self.progress_age()

            # Check for game end
            if self.game_ended is True:
                print('Game is over!')
                return self.game_end('civilian')

            # Create next age board and update handy state variables
            self.age_boards[str(self.current_age)] = Age(self.current_age)
        else:
            self.change_turn_player()

        self.turn_count += 1

        # Display game state
        return self.display_game_state()

    #TODO Give meaning to turn end functions
    def check_alt_victory(self):
        '''Checks for alternate victory conditions (military and science) and ends game if required.'''
        return

    def update_age(self):
        '''Updates player passive variables based on boths players tableau.'''
        return
        # state = self.get_game_state()

        # for key in self.players[player].passive_variables.keys(): #reset all vars to 0
        #     self.players[player].passive_variables[key] = 0

        # if self.cards_in_play:
        #     for card in self.cards_in_play:
        #         pass


        # return
        # Displays the game state in a nice enough way.

    def game_end(self, victory_method='civilian'):
        '''Does game end stuff - check for winner etc.'''
        victory_methods = ['civilian','military','science']
        if victory_method not in victory_methods:
            raise ValueError("Invalid victory method, expected one of: %s" % victory_methods)
        self.display_game_state()

        match victory_method:
            case 'military':
                print("Player "+str(self.turn_player_index)+" won by military supremacy!")
            case 'science':
                print("Player "+str(self.turn_player_index)+" won by scientific supremacy!")
            case 'civilian':
                #TODO call player_with_more_points()
                print("Player with more points won by civilian victory!")

    def display_game_state(self):
        '''Print a visual representation of the current game state.'''
        match self.state:
            case 'start_phase':
                print("Welcome to a new game! Call your_game_object.begin_draft_phase to start!")
            case 'draft_phase':
                print()
            case 'game_phase': 
                print("\n-------- \n"+
                    f"Turn #{self.turn_count}\n"+
                    "--------")
                self.age_boards[str(self.current_age)].display_board()
                print("\nPlayer 1 >" + repr(self.players[0]) +
                    "\n\nPlayer 2 >" + repr(self.players[1]) +
                    "\n\nCurrent turn player is Player " + str(self.turn_player_index + 1)
                    + "\n"
                )

    def construct_card(self, card:Card, player:Player = None, opponent:Player = None):
        '''Function to construct a card in turn players tableau'''
        if player is None:
            player = self.players[self.turn_player_index]

        if opponent is None:
            opponent = self.players[self.turn_player_index ^ 1]
        # Add card to card in play list.
        player.cards_in_play.append(card)
        print(f"Player {player.player_number+1} has constructed the {card}!\n")
        # Check colour of constructed card and update player resources.
        match card.colour:
            case 'Grey' | 'Brown':
                for resource in player.grey_brown_resources:
                    player.grey_brown_resources[resource] += card.passives[resource]
                return
            case 'Green':
                for symbol in player.victory_symbols:
                    player.victory_symbols[symbol] += card.passives[symbol]
                    if player.victory_symbols[symbol] == 2 and card.passives[symbol] == 1:
                        self.gain_progress_token()
                return
            case 'Yellow':
                for resource in player.yellow_resources:
                    player.yellow_resources[resource] += card.passives[resource]

        # Check on play effects and do what is appropriate.
        for effect, value in card.on_plays.items():
            if value == 0:
                continue
            match (effect, card.colour):
                # Deal with military.
                case ('M', _):
                    # Account for Strategy progress token
                    if 'Strategy' in [token.name for token in player.tokens_in_play]:
                        value += 1
                    if player.player_number == 0: #Player number 0 sends military track -ve
                        self.military_track += -value
                    elif player.player_number == 1: #Player number 1 sends military track +ve
                        self.military_track += value
                # Deal with normal coin gain.
                case ('$', _):
                    player.coins += value
                # Deal with $ per Wonder gain.
                case ('$ per Wonder', _):
                    player.coins += value * len(player.wonders_in_play)
                # Deal with $ per card colour you OWN.
                case (_, 'Yellow'):
                    # Extracts colour(s) from string.
                    colours = effect.partition('$ per ')[2]
                    # Counts number of cards in play that matches the colours in the string.
                    colour_count = sum(c.colour in colours.split('/') for c in player.cards_in_play)
                    player.coins += value * colour_count
                # Deal with $ per card colour in city with MOST.
                case (_, 'Purple'):
                    colours = effect.partition('$ per ')[2]
                    # Same as Yellow case, but checks max count between turn player and opponent.
                    max_colour_count = max(
                        sum(c.colour in colours.split('/') for c in player.cards_in_play),
                        sum(c.colour in colours.split('/') for c in opponent.cards_in_play)
                    )
                    player.coins += value * max_colour_count

        return

    def construct_wonder(self):
        '''Function to construct a wonder in turn players tableau'''
        #TODO all the wonder effects...
        return

    def gain_progress_token(self, player:Player = None, token:Token = None):
        '''Function to select a progress token to build. If no token is chosen, input will be requested.'''

        if not self.available_tokens:
            return print("No progress tokens available!")

        if len(self.available_tokens) == 1:
            print("Only 1 token available.")
            choice = 0
            token = self.available_tokens[choice]

        if player is None:
            player = self.players[self.turn_player_index]

        if self.random_moves is True:
            choice = self.rng.integers(0, len(self.available_tokens))

        elif token is None:
            token_string = ''
            for i, t in enumerate(self.available_tokens):
                token_string = token_string+"#"+str(i)+": "+repr(t)+" "
            print(token_string)
            choice = input("Select an available token! ")

            if not choice.isdigit():
                print("Choice must be an integer!")
                return self.gain_progress_token(player, token)

            choice = int(choice)

            if choice < 0 or choice >= len(self.available_tokens):
                print("Please select a valid token!")
                return self.gain_progress_token(player, token)

        token = self.available_tokens[choice]
        player.tokens_in_play.append(token)
        del self.available_tokens[choice]

        # Account for Urbanism and Agriculture token.
        if token.name in ['Agriculture', 'Urbanism']:
            player.coins += 6

        # Account for Law token.
        if token.name == 'Law':
            player.victory_symbols['7'] += 1

        print(f"Player {player.player_number + 1}'s progress tokens:")
        return print(player.tokens_in_play)

    def change_turn_player(self):
        '''Function to change current turn player'''
        self.turn_player_index = self.turn_player_index ^ 1  # XOR operation to change 0 to 1 and 1 to 0

    def progress_age(self):
        '''Function to progress age and end game if required'''
        # TODO For progress age function: check military track to set first turn player.
        if self.current_age < 3:
            self.current_age = self.current_age + 1
        else:
            self.game_ended = True




def object_coin_cost(player:Player, opponent:Player, obj:Constructable) -> int:
    '''Calculates card cost given current player states. Currently outputs a list of relevant params for debugging.'''

    # Checks if card_prerequisite string is not empty, and if present in players tableu.
    if isinstance(obj, Card) and obj.prerequisite and player.has_card(obj.prerequisite):
        # Account for coin gain from Urbanism token.
        if 'Urbanism' in [token.name for token in player.tokens_in_play]:
            return -4
        return 0

    # Return 0 if card is free.
    if len(obj.cost_string) == 0:
        return 0

    # Base cost is always the coin cost (if present).
    cost = obj.costs['$']

    # Checks if coin cost is the only cost - if so, return early.
    if set(obj.cost_string) == {'$'}:
        return cost

    resources = player.grey_brown_resources.keys()

    # Calculates how many of each resource the player doesn't already own.
    resource_defecit = {}
    for res in resources:
        resource_defecit[res] = max(0,
            obj.costs[res] -
            player.grey_brown_resources[res] -
            player.wonder_resources[res]
        )
    if sum(resource_defecit.values()) == 0:
        return cost

    # Calculates the cost of each resource given the opponent's board state.
    resource_cost = {}
    for res in resources:
        if player.yellow_resources[res] >= 1:
            resource_cost[res] = 1
        else:
            resource_cost[res] = 2 + opponent.grey_brown_resources[res]

    # Calculates how much benefit can be gained by allocating optional resources.
    resource_benefit = {}
    for res in resources:
        if resource_defecit[res] == 0:
            resource_benefit[res] = 0
        else:
            resource_benefit[res] = resource_cost[res]

    # Calculates how many of each set of optional resources the player has.
    or_pg = player.yellow_resources['P/G'] + player.wonder_resources['P/G']
    or_cws = player.yellow_resources['W/C/S'] + player.wonder_resources['W/C/S']

    # Account for P/G optional resources (Forum/Piraeus)
    for _ in range(or_pg):
        # Makes a dict of the relevant benefit values.
        pg_benefit = {k:v for k,v in resource_benefit.items() if k in ['P','G']}
        # If all benefits are 0, player is not short of any resource the optionals can give, so break early.
        if all(value == 0 for value in pg_benefit.values()):
            break
        # Find resource allocation which gives highest benefit (cost reduction).
        max_benefit = max(pg_benefit, key = pg_benefit.get)
        # Reduce the defecit by 1.
        resource_defecit[max_benefit] += -1
        # If the defecit is reduced to 0, no more benefit to be gained from allocation.
        if resource_defecit[max_benefit] == 0:
            resource_benefit[max_benefit] = 0

    # Account for C/W/S optional resources (Caravansery/The Great Lighthouse)
    # Same as above.
    for _ in range(or_cws):
        cws_benefit = {k:v for k,v in resource_benefit.items() if k in ['C','W','S']}
        if all(value == 0 for value in cws_benefit.values()):
            break
        max_benefit = max(cws_benefit, key = cws_benefit.get)
        resource_defecit[max_benefit] += -1
        if resource_defecit[max_benefit] == 0:
            resource_benefit[max_benefit] = 0

    # Account for Masonry (reduce cost by 2 highest cost resources)
    # Same as above, but checks if constructing a Blue card first.
    if hasattr(obj,'colour'):
        if 'Masonry' in [token.name for token in player.tokens_in_play] and obj.colour == 'Blue':
            for _ in range(2):
                if all(value == 0 for value in resource_benefit.values()):
                    break
                max_benefit = max(resource_benefit, key = resource_benefit.get)
                resource_defecit[max_benefit] += -1
                if resource_defecit[max_benefit] == 0:
                    resource_benefit[max_benefit] = 0

    # Caclulate total cost based on remaining resource defecit and costs
    for res, defecit in resource_defecit.items():
        cost += defecit * resource_cost[res]

    return cost
