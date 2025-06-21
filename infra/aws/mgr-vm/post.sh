# Display SSH command for manual key pair
echo "SSH command for manual key pair:"
echo "ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$(terraform output -raw public_ip)" 