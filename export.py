# Form implementation generated from reading ui file 'swd_qtgui.ui'
#
# Created by: PyQt6 UI code generator 6.5.1
#
# WARNING: Any manual changes made to this file will be lost when pyuic6 is
# run again.  Do not edit this file unless you know what you are doing.


from PyQt6 import QtCore, QtGui, QtWidgets


class Ui_app(object):
    def setupUi(self, app):
        app.setObjectName("app")
        app.resize(1920, 1080)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Policy.Fixed, QtWidgets.QSizePolicy.Policy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(app.sizePolicy().hasHeightForWidth())
        app.setSizePolicy(sizePolicy)
        self.centralwidget = QtWidgets.QWidget(parent=app)
        self.centralwidget.setObjectName("centralwidget")
        self.p1_cards = QtWidgets.QTableView(parent=self.centralwidget)
        self.p1_cards.setGeometry(QtCore.QRect(10, 10, 481, 781))
        self.p1_cards.setObjectName("p1_cards")
        self.p2_cards = QtWidgets.QTableView(parent=self.centralwidget)
        self.p2_cards.setGeometry(QtCore.QRect(1400, 10, 511, 781))
        self.p2_cards.setStyleSheet("")
        self.p2_cards.setObjectName("p2_cards")
        self.age2_board = QtWidgets.QFrame(parent=self.centralwidget)
        self.age2_board.setGeometry(QtCore.QRect(520, 220, 851, 811))
        self.age2_board.setStyleSheet("background-color: rgb(199, 233, 255);")
        self.age2_board.setFrameShape(QtWidgets.QFrame.Shape.StyledPanel)
        self.age2_board.setFrameShadow(QtWidgets.QFrame.Shadow.Raised)
        self.age2_board.setObjectName("age2_board")
        self.age2_slot7 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot7.setGeometry(QtCore.QRect(430, 300, 131, 211))
        self.age2_slot7.setText("")
        self.age2_slot7.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot7.setScaledContents(True)
        self.age2_slot7.setObjectName("age2_slot7")
        self.age2_slot2 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot2.setGeometry(QtCore.QRect(220, 410, 131, 211))
        self.age2_slot2.setText("")
        self.age2_slot2.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot2.setScaledContents(True)
        self.age2_slot2.setObjectName("age2_slot2")
        self.age2_slot10 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot10.setGeometry(QtCore.QRect(220, 190, 131, 211))
        self.age2_slot10.setText("")
        self.age2_slot10.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot10.setScaledContents(True)
        self.age2_slot10.setObjectName("age2_slot10")
        self.age2_slot11 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot11.setGeometry(QtCore.QRect(360, 190, 131, 211))
        self.age2_slot11.setText("")
        self.age2_slot11.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot11.setScaledContents(True)
        self.age2_slot11.setObjectName("age2_slot11")
        self.age2_slot3 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot3.setGeometry(QtCore.QRect(360, 410, 131, 211))
        self.age2_slot3.setText("")
        self.age2_slot3.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot3.setScaledContents(True)
        self.age2_slot3.setObjectName("age2_slot3")
        self.age2_slot14 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot14.setGeometry(QtCore.QRect(10, 80, 131, 211))
        self.age2_slot14.setText("")
        self.age2_slot14.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot14.setScaledContents(True)
        self.age2_slot14.setObjectName("age2_slot14")
        self.age2_slot17 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot17.setGeometry(QtCore.QRect(430, 80, 131, 211))
        self.age2_slot17.setText("")
        self.age2_slot17.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot17.setScaledContents(True)
        self.age2_slot17.setObjectName("age2_slot17")
        self.age2_slot6 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot6.setGeometry(QtCore.QRect(290, 300, 131, 211))
        self.age2_slot6.setText("")
        self.age2_slot6.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot6.setScaledContents(True)
        self.age2_slot6.setObjectName("age2_slot6")
        self.age2_slot4 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot4.setGeometry(QtCore.QRect(500, 410, 131, 211))
        self.age2_slot4.setText("")
        self.age2_slot4.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot4.setScaledContents(True)
        self.age2_slot4.setObjectName("age2_slot4")
        self.age2_slot19 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot19.setGeometry(QtCore.QRect(710, 80, 131, 211))
        self.age2_slot19.setText("")
        self.age2_slot19.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot19.setScaledContents(True)
        self.age2_slot19.setObjectName("age2_slot19")
        self.age2_slot16 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot16.setGeometry(QtCore.QRect(290, 80, 131, 211))
        self.age2_slot16.setText("")
        self.age2_slot16.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot16.setScaledContents(True)
        self.age2_slot16.setObjectName("age2_slot16")
        self.age2_slot5 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot5.setGeometry(QtCore.QRect(150, 300, 131, 211))
        self.age2_slot5.setText("")
        self.age2_slot5.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot5.setScaledContents(True)
        self.age2_slot5.setObjectName("age2_slot5")
        self.age2_slot13 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot13.setGeometry(QtCore.QRect(640, 190, 131, 211))
        self.age2_slot13.setText("")
        self.age2_slot13.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot13.setScaledContents(True)
        self.age2_slot13.setObjectName("age2_slot13")
        self.age2_slot9 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot9.setGeometry(QtCore.QRect(80, 190, 131, 211))
        self.age2_slot9.setText("")
        self.age2_slot9.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot9.setScaledContents(True)
        self.age2_slot9.setObjectName("age2_slot9")
        self.age2_slot15 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot15.setGeometry(QtCore.QRect(150, 80, 131, 211))
        self.age2_slot15.setText("")
        self.age2_slot15.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot15.setScaledContents(True)
        self.age2_slot15.setObjectName("age2_slot15")
        self.age2_slot12 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot12.setGeometry(QtCore.QRect(500, 190, 131, 211))
        self.age2_slot12.setText("")
        self.age2_slot12.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot12.setScaledContents(True)
        self.age2_slot12.setObjectName("age2_slot12")
        self.age2_slot18 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot18.setGeometry(QtCore.QRect(570, 80, 131, 211))
        self.age2_slot18.setText("")
        self.age2_slot18.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot18.setScaledContents(True)
        self.age2_slot18.setObjectName("age2_slot18")
        self.age2_slot8 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot8.setGeometry(QtCore.QRect(570, 300, 131, 211))
        self.age2_slot8.setText("")
        self.age2_slot8.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot8.setScaledContents(True)
        self.age2_slot8.setObjectName("age2_slot8")
        self.age2_slot0 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot0.setGeometry(QtCore.QRect(290, 520, 131, 211))
        self.age2_slot0.setText("")
        self.age2_slot0.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot0.setScaledContents(True)
        self.age2_slot0.setObjectName("age2_slot0")
        self.age2_slot1 = QtWidgets.QLabel(parent=self.age2_board)
        self.age2_slot1.setGeometry(QtCore.QRect(430, 520, 131, 211))
        self.age2_slot1.setText("")
        self.age2_slot1.setPixmap(QtGui.QPixmap("images/age2back.jpg"))
        self.age2_slot1.setScaledContents(True)
        self.age2_slot1.setObjectName("age2_slot1")
        self.age2_slot16.raise_()
        self.age2_slot15.raise_()
        self.age2_slot18.raise_()
        self.age2_slot17.raise_()
        self.age2_slot14.raise_()
        self.age2_slot19.raise_()
        self.age2_slot13.raise_()
        self.age2_slot10.raise_()
        self.age2_slot9.raise_()
        self.age2_slot11.raise_()
        self.age2_slot12.raise_()
        self.age2_slot8.raise_()
        self.age2_slot6.raise_()
        self.age2_slot7.raise_()
        self.age2_slot5.raise_()
        self.age2_slot2.raise_()
        self.age2_slot3.raise_()
        self.age2_slot4.raise_()
        self.age2_slot0.raise_()
        self.age2_slot1.raise_()
        self.label = QtWidgets.QLabel(parent=self.centralwidget)
        self.label.setGeometry(QtCore.QRect(510, -10, 871, 231))
        self.label.setText("")
        self.label.setPixmap(QtGui.QPixmap("images/board.png"))
        self.label.setScaledContents(True)
        self.label.setObjectName("label")
        self.age1_board = QtWidgets.QFrame(parent=self.centralwidget)
        self.age1_board.setGeometry(QtCore.QRect(520, 220, 851, 811))
        self.age1_board.setStyleSheet("background-color: rgb(255, 226, 153);")
        self.age1_board.setFrameShape(QtWidgets.QFrame.Shape.StyledPanel)
        self.age1_board.setFrameShadow(QtWidgets.QFrame.Shadow.Raised)
        self.age1_board.setObjectName("age1_board")
        self.age1_slot5 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot5.setGeometry(QtCore.QRect(710, 520, 131, 211))
        self.age1_slot5.setText("")
        self.age1_slot5.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot5.setScaledContents(True)
        self.age1_slot5.setObjectName("age1_slot5")
        self.age1_slot0 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot0.setGeometry(QtCore.QRect(10, 520, 131, 211))
        self.age1_slot0.setText("")
        self.age1_slot0.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot0.setScaledContents(True)
        self.age1_slot0.setObjectName("age1_slot0")
        self.age1_slot8 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot8.setGeometry(QtCore.QRect(360, 410, 131, 211))
        self.age1_slot8.setText("")
        self.age1_slot8.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot8.setScaledContents(True)
        self.age1_slot8.setObjectName("age1_slot8")
        self.age1_slot9 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot9.setGeometry(QtCore.QRect(500, 410, 131, 211))
        self.age1_slot9.setText("")
        self.age1_slot9.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot9.setScaledContents(True)
        self.age1_slot9.setObjectName("age1_slot9")
        self.age1_slot1 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot1.setGeometry(QtCore.QRect(150, 520, 131, 211))
        self.age1_slot1.setText("")
        self.age1_slot1.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot1.setScaledContents(True)
        self.age1_slot1.setObjectName("age1_slot1")
        self.age1_slot12 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot12.setGeometry(QtCore.QRect(290, 300, 131, 211))
        self.age1_slot12.setText("")
        self.age1_slot12.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot12.setScaledContents(True)
        self.age1_slot12.setObjectName("age1_slot12")
        self.age1_slot15 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot15.setGeometry(QtCore.QRect(220, 190, 131, 211))
        self.age1_slot15.setText("")
        self.age1_slot15.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot15.setScaledContents(True)
        self.age1_slot15.setObjectName("age1_slot15")
        self.age1_slot4 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot4.setGeometry(QtCore.QRect(570, 520, 131, 211))
        self.age1_slot4.setText("")
        self.age1_slot4.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot4.setScaledContents(True)
        self.age1_slot4.setObjectName("age1_slot4")
        self.age1_slot2 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot2.setGeometry(QtCore.QRect(290, 520, 131, 211))
        self.age1_slot2.setText("")
        self.age1_slot2.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot2.setScaledContents(True)
        self.age1_slot2.setObjectName("age1_slot2")
        self.age1_slot17 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot17.setGeometry(QtCore.QRect(500, 190, 131, 211))
        self.age1_slot17.setText("")
        self.age1_slot17.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot17.setScaledContents(True)
        self.age1_slot17.setObjectName("age1_slot17")
        self.age1_slot14 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot14.setGeometry(QtCore.QRect(570, 300, 131, 211))
        self.age1_slot14.setText("")
        self.age1_slot14.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot14.setScaledContents(True)
        self.age1_slot14.setObjectName("age1_slot14")
        self.age1_slot3 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot3.setGeometry(QtCore.QRect(430, 520, 131, 211))
        self.age1_slot3.setText("")
        self.age1_slot3.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot3.setScaledContents(True)
        self.age1_slot3.setObjectName("age1_slot3")
        self.age1_slot11 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot11.setGeometry(QtCore.QRect(150, 300, 131, 211))
        self.age1_slot11.setText("")
        self.age1_slot11.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot11.setScaledContents(True)
        self.age1_slot11.setObjectName("age1_slot11")
        self.age1_slot7 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot7.setGeometry(QtCore.QRect(220, 410, 131, 211))
        self.age1_slot7.setText("")
        self.age1_slot7.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot7.setScaledContents(True)
        self.age1_slot7.setObjectName("age1_slot7")
        self.age1_slot13 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot13.setGeometry(QtCore.QRect(430, 300, 131, 211))
        self.age1_slot13.setText("")
        self.age1_slot13.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot13.setScaledContents(True)
        self.age1_slot13.setObjectName("age1_slot13")
        self.age1_slot10 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot10.setGeometry(QtCore.QRect(640, 410, 131, 211))
        self.age1_slot10.setText("")
        self.age1_slot10.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot10.setScaledContents(True)
        self.age1_slot10.setObjectName("age1_slot10")
        self.age1_slot16 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot16.setGeometry(QtCore.QRect(360, 190, 131, 211))
        self.age1_slot16.setText("")
        self.age1_slot16.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot16.setScaledContents(True)
        self.age1_slot16.setObjectName("age1_slot16")
        self.age1_slot6 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot6.setGeometry(QtCore.QRect(80, 410, 131, 211))
        self.age1_slot6.setText("")
        self.age1_slot6.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot6.setScaledContents(True)
        self.age1_slot6.setObjectName("age1_slot6")
        self.age1_slot18 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot18.setGeometry(QtCore.QRect(290, 80, 131, 211))
        self.age1_slot18.setText("")
        self.age1_slot18.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot18.setScaledContents(True)
        self.age1_slot18.setObjectName("age1_slot18")
        self.age1_slot19 = QtWidgets.QLabel(parent=self.age1_board)
        self.age1_slot19.setGeometry(QtCore.QRect(430, 80, 131, 211))
        self.age1_slot19.setText("")
        self.age1_slot19.setPixmap(QtGui.QPixmap("images/age1back.jpg"))
        self.age1_slot19.setScaledContents(True)
        self.age1_slot19.setObjectName("age1_slot19")
        self.age1_slot18.raise_()
        self.age1_slot19.raise_()
        self.age1_slot16.raise_()
        self.age1_slot15.raise_()
        self.age1_slot17.raise_()
        self.age1_slot12.raise_()
        self.age1_slot13.raise_()
        self.age1_slot11.raise_()
        self.age1_slot14.raise_()
        self.age1_slot9.raise_()
        self.age1_slot8.raise_()
        self.age1_slot6.raise_()
        self.age1_slot7.raise_()
        self.age1_slot10.raise_()
        self.age1_slot0.raise_()
        self.age1_slot4.raise_()
        self.age1_slot1.raise_()
        self.age1_slot3.raise_()
        self.age1_slot5.raise_()
        self.age1_slot2.raise_()
        self.age3_board = QtWidgets.QFrame(parent=self.centralwidget)
        self.age3_board.setGeometry(QtCore.QRect(520, 220, 851, 811))
        self.age3_board.setStyleSheet("background-color: rgb(244, 220, 255);")
        self.age3_board.setFrameShape(QtWidgets.QFrame.Shape.StyledPanel)
        self.age3_board.setFrameShadow(QtWidgets.QFrame.Shadow.Raised)
        self.age3_board.setObjectName("age3_board")
        self.age3_slot5 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot5.setGeometry(QtCore.QRect(160, 410, 121, 191))
        self.age3_slot5.setText("")
        self.age3_slot5.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot5.setScaledContents(True)
        self.age3_slot5.setObjectName("age3_slot5")
        self.age3_slot0 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot0.setGeometry(QtCore.QRect(300, 610, 121, 191))
        self.age3_slot0.setText("")
        self.age3_slot0.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot0.setScaledContents(True)
        self.age3_slot0.setObjectName("age3_slot0")
        self.age3_slot8 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot8.setGeometry(QtCore.QRect(580, 410, 121, 191))
        self.age3_slot8.setText("")
        self.age3_slot8.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot8.setScaledContents(True)
        self.age3_slot8.setObjectName("age3_slot8")
        self.age3_slot9 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot9.setGeometry(QtCore.QRect(230, 310, 121, 191))
        self.age3_slot9.setText("")
        self.age3_slot9.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot9.setScaledContents(True)
        self.age3_slot9.setObjectName("age3_slot9")
        self.age3_slot1 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot1.setGeometry(QtCore.QRect(440, 610, 121, 191))
        self.age3_slot1.setText("")
        self.age3_slot1.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot1.setScaledContents(True)
        self.age3_slot1.setObjectName("age3_slot1")
        self.age3_slot12 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot12.setGeometry(QtCore.QRect(300, 210, 121, 191))
        self.age3_slot12.setText("")
        self.age3_slot12.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot12.setScaledContents(True)
        self.age3_slot12.setObjectName("age3_slot12")
        self.age3_slot15 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot15.setGeometry(QtCore.QRect(230, 110, 121, 191))
        self.age3_slot15.setText("")
        self.age3_slot15.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot15.setScaledContents(True)
        self.age3_slot15.setObjectName("age3_slot15")
        self.age3_slot4 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot4.setGeometry(QtCore.QRect(510, 510, 121, 191))
        self.age3_slot4.setText("")
        self.age3_slot4.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot4.setScaledContents(True)
        self.age3_slot4.setObjectName("age3_slot4")
        self.age3_slot2 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot2.setGeometry(QtCore.QRect(230, 510, 121, 191))
        self.age3_slot2.setText("")
        self.age3_slot2.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot2.setScaledContents(True)
        self.age3_slot2.setObjectName("age3_slot2")
        self.age3_slot17 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot17.setGeometry(QtCore.QRect(510, 110, 121, 191))
        self.age3_slot17.setText("")
        self.age3_slot17.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot17.setScaledContents(True)
        self.age3_slot17.setObjectName("age3_slot17")
        self.age3_slot14 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot14.setGeometry(QtCore.QRect(580, 210, 121, 191))
        self.age3_slot14.setText("")
        self.age3_slot14.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot14.setScaledContents(True)
        self.age3_slot14.setObjectName("age3_slot14")
        self.age3_slot3 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot3.setGeometry(QtCore.QRect(370, 510, 121, 191))
        self.age3_slot3.setText("")
        self.age3_slot3.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot3.setScaledContents(True)
        self.age3_slot3.setObjectName("age3_slot3")
        self.age3_slot11 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot11.setGeometry(QtCore.QRect(160, 210, 121, 191))
        self.age3_slot11.setText("")
        self.age3_slot11.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot11.setScaledContents(True)
        self.age3_slot11.setObjectName("age3_slot11")
        self.age3_slot7 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot7.setGeometry(QtCore.QRect(440, 410, 121, 191))
        self.age3_slot7.setText("")
        self.age3_slot7.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot7.setScaledContents(True)
        self.age3_slot7.setObjectName("age3_slot7")
        self.age3_slot13 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot13.setGeometry(QtCore.QRect(440, 210, 121, 191))
        self.age3_slot13.setText("")
        self.age3_slot13.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot13.setScaledContents(True)
        self.age3_slot13.setObjectName("age3_slot13")
        self.age3_slot10 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot10.setGeometry(QtCore.QRect(510, 310, 121, 191))
        self.age3_slot10.setText("")
        self.age3_slot10.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot10.setScaledContents(True)
        self.age3_slot10.setObjectName("age3_slot10")
        self.age3_slot16 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot16.setGeometry(QtCore.QRect(370, 110, 121, 191))
        self.age3_slot16.setText("")
        self.age3_slot16.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot16.setScaledContents(True)
        self.age3_slot16.setObjectName("age3_slot16")
        self.age3_slot6 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot6.setGeometry(QtCore.QRect(300, 410, 121, 191))
        self.age3_slot6.setText("")
        self.age3_slot6.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot6.setScaledContents(True)
        self.age3_slot6.setObjectName("age3_slot6")
        self.age3_slot19 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot19.setGeometry(QtCore.QRect(440, 10, 121, 191))
        self.age3_slot19.setText("")
        self.age3_slot19.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot19.setScaledContents(True)
        self.age3_slot19.setObjectName("age3_slot19")
        self.age3_slot18 = QtWidgets.QLabel(parent=self.age3_board)
        self.age3_slot18.setGeometry(QtCore.QRect(300, 10, 121, 191))
        self.age3_slot18.setText("")
        self.age3_slot18.setPixmap(QtGui.QPixmap("images/age3back.jpg"))
        self.age3_slot18.setScaledContents(True)
        self.age3_slot18.setObjectName("age3_slot18")
        self.age3_slot19.raise_()
        self.age3_slot18.raise_()
        self.age3_slot15.raise_()
        self.age3_slot16.raise_()
        self.age3_slot17.raise_()
        self.age3_slot14.raise_()
        self.age3_slot11.raise_()
        self.age3_slot13.raise_()
        self.age3_slot12.raise_()
        self.age3_slot9.raise_()
        self.age3_slot10.raise_()
        self.age3_slot7.raise_()
        self.age3_slot6.raise_()
        self.age3_slot8.raise_()
        self.age3_slot5.raise_()
        self.age3_slot4.raise_()
        self.age3_slot3.raise_()
        self.age3_slot2.raise_()
        self.age3_slot0.raise_()
        self.age3_slot1.raise_()
        self.age3_board.raise_()
        self.age2_board.raise_()
        self.age1_board.raise_()
        self.p1_cards.raise_()
        self.p2_cards.raise_()
        self.label.raise_()
        app.setCentralWidget(self.centralwidget)
        self.menubar = QtWidgets.QMenuBar(parent=app)
        self.menubar.setGeometry(QtCore.QRect(0, 0, 1920, 21))
        self.menubar.setObjectName("menubar")
        self.menuGame = QtWidgets.QMenu(parent=self.menubar)
        self.menuGame.setObjectName("menuGame")
        app.setMenuBar(self.menubar)
        self.statusbar = QtWidgets.QStatusBar(parent=app)
        self.statusbar.setObjectName("statusbar")
        app.setStatusBar(self.statusbar)
        self.actionNew_Game = QtGui.QAction(parent=app)
        self.actionNew_Game.setObjectName("actionNew_Game")
        self.menuGame.addAction(self.actionNew_Game)
        self.menubar.addAction(self.menuGame.menuAction())

        self.retranslateUi(app)
        QtCore.QMetaObject.connectSlotsByName(app)

    def retranslateUi(self, app):
        _translate = QtCore.QCoreApplication.translate
        app.setWindowTitle(_translate("app", "Seven Wonders Duel"))
        self.menuGame.setTitle(_translate("app", "Game"))
        self.actionNew_Game.setText(_translate("app", "New Game"))
