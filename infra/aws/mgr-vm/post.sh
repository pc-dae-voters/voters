# Save the generated private key to a file
echo "Saving generated private key to loader.key..."
terraform output -raw private_key > loader.key
chmod 600 loader.key
echo "Private key saved to loader.key with permissions 600."

# Get public IP from Terraform output
PUBLIC_IP=$(terraform output -raw public_ip)

# Save IP address to file for mgr-ssh.sh script
echo "$PUBLIC_IP" > instance-ip.txt
echo "Instance IP saved to instance-ip.txt"

# Verify SSH access
echo "Testing SSH access to instance at $PUBLIC_IP..."
if ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$PUBLIC_IP" "uptime"; then
  echo "SSH access verified."
else
  echo "ERROR: SSH access failed. Please check instance status."
  echo "The instance might still be starting up. Try again in a few minutes."
  exit 1
fi

# Check cloud-init status and wait for completion
echo "Checking cloud-init status on instance..."
echo "Waiting for cloud-init to complete (this may take several minutes)..."
for i in {1..30}; do
  CLOUD_INIT_STATUS=$(ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$PUBLIC_IP" "sudo cloud-init status" 2>/dev/null || echo "unknown")
  
  if [[ "$CLOUD_INIT_STATUS" == "status: done" ]]; then
    echo "✅ Cloud-init completed successfully!"
    break
  elif [[ "$CLOUD_INIT_STATUS" == "status: running" ]]; then
    echo "⏳ Cloud-init still running... (attempt $i/30)"
    sleep 30
  elif [[ "$CLOUD_INIT_STATUS" == "status: error" ]]; then
    echo "❌ Cloud-init failed with error!"
    ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$PUBLIC_IP" "sudo tail -20 /var/log/cloud-init-output.log"
    exit 1
  else
    echo "⏳ Cloud-init status: $CLOUD_INIT_STATUS (attempt $i/30)"
    sleep 30
  fi
done

if [[ "$CLOUD_INIT_STATUS" != "status: done" ]]; then
  echo "❌ Cloud-init did not complete within the expected time."
  echo "Check the cloud-init logs manually:"
  echo "ssh -i loader.key ec2-user@$PUBLIC_IP"
  echo "sudo tail -f /var/log/cloud-init-output.log"
  exit 1
fi

# Verify cloud-init outcome
echo "Verifying cloud-init installation..."
echo "Checking Terraform installation..."
if ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$PUBLIC_IP" "terraform version"; then
  echo "✅ Terraform installed successfully"
else
  echo "❌ Terraform installation failed"
fi

echo "Checking AWS CLI installation..."
if ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$PUBLIC_IP" "aws --version"; then
  echo "✅ AWS CLI installed successfully"
else
  echo "❌ AWS CLI installation failed"
fi

echo "Checking repository clone..."
if ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$PUBLIC_IP" "ls -la /home/ec2-user/pc-dae-voters/"; then
  echo "✅ Repository cloned successfully"
else
  echo "❌ Repository clone failed"
fi

echo "Checking database environment file..."
if ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@"$PUBLIC_IP" "ls -la /home/ec2-user/pc-dae-voters/infra/db/db-env.sh"; then
  echo "✅ Database environment file created"
else
  echo "❌ Database environment file not found"
fi

echo ""
echo "🎉 Manager instance setup completed!"
echo ""
echo "SSH command for manual access:"
echo "./bin/mgr-ssh.sh"
echo ""
echo "Or with specific command:"
echo "./bin/mgr-ssh.sh 'terraform version'" 