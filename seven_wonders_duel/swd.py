"""Classes and functions to run Seven Wonders Duel game logic"""
import os
import csv
from dataclasses import dataclass
from typing import TypedDict
from ast import literal_eval as leval
from numpy.random import default_rng
from sty import fg, bg, rs

os.chdir(os.path.dirname(os.path.abspath(__file__)))

@dataclass
class Card:
    '''Define a single card. Attributes match the .csv headers'''
    colour_key = {
        'Brown': bg(100, 50, 0) + fg.white,
        'Grey': bg.grey + fg.black,
        'Red': bg.red + fg.white,
        'Green': bg(0, 128, 0) + fg.white,
        'Yellow': bg.yellow + fg.black,
        'Blue': bg.blue + fg.white,
        'Purple': bg(128, 0, 128) + fg.white,
    }

    card_name:              str = ''
    card_set:               str = ''
    card_type:              str = ''
    card_cost_string:       str = ''
    card_effect_passive:    str = ''
    card_effect_on_play:    str = ''
    card_age:               str = ''
    card_prerequisite:      str = ''

    def __post_init__(self):
        self.card_costs = {
            'C':0, #Clay
            'W':0, #Wood
            'S':0, #Stone
            'P':0, #Paper
            'G':0, #Glass
            '$':0  #Coins
        }
        if self.card_cost_string:
            for resource in self.card_cost_string:
                self.card_costs[resource] += 1

    def __repr__(self):
        return str(Card.colour_key[self.card_type]
                   + self.card_name
                   + rs.all)


@dataclass
class Wonder:
    '''Define a single wonder. Attributes match the .csv headers'''
    colour_key = {
        'Wonder': bg.black + fg.white
    }

    wonder_name:              str = ''
    wonder_set:               str = ''
    wonder_cost_string:       str = ''
    wonder_effect_passive:    str = ''
    wonder_effect_on_play:    str = ''

    def __post_init__(self):
        self.card_costs = {
            'C':0, #Clay
            'W':0, #Wood
            'S':0, #Stone
            'P':0, #Paper
            'G':0, #Glass
            '$':0  #Coins
        }
        if self.wonder_cost_string:
            for resource in self.wonder_cost_string:
                self.card_costs[resource] += 1

    def __repr__(self):
        return str(Wonder.colour_key['Wonder']
                   + self.wonder_name
                   + rs.all)


class Player:
    '''Define a class for play to track tableau cards, money, etc.'''

    def __init__(self, player_number=0, player_type='human'):
        # Private:
        self.player_number = player_number
        self.player_type = player_type

        # Update as card is chosen through Game.construct_card method:
        self.coins = 7
        self.cards_in_play = []
        self.wonders_in_hand = []
        self.wonders_in_play = []
        self.progress_tokens = []

        # Passive variables can be updated anytime based on cards_in_play via self.update() method.
        self.grey_brown_resources = {
            'C':0, #Clay
            'W':0, #Wood
            'S':0, #Stone
            'P':0, #Paper
            'G':0, #Glass
        }

        self.wonder_resources = {
            'C':0, #Clay
            'W':0, #Wood
            'S':0, #Stone
            'P':0, #Paper
            'G':0, #Glass
        }

        self.gold_resources = {
            'c':0, #Clay
            'w':0, #Wood
            's':0, #Stone
            'p':0, #Paper
            'g':0, #Glass
            'G/P':0, #Forum
            'W/C/S':0 #Caravansery
        }

        self.victory_state = {
            'V':0, #Victory Points
            '1':0, #Victory Symbol (Frame)
            '2':0, #Victory Symbol (Wheel)
            '3':0, #Victory Symbol (Quill & Ink)
            '4':0, #Victory Symbol (Mortal & Pestle)
            '5':0, #Victory Symbol (Sundial)
            '6':0, #Victory Symbol (Astrolabe)
            '7':0 #Victory Symbol (Scales)
        }

    def __repr__(self):
        return str(" Coins: " + repr(self.coins)
                   + ", Board: " + repr(self.cards_in_play))


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


