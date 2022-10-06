#!/bin/bash
set -e

source /opt/ros/galactic/setup.bash
source /root/colcon_ws/install/setup.bash
/usr/lib/formant/formant-agent &

exec "$@"