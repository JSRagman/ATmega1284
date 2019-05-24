# ATmega1284
Functions, Definitions, and Macros for the Atmel ATmega1284 MCU
## Status
Work in Progress... Functions are being added ~~daily~~ ~~often~~ every now and then.
Code in this repository has been handled with care but not tested. This message will change when testing is complete.
## Comments
### Macros
I use macros heavily when a project is getting started and pushed into shape. As the project matures, macros are gradually eliminated unless they provide a serious benefit.

A case in point is the data stack. Macros nicely encapsulate data stack functions. Here is where I'm most tempted to drop the m_ prefix and go with pushd, pushdi, popd, and peekd.
### Function Labels
When a project is in the early stages of growth, I go bonkers in fully qualifying function labels and constant names. When everything is settled and in place, I will give them a good haircut.
