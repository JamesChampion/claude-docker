#!/bin/bash
# Entrypoint script for DinD testing
# Starts Docker daemon and runs the test script

set -e

echo "Starting Docker daemon..."
dockerd-entrypoint.sh &

# Wait for Docker daemon to be ready
echo "Waiting for Docker daemon to be ready..."
timeout=30
count=0
while ! docker info >/dev/null 2>&1; do
    if [ $count -ge $timeout ]; then
        echo "ERROR: Docker daemon failed to start within ${timeout} seconds"
        exit 1
    fi
    echo "Waiting for Docker... ($count/$timeout)"
    sleep 1
    count=$((count + 1))
done

echo "Docker daemon is ready!"
docker info

# Switch to testuser and run the test script
echo "Running test script as testuser..."
su - testuser -c "/home/testuser/test-setup.sh"

# Keep container running if tests pass
echo "Tests completed successfully!"
tail -f /dev/null
