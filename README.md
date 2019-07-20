# ATmega1284
Functions, Definitions, and Macros for the Atmel ATmega1284 MCU.

Also, basic functions and definitions for driving a Newhaven Display NHD-0420CW OLED Character Display module.
## Purpose
If you see a function here that you like, take it, it's yours. This is not really meant to be an installable software package, even though all of it has been built and tested.

Note: The word "tested" means that a function was built, run, and behaved as expected. Nothing exhaustive.
## Tools
- Atmel Studio 7
- AVR Assembler
- AVR Dragon
## Status
- TWI functions have been tested
- Display functions have been tested
- Re-organizing and applying polish. This will result in some significant improvements. Be patient.
## Pending
Schematic and board layout - this is still in flux.
## Comments
- Struggling with assembly language style and organization. I'll let you know when I reach enlightenment.
- There are no namespaces here. Every constant definition is global. Every function name, every address label, is global. This requires a serious coping mechanism.
- Deep breath. Count to 8.
