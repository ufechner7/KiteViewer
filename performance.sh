#! /bin/bash

if [ $(uname) != "Linux" ] ; then
    echo "For now, setting the performance is only working on Linux..."
    exit 1
fi

# Check root permissions
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root"
    exit 1
fi

echo "Setting the cpu governor to performance..."
for ((i=0;i<$(nproc);i++)); do cpufreq-set -c $i -g performance; done
