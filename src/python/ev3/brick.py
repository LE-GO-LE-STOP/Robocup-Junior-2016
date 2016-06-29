from ev3dev.ev3 import Sound as _Sound
from ev3dev.ev3 import Leds as _Leds
from ev3dev.ev3 import Button as _Button

class Sound:
    @staticmethod
    def playTone(hz, seconds, wait = False):
        process = _Sound.tone([(hz, seconds * 1000)])

        if wait:
            process.wait()

    @staticmethod
    def playFile(filename, wait = False):
        process = _Sound.play(filename)

        if wait:
            process.wait()

    @staticmethod
    def speak(text, wait = False):
        process = _Sound.speak(text)

        if wait:
            process.wait()

class LED:
    def __init__(self, baseLED):
        self._baseLED = baseLED
        self._maxBrightness = self._baseLED.max_brightness

    def brightness(self, brt):
        if brt < 0 or brt > self._maxBrightness:
            print("Invalid brightness: " + str(brt))

        self._baseLED.brightness = brt

class LEDs:
    left = {"red": LED(_Leds.red_left), "green": LED(_Leds.green_left)}
    right = {"red": LED(_Leds.red_right), "green": LED(_Leds.green_right)}

Buttons = _Button()