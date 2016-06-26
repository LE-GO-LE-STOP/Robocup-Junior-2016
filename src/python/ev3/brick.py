from ev3dev.ev3 import Sound as ev3Sound
from ev3dev.ev3 import Leds

class Sound:
    @staticmethod
    def playTone(hz, seconds, wait):
        process = ev3Sound.tone((hz, seconds * 1000))

        if wait:
            process.wait()

    @staticmethod
    def playFile(filename, wait):
        process = ev3Sound.play(filename)

        if wait:
            process.wait()

    @staticmethod
    def speak(text, wait):
        process = ev3Sound.speak(text)

        if wait:
            process.wait()

class PowerSupply:


class LED:
    def __init__(self, baseLED):
        self._baseLED = baseLED
        self._maxBrightness = self._baseLED.max_brightness

    def brightness(self, brt)
        if brt < 0 or brt > self._maxBrightness:
            print("Invalid brightness: " + str(brt))

        self._baseLED.brightness = brt

class LEDs:
    left = {"red": LED(Leds.red_left), "green": Led(Leds.green_left)}
    right = {"red": LED(Leds.red_right), "green": Led(Leds.green_right)}

class Buttons:
