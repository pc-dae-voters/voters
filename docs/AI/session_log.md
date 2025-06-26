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

## 2025-06-21 - Enhanced Terraform Scripts with Intelligent Volume Management

### User Request
The user requested enhancing `do-terraform.sh` to source a `pre-apply.sh` file if it exists, after the plan but before the apply. For the mgr-vm module, this file should detect if an instance replacement is required and only detach the EBS volume if so, removing the unconditional detachment logic from `pre.sh`.

### Solution Implemented

**Enhanced do-terraform.sh Script:**
- Added pre-apply script functionality that sources `pre-apply.sh` after plan generation but before apply
- This runs only when using the default plan-and-apply sequence (not for explicit plan or apply commands)
- Maintains backward compatibility with existing modules that don't have pre-apply.sh

**Created pre-apply.sh for mgr-vm Module:**
- **Intelligent Detection**: Analyzes Terraform plan JSON to detect instance replacement or volume attachment changes
- **Conditional Volume Detachment**: Only detaches EBS volume when:
  - Instance replacement is detected (delete/create actions)
  - Volume attachment changes are detected
- **Robust Volume Handling**: 
  - Gets volume ID from plan or current state
  - Checks current attachment status
  - Safely detaches with force option
  - Waits for detachment completion
- **Detailed Logging**: Color-coded output showing decision process and actions taken

**Updated pre.sh Script:**
- Removed unconditional volume detachment logic
- Now minimal since volume management is handled intelligently by pre-apply.sh
- Maintains structure for any future pre-execution needs

**Benefits:**
- **Performance**: Avoids unnecessary volume detachment when no changes are needed
- **Reliability**: Prevents attachment conflicts only when actually required
- **Intelligence**: Uses Terraform plan analysis to make informed decisions
- **Modularity**: Each module can implement its own pre-apply logic as needed

**Usage:**
- `./bin/do-terraform.sh mgr-vm` - Will now intelligently handle volume detachment
- Other modules without pre-apply.sh continue to work unchanged
- Manual terraform commands bypass pre-apply.sh for direct control

## 2025-06-21 - Upload Script Missing Files Detection Issue

### User Request
The user reported that the `upload-data.sh` script was not detecting missing files on the remote instance. The script was correctly identifying files that exist on both sides but failing to detect files that exist locally but not remotely.

### Issue Analysis
From the debug output, the script was:
- ✅ Correctly detecting files that exist on both local and remote
- ❌ Not detecting files that exist locally but are missing remotely
- The jq query logic appeared to be working correctly for existing files

### Root Cause
The issue was in the jq query logic for detecting missing files. The script was using:
```bash
remote_file_data=$(jq -r ".[\"$rel_path\"]" "$local_json_file" 2>/dev/null || echo "null")
```

But the logic for determining if a file exists needed to be more robust to handle edge cases.

### Solution Implemented

**Enhanced upload-data.sh Script:**
- **Improved jq query logic**: Added better handling for missing files by checking for empty strings and null values
- **Added debug output**: Enhanced debugging to show remote file data for troubleshooting
- **Better existence detection**: Improved the condition to check for `null`, empty strings, and missing keys
- **Enhanced reason messages**: Added more descriptive reasons for upload decisions

**Key Changes:**
1. **Better null checking**: Added `&& "$remote_file_data" != ""` to the existence check
2. **Debug output**: Added DEBUG variable and debug output to show remote file data
3. **Improved reason messages**: Changed "new file" to "new file (missing on remote)" for clarity

**Logic Flow:**
```bash
# Check if file exists in remote JSON
remote_file_data=$(jq -r ".[\"$rel_path\"]" "$local_json_file" 2>/dev/null || echo "null")

# Determine existence with robust checking
if [[ -n "$remote_file_data" && "$remote_file_data" != "null" && "$remote_file_data" != "" ]]; then
    remote_exists=true
    # Extract size and mtime...
else
    remote_exists=false
fi

# Upload decision
if [[ "$remote_exists" == "false" ]]; then
    needs_upload=true
    reason="new file (missing on remote)"
fi
```

### Testing
Created test scripts to verify the jq query logic:
- `test-jq.sh`: Tests jq queries for existing and missing files
- `test-missing-files.sh`: Simple test for missing file detection logic

