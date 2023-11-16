# DotA
Vi sitter här i Venten och spelar lite Dota

DotA took 10th place at Abbuc Software Contest 2023

It's Atari 800 XL/XE game, that runs on stock machine. Game is written for PAL, but it is also NTSC compatible (adjusted speed and colors). Game supports stereo pokey modification, but does not require it... when stereo is detected music plays in pseudo stereo mode (my own RMT player modification).

## How to play
It's a game where your task is to find invisible dot using blue cursor controlled by joystick. There are arrows pointing to the dot, so you have to assume its possition based on the directon of all the arrows in the level.
In the beginning everything is static, but later on the dot or/and arrows are moving which increases the difficulty... it is harder to catch the invisible dot with the cursor.

## Making of
Making of article on my blog: [LINK](http://matosimi.websupport.sk/atari/2023/10/dota-making-of/)

## Gameplay screenshots / video
![DotA Screen](http://matosimi.websupport.sk/atari/wp-content/uploads/2023/10/DotA.png)
![DotA Circles](http://matosimi.websupport.sk/atari/wp-content/uploads/2023/10/dota_circles.gif)

Video:
[![DotA](https://img.youtube.com/vi/wrRHaQpy54A/maxresdefault.jpg)](https://www.youtube.com/embed/wrRHaQpy54A)

## Download
Check the [releases](https://github.com/matosimi/DotA/releases).
Use Atari XL/XE or XEGS or [Altirra](https://www.virtualdub.org/altirra.html) emulator.

## How to compile
Use [mads](https://mads.atari8.info) to compile:

```
mads.exe DotA.asm -o:DotA.xex
```

## Contact
http://matosimi.atari.org
