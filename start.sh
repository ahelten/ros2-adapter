#!/bin/bash

source /opt/ros/*/setup.bash  # this adapter is meant to work with any ROS2 distribution
# if you use custom messages, source your workspace here
source /opt/greenfield/weedbot/ros/weedbot_ros_setup.bash

python3 -m pip install -r requirements.txt
cd formant_ros2_adapter/scripts/
python3 main.py
