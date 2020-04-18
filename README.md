# vhdl_pong

## Description
Initially it was a VGA learning project but it quickly expandend to implementation of simple PONG game :)

I based my VGA knowledge on this presentation:
http://ece-research.unm.edu/jimp/vhdl_fpgas/slides/VGA.pdf

Paddles & ball are drawn as separate objects with specified LEFT, RIGHT, START and END boundaries.
Their sizes and colors can be adjusted. Ball shape can be modified too, beacuse it is written as 2D ROM map.

Score is displayed on 7segment displays mounted on board.

I had an idea to control the paddles using PC and UART but as i have tested it is not possible for the game to be playable.
UART modules are left as an example.

Players can control the paddles using switches mounted on a board. Game starts when another switch is pressed.

I also implemented scalable angle of ball bouncing - different velocities are programmed as ROM LUT and the choice depends on the place where the ball and paddle meet.

TODO photos and rest of documentation

## Hardware
Elbert v2 board.
