#!/usr/bin/env bash
set -e

exit_script() {
    echo "exiting installation script."
}
trap exit_script EXIT

remove_container() {
    name=$1
    echo "stopping $name container..."
    sudo docker stop $name &>/dev/null || true
    echo "removing $name container..."
    sudo docker rm $name &>/dev/null || true
}

provisioning_token=$([ -n "$1" ] && echo "$1" || echo "$FORMANT_PROVISIONING_TOKEN")
if [[ ! -d /var/lib/formant && -z "$provisioning_token" ]]; then
    echo "provisioning token is required"
    exit 1
fi

arch=$(uname -m)
name=$(uname -s)

if [[ ! -f "/usr/bin/docker" ]]; then
    echo "docker is not installed, please see https://docs.docker.com/engine/install/ for instructions"
    exit 1
fi

if [ ! "$(id -u formant 2>/dev/null)" ]; then
    echo "setting up formant user"
    sudo groupadd -g 706 formant >/dev/null
    if [ "$name" == "Linux" ]; then
        sudo useradd --gid 706 -u 706 --system formant >/dev/null
        if [ $(getent group video) ]; then
            echo "adding formant user to video group"
            sudo usermod -aG video formant || true
        fi

        if [ $(getent group audio) ]; then
            echo "adding formant user to audio group"
            sudo usermod -aG audio formant || true
        fi
        if [[ $(getent group docker) ]]; then
            echo "adding formant user to docker group"
            sudo usermod -aG docker formant
            sudo chmod 666 /var/run/docker.sock
        fi
    fi
fi

# Cleanup and prep
remove_container formant-agent

if [[ ! -d /var/lib/formant ]]; then
    echo "setting up volume mount directories..."
    sudo rm -rf /var/lib/formant
    sudo mkdir -p /var/lib/formant
fi
echo "ensuring volume mount directory /var/lib/formant has correct permissions..."
sudo chown -R formant:formant /var/lib/formant

# Override default tag if FORMANT_AGENT_IMAGE_TAG is set
tag="${FORMANT_AGENT_IMAGE_TAG:=}"

ros_master_config=""
catkin_ws_config=""
if [ -n "${ROS_MASTER_URI}" ]; then
    ros_master_config=" -e ROS_MASTER_URI=$ROS_MASTER_URI "
    if [ -n "${CATKIN_WS}" ]; then
        catkin_ws_config=" -v $CATKIN_WS:/catkin_ws -e CATKIN_WS=/catkin_ws "
    fi
    tag="ros-melodic"
fi

if [[ -n "$FORMANT_AGENT_IMAGE_TAG" ]]; then
    echo "Using custom agent image tag: $FORMANT_AGENT_IMAGE_TAG"
elif [[ $arch == "x86_64" ]]; then
    if [[ $tag == "" ]]; then
        tag="latest"
    fi
elif [[ $arch == "aarch64" ]]; then
    if [[ $tag == "" ]]; then
        tag="arm64"
    else
        tag+="-arm64"
    fi
elif [[ $arch == "armv7l" ]]; then
    if [[ $tag == "" ]]; then
        tag="arm"
    else
        tag+="-arm"
    fi
fi

if [[ $tag == "" ]]; then
    tag="latest"
fi

uid=$(id -u formant)
gid=$(id -g formant)

echo "pulling latest formant-agent container..."
sudo docker pull formant/agent:focal-arm64

echo "starting up formant-agent container..."
sudo docker run -d -it --name formant-agent1 \
    --restart always \
    --net host \
    --pid host \
    --privileged \
    --user $uid:$gid \
    --group-add audio \
    --group-add video \
    # -v /var/lib/formant:/var/lib/formant \
    -v /usr/bin/docker:/usr/bin/docker \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e FORMANT_PROVISIONING_TOKEN=$provisioning_token \
    $ros_master_config \
    $catkin_ws_config \
    formant/agent:focal-arm64

echo "waiting for formant-agent to startup...."

sleep 10

sudo docker logs formant-agent
