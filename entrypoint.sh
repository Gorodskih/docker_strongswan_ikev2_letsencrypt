#!/bin/sh -e

echo "Starting entrypoint script..."

mkdir -p /logs/startup
/startup.sh 2>&1 | tee "/logs/startup/$(date +"%Y-%m-%dT%H:%M:%S").log"
