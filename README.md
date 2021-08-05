# StepperCore
A RISC-V core written in verilog which can be used in pretty much any kind of robot.

[![Lint](https://github.com/0xDEADC0DEx/stepper/actions/workflows/lint.yml/badge.svg)](https://github.com/0xDEADC0DEx/stepper/actions/workflows/lint.yml)

For most of the projects documentation have a look at the github wiki.

## Used tools
This project was written/created with the following utilities:
* Yosys (For synthesis)
* nextpnr (For routing and placing)
* prjtrellis (Bitstream documentation for the LATTICE LFE5U-12F)
* icarus verilog (Used for simulation)
* gtkwave (For opening the produced waveforms of the simulation as a vcd file)
* freecad (Used for 3d modeling)

## Project structure
#### Subfolders
* src -> Holds all the verilog src files that are synthesizeable.
* tests -> Consists of all verilog testbenches (for each model one with the naming convention `test_<name>.v`).
* designs -> Contains all of the 3d models of the project.

#### Branches && Branching
* master -> Is merged with develop if develop contains reasonably stable code.
* develop -> Contains the latest pull requests.
* <any other branch> -> Development branch of someone

A change in code or whatever is **commited** to your **personal branch** (dev for instance).
If you think that the feature you are working on is done then open a **pull-request** to **develop** on github.
The code is then checked by another member of the team. Feedback on improvements should be given via the github comments in the pull request.
If all team members are happy with the changes then those changes will be merged into the develop branch.

Only after some major improvements will the develop branch finally merged into the master branch.

## Coding conventions
* One module per file (file should have the same name as the module does).
* Split code in functional blocks with spaces.

#### Variable naming conventions
* Every input and output wire or reg of a module (except for the top module) should contain either `_in` or `_out` as a surfix.
* Every name of every reg should contain `r_` as a prefix if it is not a counter variable in a loop.
* Every reg or wire which is active low has to have `_n_` before a input output surfix (`_in/_out`) but before the real name.

###### Example:
`Register Output which is active low: r_<name>_n_out`

`Wire which is an input: <name>_in`
