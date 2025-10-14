#!/bin/bash
# This script is executed by cloud-init on the manager VM at first boot.
# Its only job is to execute the main setup script, post-init.sh.

# Exit immediately if a command exits with a non-zero status.
set -e

# Log everything to a file for debugging the bootstrap process itself.
exec > /tmp/cloud-init-bootstrap.log 2>&1

echo ">>> Starting cloud-init bootstrap..."

# The main logic is in the post-init.sh script, which is passed in as a file.
# Make it executable and then run it.
chmod +x /tmp/post-init.sh
/tmp/post-init.sh

echo ">>> Cloud-init bootstrap finished."
