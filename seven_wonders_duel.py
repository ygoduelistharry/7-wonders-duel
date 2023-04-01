'''Module to play a game of Seven Wonders Duel'''
import csv
from ast import literal_eval as leval
from numpy.random import default_rng
from sty import fg, bg, rs


class Card:
    '''Define a single card. Attributes match the .csv headers'''
    colour_key = {
        "Brown": bg(100, 50, 0) + fg.white,
        "Grey": bg.grey + fg.black,
        "Red": bg.red + fg.white,
        "Green": bg(0, 128, 0) + fg.white,
        "Yellow": bg.yellow + fg.black,
        "Blue": bg.blue + fg.white,
        "Purple": bg(128, 0, 128) + fg.white,
    }

    def __init__(self, card_name='', card_set='', card_type='', card_cost='', card_age='',
        card_effect_passive='', card_effect_when_played='', card_prerequisite=''):
        self.card_name = card_name
        self.card_set = card_set
        self.card_type = card_type
        self.card_cost = card_cost
        self.card_effect_passive = card_effect_passive
        self.card_effect_when_played = card_effect_when_played
        self.card_age = card_age
        self.card_prerequisite = card_prerequisite

    def __repr__(self):
        return str(Card.colour_key[self.card_type]
                   + self.card_name
                   + rs.all)


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

    list_of_class_objects = [to_class(**kwargs) for kwargs in kwarg_dict_list]

    return list_of_class_objects


class Game:
    '''Define a single instance of a game'''
    # TODO need to track discard pile as some wonders revive cards
    all_cards = csv_to_class('card_list.csv',Card)

    def __init__(self, game_id=1, active=0):
        # Create a list of lists, one list per age containing the card objects for that age:
        self.age_boards = {'1':Age(1)}
        self.game_id = game_id
        self.active = active
        self.players = [Player(0, 'human'), Player(1, 'human')]
        self.state_variables = StateVariables()
        self.display_game_state()

    def __repr__(self):
        return repr('Game Instance: ' + str(self.game_id))

        # TODO: Draft wonders function

    def request_player_input(self):  # TODO When using AI, no need for player input.
        """Function to begin requesting player input

        Returns:
            void: [description]
        """
        if self.active == 0:
            return

        choice = input("PLAYER " + str(self.state_variables.turn_player + 1) + ": "
                       + "Select a card to [c]onstruct or [d]iscard for coins. "
                       + "(Format is 'X#' where X is c/d and # is card position)")  # TODO Select by name or number?
        action, position = choice[0], choice[1:]

        if action == 'q':
            return print("Game has been quit")

        if action not in ['c','d']:
            print("Select a valid action! ([c]onstruct or [d]iscard)")
            return self.request_player_input()

        if not position.isdigit():
            print("Card choice must be an integer!")
            return self.request_player_input()

        self.select_card(int(position), action)

    # Main gameplay loop - players alternate choosing cards from the board and performing actions with them.
    def select_card(self, position, action='c'):
        '''Function to select card on baord and perform the appropriate action'''
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
        slots_in_age = self.age_boards[str(age)].card_positions

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
                if card_constructable(player_state, opponent_state, chosen_position.card_in_slot) is True:
                    player_state.construct_card(chosen_position.card_in_slot)
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

        # Check for end of age
        self.check_age_end()

        # Continue game loop.
        self.display_game_state()
        return self.request_player_input()

    def check_age_end(self):
        '''Checks if there are cards left in the age, and if not, progresses to the next age'''

        # Current age variables
        age = self.state_variables.current_age
        slots_in_age = self.age_boards[str(age)].card_positions

        if all(slots_in_age[slot].card_in_slot is None for slot in range(len(slots_in_age))):
            self.state_variables.progress_age()

        else:  # Otherwise, update all cards in current age and change turn turn_player
            self.age_boards[str(age)].update_all_slots()
            self.state_variables.change_turn_player()  # TODO This might not always be true if go again wonders chosen

        if self.state_variables.game_end:
            self.display_game_state()
            return print('Game is over!')  # TODO Check victory and stuff

    # Displays the game state in a nice enough way.
    def display_game_state(self):
        '''Print a visual representation of the current game state'''
        player = self.state_variables.turn_player
        age = self.state_variables.current_age

        self.age_boards[str(age)].display_board()
        print("Player 1 >", self.players[0])
        print("Player 2 >", self.players[1])
        print("Current turn player is Player ", str(player + 1))


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

        # Passive variables can be updated anytime based on cards_in_play via self.update() method.
        self.victory_points = 0
        self.clay = 0
        self.wood = 0
        self.stone = 0
        self.paper = 0
        self.glass = 0
        self.victory_tokens = []

    def __repr__(self):
        return str(" Coins: " + repr(self.coins)
                   + ", Board: " + repr(self.cards_in_play))

    # TODO Function to construct card (pay resources, add card to player board, gain on buy benefit)
    # removal of card from game board is done elsewhere! (in Game.select_card method).
    def construct_card(self, card):
        '''Fucntion to construct a card in a players tableau'''
        self.cards_in_play.append(card)

    def update(self):
        '''Updates player passive variables based on players tableau'''
        return


class StateVariables:
    '''Class to represent all state variables shared between players (military, turn player, etc.)'''

    def __init__(self, turn_player=None, current_age=1, military_track=0):
        self.rng = default_rng()
        if turn_player is None:
            self.turn_player = self.rng.integers(low=0, high=1, endpoint=True)
            # Randomly select first player if none specified.
        self.current_age = current_age  # Start in first age.
        self.military_track = military_track  # Start military track at 0.
        self.game_end = False

    def change_turn_player(self):
        '''Function to change current turn player'''
        self.turn_player = self.turn_player ^ 1  # XOR operation to change 0 to 1 and 1 to 0

    def progress_age(self):
        '''Function to progress age and end game if required'''
        # TODO For progress age function: check military track for turn player and deal with end of game.
        if self.current_age < 3:
            self.current_age = self.current_age + 1
        else:
            self.game_end = True


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
        self.card_positions = self.prepare_age_board(age)

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
        for slot in range(len(self.card_positions)):
            self.update_slot(slot)  # Update each slot for visibility and selectability.

    def update_slot(self, slot):
        '''Updates card in a single slot for visibility, selectability, etc.'''
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
        '''Prints visual representation of cards remaining on the board for this age'''
        cards = self.card_positions
        rows = max(self.card_positions[slot].row for slot in range(len(self.card_positions)))
        for row in reversed(range(int(rows) + 1)):
            print("Row", str(row + 1), ":", [card for card in cards if int(card.row) == row])


# Takes 2 Player objects and 1 Card object and checks whether card is constructable given state and cost.
# TODO Check whether card is constructable given arbitrary player/opponent/card objects
def card_constructable(player, opponent, card):
    '''Checks whether a card is constructable given current player states'''
    return True

# Takes 2 Player objects and 1 Age object and retruns all valid moves for the player.
# TODO Return list of valid moves for current player.
def valid_moves(player, opponent, age):
    '''Returns list of valid moves for given board state and player states'''
    return


if __name__ == "__main__":
    game1 = Game(1,1)
    game1.request_player_input()
    pass