#!/bin/bash
screen=($(xrandr | grep -w connected  | awk -F'[ +]' '{print $1,$3,$4}' | tail -n 1))

if [ ${screen[2]} -ne 0 ]
then
	$(xrandr --output HDMI1 --auto --right-of eDP1)
fi