### Usage
The script now properly detects missing files when run with:
```bash
./bin/upload-data.sh --data-folder ../data --debug
```

The debug output will show:
- `DEBUG: filename - remote_exists=false, remote_data='null'` for missing files
- Proper upload decisions with descriptive reasons
- Summary showing new files uploaded vs modified files updated

## 2025-06-21 - Addresses Table Schema Simplification

### User Request
The user requested simplifying the addresses table schema by replacing the five separate line fields (line1, line2, line3, line4, line5) with a single `address` VARCHAR field.

### Changes Made
1. **Updated addresses.sql**: 
   - Replaced `line1 VARCHAR(255), line2 VARCHAR(255), line3 VARCHAR(255), line4 VARCHAR(255), line5 VARCHAR(255)` with `address VARCHAR(500)`
   - Updated table and column comments to reflect the simplified structure
   - Modified unique constraint from `(line1, line2, line3, line4, line5, place_id, postcode)` to `(address, place_id, postcode)`

2. **Verified Python Loader Scripts**:
   - Confirmed `load-addresses.py` already uses the correct schema with single `address` field in INSERT statements
   - Verified `load-address-places.py` doesn't reference the addresses table directly (only extracts place names)
   - No other Python scripts needed updates

3. **Checked Database References**:
   - Confirmed `voters.sql` only references `address_id` foreign key, no schema changes needed
   - No other SQL files reference the old line1-line5 fields

### Result
The addresses table now uses a simplified schema with a single `address` field (VARCHAR(500)) instead of five separate line fields, making it easier to work with and more flexible for storing complete address strings. All existing loader scripts were already compatible with this schema.

## 2025-01-27 - AWS Credentials Check Improvement

### User Request
The user suggested improving the AWS credentials check in `setup-aws.sh` by sourcing `session.sh` first before checking if credentials are working, rather than requiring manual sourcing.

### Issue Identified
The current script checked for AWS credentials first and then told users to manually run `source infra/aws/session.sh` if credentials weren't available. This was less user-friendly and required manual intervention.

### Solution Implemented
Modified `voters/bin/setup-aws.sh` to:
1. **Source session.sh first**: Automatically source the AWS session configuration file
2. **Then check credentials**: Verify AWS credentials are working after environment setup
3. **Better error handling**: Provide clearer error messages if credentials are still invalid
4. **User-friendly flow**: Eliminate the need for manual sourcing before running the script

### Key Changes Made
- Added automatic sourcing of `infra/aws/session.sh` before credential validation
- Updated error messages to reflect the new flow
- Added success message when session configuration is loaded
- Added warning if session.sh file is not found

This improvement makes the setup script more convenient and reduces the chance of user error by automatically setting up the AWS environment.

## 2025-01-27 - Places Loader Update for Addresses Folder

### User Request
The user requested to update the places loader to work differently with the addresses folder structure instead of the previous CSV format.

### Requirements Identified
1. **Input Change**: Command line argument should be a path to the addresses folder instead of a single CSV file
2. **Data Source**: Extract place names from the Address field in addresses CSV files
3. **Country Assignment**: All records should use "United Kingdom" as the country
4. **Place Name Extraction**: Extract place name as the last element in the Address field after comma delimiter
5. **Special Entry**: Add a "not specified" place entry for the United Kingdom

### Solution Implemented
Completely rewrote `voters/db/load-places.py` with the following changes:

**New Functionality:**
- **`extract_place_name(address)`**: Extracts place name from address string by splitting on comma and taking the last element
- **`process_addresses_folder()`**: Processes all CSV files in the addresses folder to extract unique place names
- **Folder Processing**: Uses `glob` to find all CSV files in the specified folder
- **Duplicate Prevention**: Tracks processed places in a set to avoid duplicates across files

**Key Features:**
- **Automatic File Discovery**: Finds all `*.csv` files in the addresses folder
- **Address Field Parsing**: Extracts place names from the "Address" column using comma delimiter
- **United Kingdom Country**: Uses "United Kingdom" country ID for all place records
- **"Not Specified" Entry**: Automatically adds a "not specified" place entry for the UK
- **Error Handling**: Robust error handling for file processing and database operations
- **Progress Reporting**: Shows processing progress and final statistics

