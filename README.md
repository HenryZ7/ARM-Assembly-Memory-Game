# ARM-Assembly-Memory-Game
This is a game using ARM assembly that tests your memory. It was created using several different LED's and buttons connected on a breadboard to certain pins on the STM32401RE board. It is important to note that it was done on the Keil uVision platform, so changes may be needed if you plan on running this game elsewhere. 

349project.s is the code itself and has comments accordingly.

Here's how the game works:
To start, the board will play a pattern of flashing lights. The user needs to press the buttons in the same order that the lights were flashed in. If they press it in the correct order, then all 3 lights will flash and the next level will be displayed. This game does loop infinitely amongst 3 levels, but new levels can be added quite easily as long as pin assignments are correct.
