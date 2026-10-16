> **Confidentiality:** Internal
> **Document Status:** DRAFT - REVIEWED BY AI

# Voters Manager VM

This Terraform configuration creates an EC2 instance for loading the voters database. It is applied by tofu-controller on the EKS cluster, using the `voters-mgr-vm` Terraform object in `infra/aws/flux`, after the VPC, database and data volume.

## Features

- **SSH Access Control**: SSH is allowed from the comma separated CIDR blocks in `ssh_cidrs`, from the EKS cluster's `tf-config` ConfigMap, by default the public IP address of the machine that set up the EKS cluster
- **Data Volume**: Attaches the persistent EBS volume from the `data-volume` module, mounted at `/data`
- **Cloud-init**: Installs the tools, clones this repository's `project_git_branch`, the branch Flux deploys, to `/home/ec2-user/pc-dae-voters` and writes the database connection details to `infra/db/db-env.sh`
- **Database setup**: The `voters-manager` service mounts the data volume and creates the database tables when the instance starts

The instance's public IP address, SSH private key and instance ID are written to the `voters-mgr-vm-outputs` secret in `flux-system` on the EKS cluster. `bin/setup-aws.sh` writes them to `instance-ip.txt` and `loader.key` in this folder, which `bin/mgr-ssh.sh` and `bin/upload-data.sh` use. They are not committed.

## Cloud-init Version Control

Changing `cloud_init_version` changes the instance's user data, so the instance is replaced and cloud-init runs again. The data volume is kept, it is attached to the new instance. To set it, add a `cloud_init_version` entry to the Terraform object's `vars`.

## Variables

| Variable | Description | Default |
| --- | --- | --- |
| `region` | AWS region, from `tf-config` | |
| `tf_state_bucket` | State bucket, used to read the other modules' outputs, from `tf-config` | |
| `ssh_cidrs` | Comma separated CIDR blocks allowed SSH access, from `tf-config` | |
| `owner_email` | Email address added to the resources' tags, from `tf-config` | `""` |
| `instance_type` | EC2 instance type | `t3.medium` |
| `root_volume_size` | Root volume size in GB | `50` |
| `project_git_url` | Git URL of the voters project | `https://github.com/pc-dae-voters/voters.git` |
| `project_git_branch` | Branch to clone, set by the Terraform object | `main` |
| `cloud_init_version` | Increment to replace the instance and rerun cloud-init | `1.0` |