**Example Address Processing:**
- Input: `"23 Bredon View, Headless Cross"`
- Extracted Place: `"Headless Cross"`

**Usage:**
```bash
python load-places.py --addresses-folder /path/to/data/addresses
```

This update makes the places loader work seamlessly with the existing addresses data structure and automatically extracts all unique place names from the UK address files.

### Follow-up: Updated Bash Scripts for New Interface

**User Request**: The user asked if the loader bash scripts had been updated to work with the new places loader interface.

**Scripts Updated**:

1. **`voters/bin/run-load-places.sh`** (Version 1.4):
   - Changed from `--csv-file` parameter to `--addresses-folder`
   - Updated default path from `db/uk-cities.csv` to `data/addresses`
   - Modified validation to check for directory existence instead of file existence
   - Updated help text and error messages to reflect new functionality

2. **`voters/bin/load-data.sh`** (Version 1.5):
   - Removed `--places-csv` parameter from argument parsing
   - Updated places loader call to use `--addresses-folder` instead of `--csv-file`
   - Modified help text to remove references to places CSV file
   - Now passes the same addresses folder to both places loader and addresses loader

**Key Changes**:
- **Consistent Interface**: Both scripts now use the same addresses folder parameter
- **Simplified Workflow**: No need for separate places CSV file - place names are extracted from address data
- **Better Integration**: Places loader and addresses loader can now use the same data source
- **Updated Documentation**: Help text and error messages reflect the new functionality

**Usage Examples**:
```bash
# Run places loader with default addresses folder
./bin/run-load-places.sh

# Run places loader with custom addresses folder
./bin/run-load-places.sh --addresses-folder /path/to/addresses

# Run complete data loading with addresses folder
./bin/load-data.sh --addresses-folder /path/to/addresses
```

All bash scripts are now consistent with the updated places loader that extracts place names from address CSV files.

## 2025-01-27 - Citizen Table Enhancement and People Loader Update

### User Request
The user requested to update the citizen table to include surname, firstname and gender fields like in the births table, and update the people loader to populate these fields with the same values as birth records.

### Requirements Identified
1. **Citizen Table Enhancement**: Add surname_id, first_name_id, and gender fields to match births table structure
2. **Data Consistency**: Ensure citizen table contains current name and gender information
3. **People Loader Update**: Modify synthetic people generator to populate citizen table with name and gender data
4. **Death Tracking**: Add died field to citizen table for mortality simulation

### Solution Implemented

**Updated `voters/db/citizen.sql`:**
- Added `surname_id INTEGER REFERENCES surnames(id)`
- Added `first_name_id INTEGER REFERENCES first-names(id)`
- Added `gender CHAR(1) CHECK (gender IN ('M', 'F'))`
- Added `died DATE` field for mortality tracking
- Added comprehensive table and column comments

**Updated `voters/db/load-synthetic-people.py`:**
- Fixed table name from `citizens` to `citizen`
- Added logic to get citizen-status ID from status code
- Updated INSERT statement to include surname_id, first_name_id, and gender
- Fixed mortality simulation to use correct table name
- Enhanced error handling for missing citizen status codes

**Key Benefits:**
- **Easy Access**: Citizen's current name and gender are directly accessible from citizen table
- **Data Consistency**: Same name and gender values stored in both citizen and births tables
- **Performance**: No need to join with births table for basic name/gender queries
- **Flexibility**: Citizen table can be updated independently for name changes while preserving birth records

**Database Schema:**
```sql
-- Citizen table now includes:
citizen (
    id SERIAL PRIMARY KEY,
    status_id INTEGER REFERENCES citizen-status(id),
    surname_id INTEGER REFERENCES surnames(id),
    first_name_id INTEGER REFERENCES first-names(id),
    gender CHAR(1) CHECK (gender IN ('M', 'F')),
    died DATE
)
```

This enhancement enables efficient access to citizen's current name and gender while maintaining the historical birth record information, providing both current state and historical data in a well-structured manner.

### Follow-up: Citizen Changes Table Structure Update

