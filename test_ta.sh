#!/bin/bash

# Detect OS and version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_ID=$(echo $VERSION_ID | cut -d'.' -f1)
else
    echo "Unsupported OS"
    exit 1
fi

install_percona_telemetry() {

    case "$OS" in
        ol)
            # Oracle Linux
            if [ "$VERSION_ID" == "8" ] || [ "$VERSION_ID" == "9" ]; then
                sudo yum install -y https://repo.percona.com/yum/percona-release-latest.noarch.rpm
            else
                echo "Unsupported Oracle Linux version"
                exit 1
            fi
            ;;
        debian | ubuntu)
            if [ "$VERSION_ID" == "11" ] || [ "$VERSION_ID" == "12" ] || [ "$VERSION_ID" == "20" ] || [ "$VERSION_ID" == "22" ] || [ "$VERSION_ID" == "24" ]; then
                sudo apt-get update
                sudo apt-get install -y wget gnupg2 lsb-release curl systemd
                wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
                sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
            else
                echo "Unsupported Debian/Ubuntu version"
                exit 1
            fi
            ;;
        *)
            echo "Unsupported OS"
            exit 1
            ;;
    esac

    sudo percona-release enable telemetry

    if [ "$OS" == "ol" ]; then
        sudo yum install -y percona-telemetry-agent
    else
        sudo apt-get update
        sudo apt-get install -y percona-telemetry-agent
    fi

    sudo systemctl stop percona-telemetry-agent
    sudo systemctl disable percona-telemetry-agent

    sudo percona-release enable telemetry testing

    if [ "$OS" == "ol" ]; then
        sudo yum update -y percona-telemetry-agent
    else
        sudo apt-get update
        sudo apt-get install --only-upgrade -y percona-telemetry-agent
    fi

    systemctl is-enabled percona-telemetry-agent | grep -q "disabled"
    if [ $? -eq 0 ]; then
        echo "Service is still disabled as expected."
    else
        echo "Warning: Service is enabled, but it should be disabled."
    fi
}

install_percona_telemetry
