# Voters Manager VM

This Terraform configuration creates an EC2 instance for managing the voters database project.

## Features

- **SSH Access Control**: Automatically allows SSH access from your current IP address
- **Additional CIDR Support**: Configure additional CIDR blocks for SSH access
- **Admin IAM Role**: Instance has Administrator privileges for AWS operations
- **Data Volume**: Attaches a persistent EBS volume for data storage
- **Cloud-init**: Automated setup with database connection and project cloning

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

## Usage

1. **Deploy the infrastructure**:
   ```bash
   cd voters/infra/aws/mgr-vm
   ./do-terraform.sh
   ```

2. **SSH to the instance**:
   ```bash
   ./mgr-ssh.sh
   ```

3. **Upload data**:
   ```bash
   ./upload-data.sh --data-folder ../../data
   ```

## Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | AWS region | `eu-west-1` |
| `instance_type` | EC2 instance type | `t3.medium` |
| `root_volume_size` | Root volume size in GB | `50` |
| `additional_ssh_cidrs` | Additional CIDR blocks for SSH access | `[]` |
| `project_git_url` | Git URL for the voters project | `https://github.com/pc-dae-voters.git` |

## Security

- SSH access is restricted to your current IP and any additional CIDRs you specify
- The instance has Administrator privileges for AWS operations
- All outbound traffic is allowed
- No inbound traffic except SSH (port 22) 