# AI Session Log

## 2024-12-19

### Request: Change lockdb and bucket names to prefix with "dae-"
**User Query:** "lets change the name of the lockdb and bucket to prefix with a dae-"

**Response:** Updated the terraform.tfvars file in `voters/infra/aws/tf-state/` to change:
- `lockdb_name` from "paulcarlton-voters-tfstate-lock" to "dae-voters-tfstate-lock"
- `bucket_name` from "paulcarlton-voters-tfstate" to "dae-voters-tfstate"

The names now use the "dae-" prefix as requested, which will affect the DynamoDB table for Terraform state locking and the S3 bucket for storing Terraform state files.

### Follow-up Request: Update backend.tf files to reflect new bucket name
**User Query:** "This change of bucket name needs to be reflected in the backend.tf files under infra/aws"

**Response:** Updated all three backend.tf files under infra/aws to use the new bucket name:
- `voters/infra/aws/vpc/backend.tf` - Changed bucket from "paulcarlton-voters-tfstate" to "dae-voters-tfstate"
- `voters/infra/aws/db/backend.tf` - Changed bucket from "paulcarlton-voters-tfstate" to "dae-voters-tfstate"
- `voters/infra/aws/eks/backend.tf` - Changed bucket from "paulcarlton-voters-tfstate" to "dae-voters-tfstate"

All backend.tf files now consistently use the new bucket name that matches the terraform.tfvars configuration.

### Request: Redesign database setup for VPC-only access
**User Query:** "I want to redesign the database setup in @infra/aws/db to make the database only accessible from within the vpc, i.e. accessible from the eks cluster we we create in a minute"

**Response:** Redesigned the database setup to be VPC-only accessible with the following changes:

**Database Configuration (`voters/infra/aws/db/main.tf`):**
- Updated backend bucket name to "dae-voters-tfstate"
- Removed public IP access rule (http data source and security group rule)
- Created new dedicated security group for database with VPC-only access
- Changed database to use private subnets instead of public subnets
- Set `publicly_accessible = false`

**RDS Module Updates (`voters/infra/aws/modules/rds/`):**
- Added `vpc_security_group_ids` variable to accept security group IDs
- Added `publicly_accessible` variable to control public access
- Updated RDS instance to use these new parameters

**VPC Module Updates (`voters/infra/aws/modules/vpc/`):**
- Added `vpc_cidr_block` output to expose VPC CIDR for security group rules

**Database Outputs (`voters/infra/aws/db/outputs.tf`):**
- Added `db_security_group_id` output for EKS integration
- Added `vpc_id` output for reference

**Security Group Configuration:**
- Created dedicated security group allowing PostgreSQL (port 5432) access from within VPC CIDR
- Configured egress rules to allow all outbound traffic
- Database is now only accessible from resources within the VPC (including future EKS cluster)