class Game:
    '''Define a single instance of a game'''
    # TODO need to track discard pile as some wonders revive cards
    all_cards = csv_to_class('card_list.csv',Card)

    def __init__(self, game_id=1, active=0):
        # Create a dict with first age cards and card slots:
        self.age_boards = {'1':Age(1)}
        self.game_id = game_id
        self.active = active
        self.players = [Player(0, 'human'), Player(1, 'human')]
        self.common_variables = CommonVariables()
        self.state = self.get_game_state()
        self.turn_count = 1
        self.display_game_state()

    def __repr__(self):
        return repr('Game Instance: ' + str(self.game_id))

    def get_game_state(self):
        '''Returns a TypedDict of commonly used game state variables'''
        # Turn player variables
        player_index = self.common_variables.turn_player
        player_state = self.players[player_index]
        player_cards = player_state.cards_in_play

        # Opponent player variables
        opponent_index = player_index ^ 1  # XOR operator (changes 1 to 0 and 0 to 1)
        opponent_state = self.players[opponent_index]
        opponent_cards = opponent_state.cards_in_play

        # Current age variables
        current_age = self.common_variables.current_age
        slots_in_age = self.age_boards[str(current_age)].card_slots

        gamestate_class = TypedDict('GameState', {
            'player_index':      int,
            'player_state':      Player,
            'player_cards':      list[Card],

            'opponent_index':    int,
            'opponent_state':    Player,
            'opponent_cards':    list[Card],

            'current_age':       int,
            'slots_in_age':      list[CardSlot]
        })

        gamestate: gamestate_class = {
            'player_index':      player_index,
            'player_state':      player_state,
            'player_cards':      player_cards,

            'opponent_index':    opponent_index,
            'opponent_state':    opponent_state,
            'opponent_cards':    opponent_cards,

            'current_age':       current_age,
            'slots_in_age':      slots_in_age
        }
        return gamestate

    # TODO: Draft wonders function
    def request_player_input(self, display=True):
        # TODO When using AI, no need for player input.
        """Function to begin requesting player input

        Returns:
            void: [description]
        """

        if self.active == 0:
            return

        if display is True:
            self.display_game_state()

        choice = input("PLAYER " + str(self.common_variables.turn_player + 1) + ": "
                       + "Select a card to [c]onstruct or [d]iscard for coins. "
                       + "(Format is 'X#' where X is c/d and # is card position)")  # TODO Select by name or number?
        action, position = choice[0], choice[1:]

        if action == 'q':
            print("Game has been quit")
            return

        if action not in ['c','d']:
            print("Select a valid action! ([c]onstruct or [d]iscard)")
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

        if position >= len(self.state['slots_in_age']) or position < 0:
            print('Select a card on the board!')
            return

        chosen_slot = self.state['slots_in_age'][position]
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
                if card_constructable(self.state['player_state'], self.state['opponent_state'], chosen_card) is True:
                    self.construct_card(self.state['player_state'], chosen_card)
                else:
                    print('You do not have the resources required to construct this card!')
                    return
            case 'd':  # Gain coins based on yellow buildings owned.
                yellow_card_count = len([card for card in self.state['player_cards'] if card.card_type == 'Yellow'])
                self.state['player_state'].coins += 2 + yellow_card_count
            case _:
                print('This is not a valid action!')
                return

        # Remove card from board
        # TODO move to DiscardPile object
        chosen_slot.card_in_slot = None
        self.turn_end()
        return

    def construct_card(self, player:Player, card:Card):
        '''Fucntion to construct a card in turn players tableau'''

        player.cards_in_play.append(card)

        # TODO run on construct effects
        return

    def turn_end(self):
        '''Run end of turn functions'''
        # Update player passive variables (resources/VP/science symbols)
        self.update_player_states()

        # Check for science/military win and end game if required
        self.check_alt_victory()

        # Update age card slots
        self.age_boards[str(self.state['current_age'])].update_all_slots()

        # Check for end of age and progress if required
        if all(self.state['slots_in_age'][s].card_in_slot is None for s in range(len(self.state['slots_in_age']))):
            self.common_variables.progress_age()

            # Check for game end
            if self.common_variables.game_ended is True:
                print('Game is over!')
                return self.game_end('civilian')

            # Create next age board and update handy state variables
            self.age_boards[str(self.common_variables.current_age)] = Age(self.common_variables.current_age)
        else:
            self.common_variables.change_turn_player()

        # Update handy self.state variable and turn count
        self.state = self.get_game_state()
        self.turn_count += 1

        # Display game state
        return self.display_game_state()

    #TODO Give meaning to turn end functions
    def update_player_states(self):
        '''Updates all player passive variables (resources/VP/science symbols etc.)'''
        return

    def check_alt_victory(self):
        '''Checks for alternate victory conditions (military and science) and ends game if required'''
        return

    def update_age(self):
        '''Updates player passive variables based on boths players tableau'''
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
                print("Player "+str(self.common_variables.turn_player)+" won by military supremacy!")
            case 'science':
                print("Player "+str(self.common_variables.turn_player)+" won by scientific supremacy!")
            case 'civilian':
                #TODO call player_with_more_points()
                print("Player with more points won by civilian victory!")

    def display_game_state(self):
        '''Print a visual representation of the current game state'''

        self.age_boards[str(self.state['current_age'])].display_board()
        print("Player 1 >", self.players[0])
        print("Player 2 >", self.players[1])
        print("Current turn player is Player ", str(self.state['player_index'] + 1))


