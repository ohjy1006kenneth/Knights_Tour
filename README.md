# Knight's Tour


A Knight's tour problem is a sequence of moves of a knight on a 5x5 chessboard such that the knight visits very square exactly once. 

![A screenshot of a computer Description
automatically generated](./media/KnightsTour.png)

I solved the Knight's tour problem in a Harware to make a little robot physically make the tour. The little robot have two motors, gyro sensor, three IR sensors, piezo, BLE Module, and a FPGA on top of it. I created the digial logic for the robot.

## Functionality
The Knight is controlled using a bluetooth module. Every command is 16 bit and there are currently 4 commands that Knight can interpret. Anatomy of move command is as follows: 

![A screenshot of a computer Description
automatically generated](./media/cmd_Anatomy.png)
![A screenshot of a computer Description
automatically generated](./media/cmd_opcode.png)

Since the chessboard is 5x5, the Knight's Tour will work only if the tour starts at a black tile of the chessboard.

## Verilog
The functionality of each codes are as follows:

**cmd_proc.sv:** Interpret incoming commands

**inert_intf.sv:** Configure gyro sensors and obtain readings from it (SPI)

**sponge.sv:** Plays SpongeBob theme song with a piezo bender

**PID.sv:** PID controller to make the Knight turn to desired heading

**MtrDrv.sv:** Receives values from PID to move two motors using PWM

**TourLogic.sv:** Computes "solution of the tour" which is an array of 24 moves encoded in memory. It enables TourCmd to "re-play" these moves on the physical board

**TourCmd.sv:** Decodes tour move from TourLogic to generate series of commands to send it to cmd_proc.

**UART_wrapper.sv:** Packages two bytes of command from Bluetooth module via UART (a byte based protocol)


Block Diagram of Digital Portion look like this: 

![A screenshot of a computer Description
automatically generated](./media/Block_Diagram.png)