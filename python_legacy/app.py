import sys
from PyQt6.QtWidgets import QMainWindow, QApplication
from PyQt6.uic import loadUi
from PyQt6 import QtGui
from seven_wonders_duel import swd

class UI(QMainWindow):
    def __init__(self, game:swd.Game):
        super().__init__()
        loadUi("../swd_qtgui.ui", self)
        self.game = game
        self.display_age_board()
        self.display_cards_on_board()
    
    def display_age_board(self, age:int=None):
        '''Brings container widget containing age cards to the front layer'''
        if age is None:
            age = self.game.current_age

        board_string = "age"+str(age)+"_board"
        getattr(self, board_string).raise_()
    
    def display_cards_on_board(self, age:int=None):
        '''Sets pixmap for widgets in age board to images of cards in slots'''
        if age is None:
            age = self.game.current_age

        #Return list of slots in age
        slots_in_age = self.game.get_slots_in_age(age)

        #Iterate over slots in age and set pixmaps
        for position, slot in enumerate(slots_in_age):
            #Widget name
            card_back_path = "../images/age"+str(age)+"back.jpg"
            card_string = "age"+str(age)+"_slot"+str(position)
            #Check if card is hidden
            if slot.card_visible == 0:
                #Set to age card back
                getattr(self, card_string).setPixmap(QtGui.QPixmap(card_back_path))
            else:
                card_name = slot.card_in_slot.name.replace(" ","").lower()
                card_image_path = "../images/"+card_name+".jpg"
                #Set to card image
                getattr(self, card_string).setPixmap(QtGui.QPixmap(card_image_path))

game = swd.Game()
app = QApplication(sys.argv)
window = UI(game=game)
window.show()
app.exec()
pass
