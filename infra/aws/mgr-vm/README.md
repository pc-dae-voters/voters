# Voters Manager VM

This Terraform configuration creates an EC2 instance for managing the voters database project.

## Features

- **SSH Access Control**: Automatically allows SSH access from your current IP address
- **Additional CIDR Support**: Configure additional CIDR blocks for SSH access
- **Admin IAM Role**: Instance has Administrator privileges for AWS operations
- **Data Volume**: Attaches a persistent EBS volume for data storage
- **Cloud-init**: Automated setup with database connection and project cloning
- **Smart Cloud-init Versioning**: Control when cloud-init runs using version variables

## SSH Access Configuration

The security group automatically allows SSH access from:
1. **Your current IP address** (detected automatically)
2. **Additional CIDR blocks** (configurable via `additional_ssh_cidrs` variable)

### Configuring Additional SSH Access

To allow SSH access from additional networks, create a `terraform.tfvars` file:

```hcl
# Allow access from office network and VPN
additional_ssh_cidrs = [
  "192.168.1.0/24",    # Office network
  "10.0.0.0/8",        # VPN network
  "203.0.113.0/24"     # Specific network
]

# Or leave empty for current IP only
additional_ssh_cidrs = []
```

## Cloud-init Version Control

The cloud-init script uses version-based triggering instead of timestamps to prevent unnecessary instance replacements. The system automatically:

1. **Detects current version** from Terraform state
2. **Sets TF_VAR_CLOUD_INIT_VERSION** to the current version
3. **Only replaces instance** when version changes

### Forcing Cloud-init to Run

To force cloud-init to run again (e.g., after updating the cloud-init script):

```bash
# Set a new version
export TF_VAR_CLOUD_INIT_VERSION="1.1"

# Run Terraform
./bin/do-terraform.sh mgr-vm
```

### Automatic Version Management

The `post-init.sh` script automatically:
- Reads the current cloud-init version from Terraform state
- Sets `TF_VAR_CLOUD_INIT_VERSION` to maintain the current version
- Only changes version when explicitly set by the user

## Usage

1. **Deploy the infrastructure**:
   ```bash
   cd voters/infra/aws/mgr-vm
   ./bin/do-terraform.sh mgr-vm
   ```

2. **SSH to the instance**:
   ```bash
   ./bin/mgr-ssh.sh
   ```

3. **Upload data**:
   ```bash
   ./bin/upload-data.sh --data-folder ../../data
   ```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | AWS region | `eu-west-1` |
| `instance_type` | EC2 instance type | `t3.medium` |
| `root_volume_size` | Root volume size in GB | `50` |
| `additional_ssh_cidrs` | Additional CIDR blocks for SSH access | `[]` |
| `project_git_url` | Git URL for the voters project | `https://github.com/pc-dae-voters.git` |
| `cloud_init_version` | Version number for cloud-init configuration | `1.0` |

## Security

- SSH access is restricted to your current IP and any additional CIDRs you specify
- The instance has Administrator privileges for AWS operations
- All outbound traffic is allowed
- No inbound traffic except SSH (port 22) 