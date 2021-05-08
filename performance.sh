#! /bin/bash

echo "Setting the cpu governor to performance..."
for ((i=0;i<$(nproc);i++)); do cpufreq-set -c $i -g performance; done
