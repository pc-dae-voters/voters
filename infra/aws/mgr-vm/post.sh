# Display SSH command for manual key pair
echo "SSH command for manual key pair:"
echo "ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$(terraform output -raw public_ip)"

# Fix loader.key permissions
echo "Setting permissions on loader.key..."
if [[ -f loader.key ]]; then
  chmod 600 loader.key
  echo "Permissions set to 600 on loader.key."
else
  echo "WARNING: loader.key not found in current directory."
  echo "The Terraform configuration uses key pair: voters-data-loader-key-manual"
  echo "You need to obtain the private key file for this key pair and save it as 'loader.key'"
  echo "If you don't have the private key, you may need to:"
  echo "1. Create a new key pair in AWS Console"
  echo "2. Update the Terraform configuration to use the new key pair"
  echo "3. Download the private key and save it as 'loader.key'"
  echo ""
  echo "For now, skipping SSH tests..."
  exit 0
fi

# Get public IP from Terraform output
PUBLIC_IP=$(terraform output -raw public_ip)

# Verify SSH access
echo "Testing SSH access to instance at $PUBLIC_IP..."
if ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$PUBLIC_IP" "uptime"; then
  echo "SSH access verified."
else
  echo "ERROR: SSH access failed. Please check loader.key and instance status."
fi

# Check cloud-init status
echo "Checking cloud-init status on instance..."
ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$PUBLIC_IP" "sudo cloud-init status" 