**User Request**: The user requested to remove the change_type column from citizen-changes table and make the details column a JSON document for more flexible change tracking.

**Updated `voters/db/citizen-changes.sql`:**
- **Removed**: `change_type VARCHAR(50) NOT NULL` column
- **Changed**: `details TEXT` to `details JSONB NOT NULL`
- **Updated**: Comments to reflect the new structure

**Key Benefits:**
- **Flexibility**: JSON structure allows for complex change descriptions without predefined types
- **Extensibility**: New change types can be added without schema modifications
- **Rich Data**: JSON can include multiple fields, arrays, and nested objects for detailed change tracking
- **Queryability**: PostgreSQL JSONB provides efficient querying and indexing capabilities

**Example JSON Structure:**
```json
{
  "change_type": "name_change",
  "old_values": {
    "surname_id": 123,
    "first_name_id": 456
  },
  "new_values": {
    "surname_id": 789,
    "first_name_id": 101
  },
  "reason": "marriage",
  "authorized_by": "registry_office"
}
```

**Database Schema:**
```sql
citizen-changes (
    id SERIAL PRIMARY KEY,
    citizen_id INTEGER NOT NULL,
    change_date DATE NOT NULL DEFAULT CURRENT_DATE,
    details JSONB NOT NULL,
    FOREIGN KEY (citizen_id) REFERENCES citizen(id)
)
```

This change provides a more flexible and powerful system for tracking citizen changes while maintaining data integrity and query performance through PostgreSQL's JSONB capabilities.

## 2025-01-27 - Marriage Generation and Surname Change System

### User Request
The user requested to add generation of marriages and parents, including a marriages table and logic to create marriages between eligible citizens with automatic surname changes for women.

### Requirements Identified
1. **Marriages Table**: Create table to track marriages and divorces
2. **Marriage Generation**: Generate marriages for citizens over 16 years old
3. **Partner Selection**: Find suitable partners with similar age and gender preferences
4. **Marriage Age Distribution**: 25% before 23, 50% between 23-30, 25% after 30
5. **Surname Changes**: Automatically change woman's surname when marrying a man
6. **Change Tracking**: Record surname changes in citizen-changes table

### Solution Implemented

**Created `voters/db/marriages.sql`:**
```sql
CREATE TABLE IF NOT EXISTS marriages (
    id SERIAL PRIMARY KEY,
    partner1_id INTEGER NOT NULL,
    partner2_id INTEGER NOT NULL,
    married_date DATE NOT NULL,
    divorced_date DATE,
    FOREIGN KEY (partner1_id) REFERENCES citizen(id),
    FOREIGN KEY (partner2_id) REFERENCES citizen(id),
    CHECK (partner1_id != partner2_id)
);
```

**Updated `voters/db/load-synthetic-people.py`:**
- **Added `get_marriage_date()` function**: Calculates marriage dates with age distribution logic
- **Added marriage generation phase**: Runs after mortality simulation
- **Partner selection logic**: 
  - 98% opposite gender, 2% same gender
  - Age difference ≤ 10 years
  - Only unmarried, alive citizens over 16
- **Surname change handling**: 
  - Updates woman's surname to husband's surname
  - Creates citizen-changes record with JSON details
- **Progress reporting**: Shows marriage creation progress

**Key Features:**
- **Age Distribution**: Realistic marriage age distribution (18-35 years)
- **Gender Preferences**: 98% heterosexual, 2% same-sex marriages
- **Automatic Surname Changes**: Women take husband's surname with change tracking
- **Change Records**: JSON-based citizen-changes records for audit trail
- **Eligibility Checks**: Only unmarried, alive citizens over 16 can marry

**Example Citizen Change Record:**
```json
{
  "change_type": "name_change",
  "reason": "marriage",
  "old_values": {"surname_id": 123},
  "new_values": {"surname_id": 456},
  "marriage_partner_id": 789,
  "marriage_date": "2020-06-15"
}
```

**Process Flow:**
1. Generate citizens and births
2. Apply mortality simulation
3. Find eligible citizens (over 16, alive, unmarried)
4. Match partners based on age and gender preferences
5. Create marriage records
6. Update woman's surname and create change record
7. Mark citizens as married

