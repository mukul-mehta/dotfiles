#!/usr/bin/env python3
#
# Weather blocklet script for i3blocks

import os
from pyowm import OWM

# Set the api key before using this script
api_key = "589801fcff0d50f0a83596268fcd3c9a"

def get_icon(wtype):
    FA_SUN = "<span font='FontAwesome'>\uf0a3</span>"
    FA_MOON = "<span font='FontAwesome'>\uf186</span>"
    FA_CLOUD = "<span font='FontAwesome'>\uf0c2</span>"
    FA_UMBRELLA = "<span font='FontAwesome'>\uf0e9</span>"
    FA_LIGHTNING = "<span font='FontAwesome'>\uf0e7</span>"
    FA_ASTERIKS = "<span font='FontAwesome'>\uf069</span>"
    FA_ALIGN_LEFT = "<span font='FontAwesome'>\uf036</span>"
    FA_UNLINK = "<span font='FontAwesome'>\uf127</span>"

    # get icon according to weather condition codes
    # http://openweathermap.org/weather-conditions

    if wtype.startswith('01'):
        # clear sky
        if wtype[2] == 'd':
            icon = "<span color='yellow'>{}</span>".format(FA_SUN)
        else:
            icon = "<span color='yellow'>{}</span>".format(FA_MOON)
    elif wtype.startswith('02'):
        # few clouds
        if wtype[2] == 'd':
            icon = FA_SUN
        else:
            icon = FA_MOON
    elif wtype.startswith('03'):
        # scattered clouds
        icon = FA_CLOUD
    elif wtype.startswith('04'):
        # broken clouds
        icon = "<span color='blue'>{}</span>".format(FA_CLOUD)
    elif wtype.startswith('09'):
        # shower rain
        icon = "<span color='blue'>{}</span>".format(FA_UMBRELLA)
    elif wtype.startswith('10'):
        # rain
        icon = FA_UMBRELLA
    elif wtype.startswith('11'):
        # thunderstorm
        icon = FA_LIGHTNING
    elif wtype.startswith('13'):
        # Snowy
        icon = FA_ASTERIKS
    elif wtype.startswith('50'):
        # Misty
        icon = FA_ALIGN_LEFT
    else:
        # Unknown
        icon = FA_UNLINK
    return icon


city_id  = os.environ.get('BLOCK_INSTANCE')
if not city_id:
    # Defaults to London, UK
    city_id = 2643743

try:  # connect
    owm = OWM(api_key)
    obs = owm.weather_at_id( int(city_id) )
    w = obs.get_weather()
except Exception:
    # If api call failed, shows error message
    FA_UNLINK = "<span font='FontAwesome'>\uf127</span>"
    text = FA_UNLINK + " NO CONNECTION"
    print(text)
    print(text)
    exit(33)

text = get_icon(w.get_weather_icon_name())
temp = w.get_temperature('celsius')['temp']
text += str(round(temp)).rjust(3) 

# Degree symbol
text += '\u00b0'

print(text)
print(text)
