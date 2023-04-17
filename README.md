# MATLAB-Connect4

![Connect 4 Gameplay](https://github.com/NoahK216/MATLAB-Connect4/blob/master/Animation.gif)

This is a Connect 4 game implemented in MATLAB. The game allows players to play against each other or against an AI player. The AI player has a sliding difficulty scale that goes from 0 to 100.

# Game rules
The game is played on a vertical board consisting of 7 columns and 6 rows. Players take turns dropping their colored discs from the top of the board. The goal of the game is to connect four discs of the same color vertically, horizontally, or diagonally. The first player to connect four discs wins the game.

# Running the game
To run the game, open the Connect4.m file in MATLAB and run it. The game will open in a separate window.

# Playing the game
During the game setup, each player can be either human-controlled or computer-controlled by adjusting their respective sliders. The slider value ranges from 0 to 100, where a value of 0 means the player is controlled by a human and any value between 1 and 100 means the computer will act perform at that difficulty. A level 1 player will make random moves, where a level 100 player will always make mathematically perfect moves.

During the game, the user can select a column to drop their disc into by clicking anywhere in the corresponding column. The game will automatically switch between the players after each turn. If the game ends in a tie, a message will be displayed indicating that the game is a draw.

# Player sliders and pause menu
The game has a pause menu that can be accessed by hitting the "escape" key. The pause menu has three buttons: "Restart", "Resume", and "Quit".

This pause menu holds the two sliders that allow the user to adjust the difficulty level of each player. If both players are computer controlled, the game will be played automatically, and the user can watch the game progress without having to make any moves.

# Acknowledgments
This game was developed by Noah Klein as a project for 1181. The game was developed using MATLAB R2022b.
