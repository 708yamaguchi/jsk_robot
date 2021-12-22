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
        rospy.loginfo('Start shutdown node.')
        rospy.Service('shutdown', Empty, self.shutdown)
        rospy.Service('reboot', Empty, self.reboot)

    def shutdown(self, req):
        rospy.loginfo('Shut down robot.')
        shutdown_command = '/sbin/shutdown -h now'
        ret = os.system(shutdown_command)
        if ret != 0:
            rospy.logerr("Failed to call '$ {}'. Check authentication.".format(
                shutdown_command))
        return EmptyResponse()

    def reboot(self, req):
        rospy.loginfo('Reboot robot.')
        reboot_command = '/sbin/shutdown -r now'
        ret = os.system(reboot_command)
        if ret != 0:
            rospy.logerr("Failed to call '$ {}'. Check authentication.".format(
                reboot_command))
        return EmptyResponse()


if __name__ == '__main__':
    rospy.init_node('shutdown')
    s = Shutdown()
    rospy.spin()
