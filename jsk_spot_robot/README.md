jsk_spot_robot
==============

## Setup Environment

First, you need to install ros. For ros melodic, please refer to install guide like [here](http://wiki.ros.org/melodic/Installation/Ubuntu).
Then, create workspace.
```bash
mkdir -p catkin_ws/src
cd  catkin_ws/src
wstool init .
wstool set --git jsk-ros-pkg/jsk_robot https://github.com/jsk-ros-pkg/jsk_robot.git -y
wstool merge -t . https://raw.githubusercontent.com/jsk-ros-pkg/jsk_robot/master/jsk_spot_robot/jsk_spot_user.rosinstall
wstool update -t .
source /opt/ros/$ROS_DISTRO/setup.bash
rosdep install -y -r --from-paths . --ignore-src
cd ../
catkin build spoteus jsk_spot_startup
source devel/setup.bash
```
