# How to use this Apple2e FPGA Emulator

Made by Reet Sinha and Sid Vadyalam

## Vivado
***Note***: this step does not need to be done as a working hardware platform is already inside the apple2e folder <repo_dir>/apple2e/working.xsa

First open the apple2e.xpr in vivado. The apple2e.xpr is located in <repo_dir>/apple2e/apple2e.xpr. From there generate bitstream and export hardware platform (include bitstream). **Note**: this step does not need to be done as a working hardware platform is already inside the apple2e folder <repo_dir>/apple2e/working.xsa

## Vitis
Open up vitis and set your workspace as <repo_dir>/vitis_sdk. Right click mb_usb_hdmi_top and click update hardware platform and select your hardware platform. Build the application (keyboard_app_system) and run the application on the urbana board. If you have your peripherals connected (Keyboard and hdmi) you should be able to mess around.

This project was loaded in with a slightly buggy Tower of Hanoi program written in Applesoft BASIC. To run the program, type the following commands in BASIC
```BASIC
CALL 768
```
If you wish to see the program
```BASIC
LIST
```
To run simply type
```BASIC
RUN
```

If you want to try some other programs type
```BASIC
NEW
```
before entering your new program

Here are some basic tests you can try out!

Text mode test 1
```BASIC
10 HOME
20 FOR I = 1 TO 300
30 PRINT I; "  SQUARE="; I*I
40 NEXT I
50 PRINT "DONE"
```

Text mode test 2
```BASIC
10 HOME
20 FOR R = 1 TO 20
30 FOR C = 1 TO R
40 PRINT " ";
50 NEXT C
60 PRINT R
70 NEXT R
```
GR Test 1 (Crosshair)
```BASIC
10 GR
20 COLOR=15: HLIN 0,39 AT 0
30 HLIN 0,39 AT 39
40 VLIN 0,39 AT 0
50 VLIN 0,39 AT 39
60 COLOR=1: HLIN 0,39 AT 20
70 VLIN 0,39 AT 20
```
GR Test 2 (Random Confetti)
```BASIC
FOR I=1 TO 2000
30 X = INT(RND(1)*)
