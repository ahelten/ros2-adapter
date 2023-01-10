#!/bin/bash
SCRIPT_DIR=$( dirname $( readlink -f "$0" ) )

source /opt/ros/*/setup.bash  # this adapter is meant to work with any ROS2 distribution
# if you use custom messages, source your workspace here
source /opt/greenfield/weedbot/ros/weedbot_ros_setup.bash

#add current directory to trusted git source if not present in git config
EXISTING_DIR=$(git config --global --get-all safe.directory | grep "$SCRIPT_DIR" | head -1)
if [ "$SCRIPT_DIR" != "$EXISTING_DIR" ]; then
    git config --global --add safe.directory "$SCRIPT_DIR"
fi
git pull

# patch agent for overall video support
patch /lib/formant/agent/common/encoded_video_telemetry_uploader.py formant_ros2_adapter/scripts/patches/encoded_video_telemetry_uploader.patch
patch /lib/formant/agent/common/h264_encoder.py formant_ros2_adapter/scripts/patches/h264_encoder.patch

python3 -m pip install -r requirements.txt
cd formant_ros2_adapter/scripts/
python3 main.py &
python3 ros_msg_handler.py &
python3 overall_video_uploader.py
