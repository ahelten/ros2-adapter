#!/usr/bin/env bash
set -e

exit_script() {
    echo "exiting installation script."
}
trap exit_script EXIT

. /etc/os-release

if [ -z "${VERSION_CODENAME}" ]; then
    echo "could not get linux distro version codename."
    exit 1
fi

supported_distros=("xenial" "bionic" "focal" "stretch" "buster" "bullseye" "jammy")
if ! printf '%s\n' ${supported_distros[@]} | grep -q -P '^'$VERSION_CODENAME'$'; then
    echo "distro $VERSION_CODENAME not supported"
    exit 1
fi

# Set provisioning token as input parameter or environment variable
provisioning_token=$([ -n "$1" ] && echo "$1" || echo "$FORMANT_PROVISIONING_TOKEN")
if [ -z "$provisioning_token" ]; then
    echo "provisioning token is required"
    exit 1
fi

sudo apt update

echo "ensuring 'universe' repo is enabled"
sudo apt install -y software-properties-common --no-install-recommends

if [ "$NAME" != "Raspbian GNU/Linux" ]; then
    sudo add-apt-repository universe
    sudo apt update
fi

echo "installing HTTPS dependencies"
sudo apt install -y apt-transport-https ca-certificates --no-install-recommends

use_gnupg_curl=("xenial" "buster")
if printf '%s\n' ${use_gnupg_curl[@]} | grep -q -P '^'$VERSION_CODENAME'$'; then
    sudo apt install -y gnupg-curl --no-install-recommends
fi

if apt-key list 2>/dev/null | grep -q formant; then
    echo "existing Formant package signature public key found"
else
    echo "adding Formant package signature public key"
    sudo apt-key adv --fetch-keys https://keys.formant.io/formant.pub.gpg
fi

if grep -Fq formant "/etc/apt/sources.list" >/dev/null; then
    echo "Formant repo already in sources list"
else
    echo "deb https://repo.formant.io/formant/debian $VERSION_CODENAME main" | sudo tee -a /etc/apt/sources.list >/dev/null
fi

echo formant-agent formant-agent/token password $provisioning_token | sudo debconf-set-selections
echo formant-agent formant-agent/port_forwarding boolean "true" | sudo debconf-set-selections

sudo apt update

if [ -n "${SOURCE_SCRIPT}" ]; then
    echo "setting source script debconf parameter to $SOURCE_SCRIPT"
    echo formant-agent formant-agent/source_script string "$SOURCE_SCRIPT" | sudo debconf-set-selections
fi

fd=0
if [ -t "$fd" ] || [ -p /dev/stdin ]; then
    sudo DEBIAN_FRONTEND=noninteractive apt install -y formant-agent --no-install-recommends
else
    sudo DEBIAN_FRONTEND=noninteractive apt install -y formant-agent --no-install-recommends
fi

sudo DEBIAN_FRONTEND=noninteractive apt install -y formant-sidecar --no-install-recommends