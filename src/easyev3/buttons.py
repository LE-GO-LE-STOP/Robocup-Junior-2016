#!/usr/bin/env python
#from https://github.com/ev3dev/ev3dev/wiki/Using-the-Buttons

import array
import fcntl
import sys

# from linux/input.h

KEY_up = 103
KEY_down = 108
KEY_left = 105
KEY_right = 106
KEY_center = 28
KEY_end = 1

KEY_MAX = 0x2ff

def EVIOCGKEY(length):
    return 2 << (14+8+8) | length << (8+8) | ord('E') << 8 | 0x18

# end of stuff from linux/input.h

BUF_LEN = (KEY_MAX + 7) / 8

def test_bit(bit, bytes):
    # bit in bytes is 1 when released and 0 when pressed
    return not bool(bytes[bit / 8] & 1 << bit % 8)

def main():
    buf = array.array('B', [0] * BUF_LEN)
    with open('/dev/input/by-path/platform-gpio-keys.0-event', 'r') as fd:
        ret = fcntl.ioctl(fd, EVIOCGKEY(len(buf)), buf)

    if ret < 0:
        print "ioctl error", ret
        sys.exit(1)

    for key in ['up', 'down', 'left', 'right', 'center', 'end']:
        key_code = globals()['KEY_' + key]
        key_state = test_bit(key_code, buf) and "pressed" or "released"
        print key + " " + key_state

main()