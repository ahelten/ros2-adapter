FROM osrf/ros:galactic-desktop

LABEL mantainer="chiragmakwana02@gmail.com"

SHELL ["/bin/bash","-c"]

RUN apt-get update && apt-get install -y \
  bash-completion \
  build-essential \
  cmake \
  gdb \
  git \
  pylint3 \
  python3-argcomplete \
  python3-colcon-common-extensions \
  python3-pip \
  python3-rosdep \
  python3-vcstool \
  vim \
  wget \
  # Install ros distro testing packages
  ros-galactic-ament-lint \
  ros-galactic-launch-testing \
  ros-galactic-launch-testing-ament-cmake \
  ros-galactic-launch-testing-ros \
  python3-autopep8 \
  && rm -rf /var/lib/apt/lists/* \
  && rosdep init || echo "rosdep already initialized" \
  # Update pydocstyle
  && pip install --upgrade pydocstyle

RUN python3 -m pip install numpy>=1.19.3 \
        formant \
        jsonschema \
        python-lzf \
        opencv-python 

ENV DEBIAN_FRONTEND=noninteractive

COPY ./ /root/colcon_ws/src/ros2-adapter
# RUN bash /root/colcon_ws/src/ros2-adapter/install-agent.sh b703158692e3ab8f76aeb0cea7c62606
RUN bash <(wget -q0 - https://app.formant.io/install-agent-docker.sh) b703158692e3ab8f76aeb0cea7c62606 
# RUN ls requirements
RUN ls /root/colcon_ws/src/ros2-adapter

#ROS workspace
ARG DOMAIN_ID

ENV ROS_DOMAIN_ID=${DOMAIN_ID}
ENV COLCON_WS=/root/colcon_ws
WORKDIR $COLCON_WS

# RUN cd $COLCON_WS && \
#     source /opt/ros/galactic/setup.bash && \
#     colcon build --symlink-install
# RUN pwd 


ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]