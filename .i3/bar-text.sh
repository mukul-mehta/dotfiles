 
#!/bin/sh

clock() {
    date +%H:%M:%S
}

battery() {
    cat /sys/class/power_supply/BAT0/capacity
}


BAR_INPUT="%{c}LIFE : $(battery)%% TIME : $(clock)"
echo $BAR_INPUT
