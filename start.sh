#!/bin/bash

source /opt/ros/galactic/setup.bash  # this adapter is meant to work with any ROS2 distribution
# if you use custom messages, source your workspace here
# python3 -m pip install -r requirements.txt
cd /root/colcon_ws/src/ros2-adapter/formant_ros2_adapter/src
python3 main.py