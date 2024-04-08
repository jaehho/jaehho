#!/bin/python3

# failsafe: move mouse to any one of the four corners of the primary monitor

import pyautogui
import time

delay = 5
while delay > 0:
	print(f"select window to type in | will start in {delay:.1f} seconds")
	time.sleep(0.1)
	delay -= 0.1
print("typing...")

strings = [
    "Hi!",
    "I_am_an_Electrical_Engineering_Major",
    "Driven_by_dual_passions_in_robotics_and_medicine",
    "Feel_free_to_reach_out_and_say_hi!"
]

interval = 0.03   # In Seconds

pause = 3
for string in strings:
	pyautogui.write(string, interval=interval)
	time.sleep(1)
	pyautogui.write("\n")
	time.sleep(pause)

print("complete")