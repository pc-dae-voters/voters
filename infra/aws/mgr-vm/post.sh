# Display SSH command for manual key pair
echo "SSH command for manual key pair:"
echo "ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$(terraform output -raw public_ip)"

# Save the generated private key to a file
echo "Saving generated private key to loader.key..."
terraform output -raw private_key > loader.key
chmod 600 loader.key
echo "Private key saved to loader.key with permissions 600."

# Get public IP from Terraform output
PUBLIC_IP=$(terraform output -raw public_ip)

# Verify SSH access
echo "Testing SSH access to instance at $PUBLIC_IP..."
if ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$PUBLIC_IP" "uptime"; then
  echo "SSH access verified."
else
  echo "ERROR: SSH access failed. Please check instance status."
  echo "The instance might still be starting up. Try again in a few minutes."
fi

# Check cloud-init status
echo "Checking cloud-init status on instance..."
ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$PUBLIC_IP" "sudo cloud-init status" 