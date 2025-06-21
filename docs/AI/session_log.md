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

**Data Loader Infrastructure (`voters/infra/aws/data-loader/`):**
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