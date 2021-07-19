#!/usr/bin/env python

# https://www.youtube.com/watch?v=HM-xG0qXaeA&&
# ffmpeg -i R2D2\ all\ Sounds\ -\ Star\ Wars\ free\ sounds.mp4 -ss 48 -t 10 R2D2.wav

import rospy
import time, socket, os
import netifaces as ni
import rospkg

from sound_play.libsoundplay import SoundClient
import actionlib

if __name__ == "__main__":
    rospy.init_node("boot_sound")
    sound = SoundClient(sound_action='sound_play', blocking=True)
    sound.actionclient.wait_for_server()

    if len(ni.ifaddresses('eth0')) > 2 :
        ip = ni.ifaddresses('eth0')[2][0]['addr']
    elif len(ni.ifaddresses('wlan0')) > 2 :
        ip = ni.ifaddresses('wlan0')[2][0]['addr']
    else:
        ip = None

    # play sound
    rospack = rospkg.RosPack()
    wav_file = os.path.join(rospack.get_path("jsk_fetch_startup"),"data/boot_sound.wav")
    rospy.loginfo("Playing {}".format(wav_file))
    sound.playWave(wav_file, replace=False)

    # notify ip address
    ip_text = "My internet address is {}".format(ip)
    rospy.loginfo(ip_text)
    ip_text = ip_text.replace('.', ', ')
    sound.say(ip_text, replace=False)