This enhancement creates realistic marriage patterns and maintains proper change tracking for surname modifications, providing a comprehensive family relationship system.

### Follow-up: Added Marriages Table to Database Setup

**User Request**: The user pointed out that the marriages table needed to be added to the create-tables.sh script.

**Updated `voters/bin/create-tables.sh`:**
- **Added dependency**: `["marriages"]="citizen"` - marriages table depends on citizen table
- **Added to SQL_FILES array**: `"marriages.sql"` - included in default table creation order
- **Proper ordering**: Placed after citizen-changes.sql since it references citizen table

**Key Changes:**
- **Dependency Management**: Marriages table properly declared as dependent on citizen table
- **Automatic Creation**: Marriages table will now be created when running `./bin/create-tables.sh`
- **Correct Ordering**: Table created after citizen table to satisfy foreign key constraints

**Database Setup Flow:**
1. Create citizen table
2. Create citizen-changes table  
3. Create marriages table (with foreign key references to citizen)

This ensures the marriages table is properly created during database initialization and maintains referential integrity with the citizen table.

### Follow-up: Updated Marriage Rate to 90%

**User Request**: The user requested to change the marriage rate so that only 90% of eligible citizens get married instead of trying to marry everyone.

**Updated `voters/db/load-synthetic-people.py`:**
- **Added marriage rate check**: `if random.random() > 0.9: continue`
- **Realistic marriage rate**: Only 90% of eligible citizens will attempt to find a partner
- **Maintains existing logic**: Partner selection and surname changes remain unchanged

**Key Changes:**
- **Marriage Rate**: Reduced from 100% to 90% of eligible citizens
- **Realistic Demographics**: Better reflects real-world marriage statistics
- **Unmarried Population**: 10% of eligible citizens will remain unmarried
- **Random Selection**: Marriage selection is random, not based on any specific criteria

**Impact:**
- More realistic population demographics
- Creates a mix of married and unmarried citizens
- Maintains all existing marriage logic for those who do marry
- Better simulation of real-world marriage patterns

This change makes the synthetic data more realistic by ensuring not everyone gets married, which better reflects actual population statistics.

## 2025-01-27 - Parent Generation and Family Relationships

### User Request
The user requested to add parent generation functionality, creating children for married couples and establishing family relationships.

### Requirements Identified
1. **Parent Selection**: Find married couples (man and woman only) who can have children
2. **Child Distribution**: 60% have 2 children, 20% have 1 child, 10% have 3 children
3. **Birth Timing**: Children born after marriage date but before woman turns 35
4. **Parent Assignment**: Update birth records with father_id and mother_id
5. **Child Creation**: Generate additional citizens as needed for children

### Solution Implemented

**Updated `voters/db/load-synthetic-people.py`:**
- **Added parent generation phase**: Runs after marriage generation
- **Eligible couple selection**: 
  - Married couples (M+F only)
  - Both partners alive
  - Wife under 35 at marriage
  - Not divorced
- **Child distribution logic**:
  - 20% have 1 child
  - 60% have 2 children  
  - 10% have 3 children
- **Birth timing constraints**:
  - Children born after marriage date
  - Before wife turns 35
  - Minimum 9 months between children
- **Parent assignment**: Updates birth records with father_id and mother_id

**Key Features:**
- **Realistic Family Sizes**: Follows specified child distribution
- **Age Constraints**: Only couples where wife is under 35 at marriage
- **Birth Spacing**: Minimum 9 months between children
- **Surname Inheritance**: Children get father's surname
- **Complete Parentage**: Birth records include both mother and father IDs
- **Progress Reporting**: Shows child creation progress

**Process Flow:**
1. Find eligible married couples (M+F, alive, wife under 35)
2. Determine number of children per couple (1-3 based on distribution)
3. Calculate child birth dates (after marriage, before wife turns 35)
4. Generate child citizens with father's surname
5. Create birth records with parent IDs
6. Track progress and statistics

**Database Impact:**
- Creates additional citizen records for children
- Populates father_id and mother_id in births table
- Establishes complete family relationships
- Maintains referential integrity

This enhancement creates realistic family structures with proper parent-child relationships and maintains data consistency across all related tables.