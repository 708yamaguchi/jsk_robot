#!/usr/bin/env python

import os
import rospy
from std_srvs.srv import Empty, EmptyResponse


class Shutdown(object):
    """
    This node shuts down or reboots the robot itself
    according to the rosservice.

    Note that this node needs to be run with sudo privileges.

    Usage:
    # Launch node
    $ su [sudo user] -c ". [setup.bash]; rosrun jsk_robot_startup shutdown.py"

    # To shutdown robot
    rosservice call /shutdown
    # To restart robot
    rosservice call /reboot
    """

    def __init__(self):
        rospy.Service('shutdown', Empty, self.shutdown)
        rospy.Service('reboot', Empty, self.reboot)

    def shutdown(self, req):
        rospy.loginfo('Shut down robot.')
        os.system('/sbin/shutdown -h now')
        return EmptyResponse()

    def reboot(self, req):
        rospy.loginfo('Reboot robot.')
        os.system('/sbin/shutdown -r now')
        return EmptyResponse()


if __name__ == '__main__':
    rospy.init_node('shutdown')
    s = Shutdown()
    rospy.spin()
