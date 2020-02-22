# Mater

## Overview

*Mater* is a mate searching program written in Pascal by Valentin Albillo.

In this repository you can find the original program by V. Albillo, and a version retouched by me (Roland Chastain). The most noticeable modification that I made is to change the console program to a Pascal unit. I also made a little demo, using the examples from the original documentation.

You can find the original program [here](original/mater.txt). The compressed file *website.zip* contains the documentation of the original program.

## Examples

Here are eight problems coming from Mater original website. These problems are solved in the program *demo.pas*.

### Position 1

![alt text](pictures/position1.png)

    Search mode: all moves
    Maximum moves number: 3
    Result: b7a8n
    Time elapsed: 00:00:00:010

### Position 2

![alt text](pictures/position2.png)

    Search mode: all moves
    Maximum moves number: 3
    Result: h6c1
    Time elapsed: 00:00:00:004

### Position 3

![alt text](pictures/position3.png)

    Search mode: all moves
    Maximum moves number: 4
    Result: d6c7
    Time elapsed: 00:00:00:053

### Position 4

![alt text](pictures/position4.png)

    Search mode: all moves
    Maximum moves number: 4
    Result: f6d5
    Time elapsed: 00:00:01:395

### Position 5

![alt text](pictures/position5.png)

    Search mode: all moves
    Maximum moves number: 3
    Result: h7g7
    Time elapsed: 00:00:00:005

### Position 6

![alt text](pictures/position6.png)

    Search mode: all moves
    Maximum moves number: 3
    Result: b7b8r
    Time elapsed: 00:00:00:012

### Position 7

![alt text](pictures/position7.png)

    Search mode: all moves
    Maximum moves number: 3
    Result: e7e8b
    Time elapsed: 00:00:00:008

### Position 8

![alt text](pictures/position8.png)

    Search mode: check sequence
    Maximum moves number: 12
    Result: h3g5
    Time elapsed: 00:00:00:036

As you can see, *Mater* has two search modes: either he searches for all moves, or he only searches for checkmate by consecutive checks (as in the last example).