**Issue Resolution:**
- Fixed VPC CIDR block reference error by using hardcoded "10.0.0.0/16" instead of trying to get it from VPC outputs (which don't exist yet in the current VPC state)
- The VPC CIDR block will be properly referenced once the VPC is redeployed with the new output

### Request: Create EC2 instance for database creation and loading
**User Query:** "Now the database is not publicly accessible I need to update the database creation and loading strategy, I can't run the bash scripts in bin directory from this machine anymore. I was thinking we should add the terraform code to create an AWS linux EC2 instance with a disk big enough for 20gb of data and configure ssh access to the ip of this machine only, the cloud init script for this instance should install the software we need to run the database creation and loader scripts then execute them"

**Response:** Created a complete EC2-based data loader solution with the following components:

**Data Loader Infrastructure (`voters/infra/aws/mgr-vm/`):**
- **main.tf**: EC2 instance configuration with security group, IAM role, and cloud-init setup
- **variables.tf**: Configurable variables for region, AMI, instance type, volume size, and project URL
- **backend.tf**: Terraform state configuration using the new "dae-voters-tfstate" bucket
- **outputs.tf**: Instance details, SSH command, and database connection info
- **cloud-init.sh**: Automated setup script that installs all required software

**EC2 Instance Configuration:**
- **Instance Type**: t3.medium (2 vCPU, 4GB RAM)
- **Storage**: 50GB GP3 root volume (expandable for 20GB+ data)
- **AMI**: Amazon Linux 2023 (latest)
- **Network**: Public subnet with SSH access from user's IP only
- **Security**: Dedicated security group with restricted SSH access

**Software Installation (via cloud-init):**
- **Database**: PostgreSQL 15 client tools
- **Java**: Amazon Corretto 21 (for Maven builds)
- **Python**: Python 3 with psycopg2-binary
- **Development**: Git, Maven, curl, jq, unzip, wget
- **Environment**: Python virtual environment with required dependencies

**Automated Setup Process:**
1. System updates and package installation
2. Database environment file creation with connection details
3. Project cloning from GitHub
4. Python virtual environment setup
5. Database table creation (via create-tables.sh)
6. Ready-to-use data loading scripts

**Security Features:**
- SSH access restricted to user's current IP address only
- Instance runs in VPC with access to private database
- IAM role for future AWS service integration
- All database credentials handled securely via Terraform outputs

**Usage:**
- After deployment, SSH to instance using provided command
- Database tables are automatically created during setup
- Run `/home/ec2-user/load-data.sh` to load data into database
- Instance can be terminated after data loading is complete

### User: I'm not seeing how these variables get set, where are you getting ${db_... } values from?

**Assistant**: Explained how the `${db_...}` variables are set through Terraform's `templatefile` function:

1. **Terraform Remote State Data Sources**: The `mgr-vm` module reads database configuration from the `db` module's remote state
2. **Templatefile Function**: The `templatefile` function passes database values as variables to the cloud-init script
3. **Variable Substitution**: The function replaces `${db_host}`, `${db_name}`, `${db_username}`, and `${db_password}` with actual values from database module outputs

The flow is: Database module creates RDS instance and outputs connection details → Data loader module reads outputs via remote state → Terraform's `templatefile` function injects values into cloud-init script → Cloud-init script receives actual database connection parameters.

### User: got it

**Assistant**: Confirmed understanding and offered to help with any other infrastructure or database setup tasks.

### User: I've destroying infra/aws/mgr-vm and recreated it

**Assistant**: Helped troubleshoot SSH connection issues with the newly recreated mgr-vm instance. The user was getting "Permission denied (publickey)" errors when trying to SSH into the new instance at 34.242.221.12. 

Investigated the key pair mismatch issue by:
- Checking the private key format and permissions
- Extracting fresh private key from Terraform output
- Comparing public keys generated from private key vs registered with AWS
- Running SSH with verbose debugging to identify authentication failures

The issue was that the private key didn't match the public key registered with AWS, causing authentication failures.

### User: lets add the option to ignore the key issue

**Assistant**: Explained that the SSH options to ignore host key verification are:
- `-o StrictHostKeyChecking=no` - Ignore host key checking
- `-o UserKnownHostsFile=/dev/null` - Don't save host key

Provided the full SSH command: `ssh -i loader.key -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@34.242.221.12`

Clarified that the current issue is key authentication failure, not host key verification, and offered to help troubleshoot the key pair mismatch or create scripts with these SSH options.

### User: The credentials expired again

**Assistant**: Checked the current credentials file and asked for new AWS credentials to update the file.

### User: I have updated voters/infra/aws/creds.sh

**Assistant**: Verified the updated credentials are working by running `aws sts get-caller-identity`. Confirmed authentication as `paul.carlton@dae.mn` with AWS account `499395681035`. 

Offered to help with next steps including SSH access to the mgr-vm instance or running Terraform operations.

### User: How do I tell how long these credentials are good for

**Assistant**: Explained several ways to check AWS credential expiration:
- For session credentials: Try API calls, check SSO portal, decode JWT tokens
- For long-term credentials: Check IAM console, use `aws iam get-access-key-last-used`
- Quick test: Run any AWS command and look for "ExpiredTokenException"

Noted that SSO session credentials typically last 1 hour (default) to 12 hours (configurable).

### User: export AWS_PROFILE=daemon_IsbUsersPS-499395681035 to get longer life creds, lets add this to creds.sh

**Assistant**: Added `export AWS_PROFILE=daemon_IsbUsersPS-499395681035` to the beginning of `creds.sh` to use longer-lived credentials from the AWS profile. 

Tested the updated credentials file and confirmed it works correctly. This setup provides longer credential validity and more flexibility for ongoing work. 

### User: is still broken

**Assistant**: Helped troubleshoot the persistent SSH connection issue by:
- Destroying and recreating the mgr-vm infrastructure with fresh key pair
- Identifying key pair mismatch between private key and AWS-registered public key
- Creating a manual key pair using `ssh-keygen` and importing it to AWS
- Updating Terraform configuration to use the manual key pair via data source
- Recreating the EC2 instance with the correct key pair association

The issue was resolved by using a manually created key pair instead of the Terraform-generated one.

### User: That worked

**Assistant**: Confirmed successful SSH connection to the mgr-vm instance at 18.203.238.51. The key pair mismatch issue was resolved by using a manual key pair and updating the Terraform configuration accordingly.

Provided the working SSH command with ignore options for host key verification.

## 2025-06-21 - Data Loader Cloud-init and EBS Volume Issues

### User Request
The user reported that after running the data-volume and data-loader Terraform modules, the cloud-init script didn't run properly and the EBS volume wasn't mounted.

### Issues Identified
1. **EBS Volume Mounting**: The cloud-init script was trying to mount `/dev/xvdf` but the actual device was `/dev/nvme1n1` due to AWS NVMe naming conventions
2. **Timing Issue**: Cloud-init runs during instance boot, but EBS volume attachment happens after instance creation
3. **Database Connection**: Environment file was created in wrong location (`infra/aws/db/` instead of `infra/db/`)
4. **Port Configuration**: Database host included port in PGHOST variable, causing conflicts with PGPORT

### Solutions Implemented
1. **Updated cloud-init script** to handle both xvdf and nvme device naming conventions
2. **Added systemd service** (`voters-setup.service`) that runs after cloud-init to handle delayed EBS volume attachment
3. **Fixed database environment file path** to match what the create-tables.sh script expects
4. **Fixed database connection configuration** by removing PGPORT when PGHOST already includes port

### Key Changes Made
- Modified `cloud-init.sh` to not fail if EBS volume isn't available during boot
- Created systemd service that waits up to 5 minutes for EBS volume and then mounts it
- Fixed database environment file location from `infra/aws/db/db-env.sh` to `infra/db/db-env.sh`
- Fixed PGPORT configuration to avoid conflicts with port in PGHOST

### Result
The data loader instance now:
- ✅ Automatically mounts the EBS volume at `/data` when it becomes available
- ✅ Installs all required software packages
- ✅ Clones the repository and sets up Python environment
- ✅ Creates database environment file in correct location
- ✅ Successfully connects to the database and creates tables
- ✅ Provides scripts for data loading (`/home/ec2-user/load-data.sh`)

### Commands Used
```bash
# Recreated instance with fixed cloud-init script
terraform destroy -auto-approve && terraform apply -auto-approve

# Verified EBS volume mounting
ssh -i loader.key ec2-user@<instance-ip> "lsblk && df -h"

# Tested database connection
ssh -i loader.key ec2-user@<instance-ip> "cd /home/ec2-user/pc-dae-voters && source infra/db/db-env.sh && psql -c '\dt'"
```

### Current Status
The data loader instance is fully functional and ready for data loading operations. The cloud-init script now properly handles the timing issues with EBS volume attachment and creates all necessary components automatically. 

## Session Entry - 2024-12-19

### User Request
User encountered SCP permission denied errors when trying to upload data files to the EC2 instance:
```
scp -r -i loader.key ../data/* ec2-user@52.30.252.221:/data
scp: dest open "/data/2024-results-by-constituency.csv": Permission denied
scp: failed to upload file ../data/2024-results-by-constituency.csv to /data
```

### Issue Analysis
The cloud-init script was creating the `/data` directory and mounting the EBS volume, but not setting proper ownership and permissions for the `ec2-user` to write to it. The directory was owned by root, preventing SCP operations.

### Solution Applied
Updated the `voters/infra/aws/mgr-vm/cloud-init.sh` script to add proper ownership and permissions after mounting the EBS volume:

```bash
# Set proper ownership and permissions for ec2-user
echo "Setting ownership and permissions on $MOUNTPOINT..."
chown ec2-user:ec2-user $MOUNTPOINT
chmod 755 $MOUNTPOINT
```

This change was applied to both:
1. The main `mount_ebs_volume()` function in the cloud-init script
2. The `mount_ebs_volume()` function in the delayed setup script (`/usr/local/bin/voters-setup-delayed.sh`)

### Files Modified
- `voters/infra/aws/mgr-vm/cloud-init.sh` - Added ownership and permission settings for `/data` directory

### Next Steps
The user will need to redeploy the EC2 instance with the updated cloud-init script to apply these permission changes, or manually fix the permissions on the existing instance by running:
```bash
sudo chown ec2-user:ec2-user /data
sudo chmod 755 /data
```

## Session Entry - 2024-12-19 (Part 2)

### User Request
User requested to:
1. Create a Terraform configuration for an admin role with Administrator privileges
2. Assign this role to the data-loader instance
3. Rename the instance from "data-loader" to "manager" as it will be used for more than just data loading

### Solution Applied
Completely updated the Terraform configuration to:

1. **Renamed all resources** from "data-loader" to "manager":
   - `aws_instance.data_loader` → `aws_instance.manager`
   - `aws_security_group.data_loader` → `aws_security_group.manager`
   - `aws_iam_role.data_loader_role` → `aws_iam_role.manager_admin_role`
   - `aws_iam_instance_profile.data_loader_profile` → `aws_iam_instance_profile.manager_profile`
   - All resource names, tags, and descriptions updated

2. **Created Admin Role with Administrator privileges**:
   - Added `aws_iam_role.manager_admin_role` with EC2 assume role policy
   - Added `aws_iam_role_policy_attachment.manager_admin_policy` attaching `AdministratorAccess` policy
   - Updated instance profile to use the admin role
   - Added `iam_instance_profile` attribute to the EC2 instance

3. **Updated outputs**:
   - Added `admin_role_arn` and `admin_role_name` outputs
   - Updated all existing outputs to reflect manager naming

4. **Updated cloud-init script**:
   - Updated comments and service names to reflect manager naming
   - Changed systemd service from `voters-setup.service` to `voters-manager.service`

### Files Modified
- `voters/infra/aws/mgr-vm/main.tf` - Complete rename and admin role creation
- `voters/infra/aws/mgr-vm/outputs.tf` - Updated outputs and added admin role outputs
- `voters/infra/aws/mgr-vm/cloud-init.sh` - Updated naming in comments and systemd service

### Security Note
The manager instance now has full Administrator privileges via the attached IAM role. This provides maximum flexibility for management tasks but should be used carefully and only when necessary.

### Next Steps
Run `terraform apply` to create the new manager instance with admin privileges. The old data-loader instance will be destroyed and replaced with the new manager instance. 

## Session Entry - 2024-12-19 (Part 3)

### User Request
User requested to rename the infrastructure directory from `infra/aws/data-loader` to `infra/aws/mgr-vm` to better reflect its new purpose as a manager VM.

### Solution Applied
1. **Renamed directory**: Moved `voters/infra/aws/data-loader/` to `voters/infra/aws/mgr-vm/`
2. **Updated backend configuration**: Changed the Terraform state key from `data-loader/terraform.tfstate` to `mgr-vm/terraform.tfstate` in `backend.tf`
3. **Updated documentation**: Updated all references in the session log to reflect the new directory path

### Files Modified
- Directory renamed: `voters/infra/aws/data-loader/` → `voters/infra/aws/mgr-vm/`
- `voters/infra/aws/mgr-vm/backend.tf` - Updated state key
- `voters/docs/AI/session_log.md` - Updated all path references

### Next Steps
The infrastructure is now properly organized under the `mgr-vm` directory name. All Terraform operations should now be run from the `voters/infra/aws/mgr-vm/` directory. 

## Session Entry - 2024-12-19 (Part 4)

### User Request
User requested to make the output of the `db-query.sh` script more readable, as the current tab-separated format was hard to read.

### Issue Analysis
The original `db-query.sh` script used `psql -t -A` flags which produce tab-separated output that's difficult to read, especially for table layouts.

### Solution Applied
Created an improved version of the `db-query.sh` script with the following changes:

1. **Better table layout formatting**: Changed from `psql -t -A -c "\d \"$TABLE\""` to `psql -c "\d \"$TABLE\""` for expanded, readable output
2. **Improved row display**: Changed from tab-separated to expanded format when showing table rows
3. **Maintained count functionality**: Kept the simple count output as it was already readable

### Files Modified
- `voters/infra/aws/mgr-vm/improved-db-query.sh` - Created improved version
- Updated the script on the instance: `~/pc-dae-voters/bin/db-query.sh`

### Results
The table layout output now shows:
- Proper column formatting with headers
- Data types, constraints, and defaults clearly displayed
- Indexes and foreign key relationships
- Much more readable format compared to the previous tab-separated output

### Example Output
Before: `id|integer||not null|nextval('citizen_id_seq'::regclass)`
After: 
```
                              Table "public.citizen"
  Column   |  Type   | Collation | Nullable |               Default               
-----------+---------+-----------+----------+-------------------------------------
 id        | integer |           | not null | nextval('citizen_id_seq'::regclass)
 status_id | integer |           |          | 
```

### Next Steps
The improved script is now active on the instance and provides much better readability for database queries. 