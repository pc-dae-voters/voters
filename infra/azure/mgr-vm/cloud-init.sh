#!/bin/bash
# This script is executed by cloud-init on the manager VM at first boot.
# It creates and then executes the main setup script, post-init.sh.

set -ex
exec > /tmp/cloud-init-bootstrap.log 2>&1

echo ">>> Starting cloud-init bootstrap..."

# Create the post-init.sh script using a heredoc
# Note the lack of quotes around EOF, allowing variable expansion
cat <<EOF > /tmp/post-init.sh
${post_init_sh}
EOF

echo ">>> Created /tmp/post-init.sh. Running it now..."

# Make it executable and then run it.
chmod +x /tmp/post-init.sh
/tmp/post-init.sh

echo ">>> Cloud-init bootstrap finished."
