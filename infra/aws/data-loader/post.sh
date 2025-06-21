# Extract the private key for SSH access and set permissions
echo "Extracting loader.key from Terraform output..."
terraform output -raw private_key > ../../loader.key
chmod 600 ../../loader.key 