class CardSlot:
    '''Define a card slot on board to represent selectability, visibility, etc.'''
    # TODO covered_by doesnt work when covered by 0 only (age 2 pos 2, age 3 pos 2).
    # TODO Changed .csv to "0" instead of 0, but would like to fix here.
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


class CommonVariables:
    '''Class to represent all state variables shared between players (military, turn player, etc.)'''

    def __init__(self, turn_player=None, current_age=1, military_track=0):
        self.rng = default_rng()
        if turn_player is None:
            self.turn_player = self.rng.integers(low=0, high=1, endpoint=True)
            # Randomly select first player if none specified.
        self.current_age = current_age  # Start in first age.
        self.military_track = military_track  # Start military track at 0.
        self.game_ended = False

    def change_turn_player(self):
        '''Function to change current turn player'''
        self.turn_player = self.turn_player ^ 1  # XOR operation to change 0 to 1 and 1 to 0

    def progress_age(self):
        '''Function to progress age and end game if required'''
        # TODO For progress age function: check military track to set first turn player.
        if self.current_age < 3:
            self.current_age = self.current_age + 1
        else:
            self.game_ended = True


class Age:
    '''Class to define a game age and represent the unique board layouts'''

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
            card_pool = [card for card in Game.all_cards if str(card.card_age)==card_type]
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


def get_valid_moves(game:Game) -> list[str]:
    '''Returns list of valid moves for given board state and player states'''
    # TODO Return list of valid moves for current player using below functions.
    return


def card_constructable(player:Player, opponent:Player, card:Card) -> bool:
    '''Checks whether a card is constructable given current player states'''

    return True


def wonder_constructable(player:Player, opponent:Player, card:Wonder) -> bool:
    '''Checks whether a card is constructable given current player states'''

    return True


def card_coin_cost(player:Player, opponent:Player, card:Card) -> int:
    '''Calculates card cost given current player states'''
    #TODO implement card coin cost function
    if len(card.card_cost_string) == 0:
        return 0

    # Checks if card_prerequisite string is not empty, and if present in players tableu.
    if card.card_prerequisite and card.card_prerequisite in [c.card_name for c in player.cards_in_play]:
        return 0

    if all(card.card_cost_string) == '$':
        return len(card.card_cost_string)

    cost_defecit = {}
    for resource in ['C','W','S','P','G']:
        cost_defecit[resource] = max(0,
            card.costs[resource] -
            player.grey_brown_resources[resource] -
            player.wonder_resources
        )
    if sum(cost_defecit.values()) == 0:
        return 0

    # Adds cost based on opponents board. Need to deal with optional resources
    cost = 0
    for resource, defecit in cost_defecit.items():
        if player.gold_resources[resource.lower()] > 0:
            cost += defecit
        else:
            cost += 2 + defecit * opponent.grey_brown_resources[resource]

    return cost


if __name__ == "__main__":
    game1 = Game(1,1)
    game1.request_player_input(display=True)
