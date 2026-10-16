> **Confidentiality:** Internal
> **Document Status:** DRAFT - REVIEWED BY AI

# Voters

Infrastructure + data pipeline for a **synthetic voter register** dataset, plus an optional **Spring Boot REST API** (`voters-api/`) to query and update it.

This repo is designed to be used in two modes:

- **Cloud “manager VM” mode (recommended for realistic scale)**: tofu-controller, running on an EKS cluster, provisions a database and a “manager” machine; you upload a `/data` bundle; the manager runs the loaders to create schema + populate Postgres.
- **Local dev mode (fast iteration)**: run Postgres locally (Docker Compose is included under `voters-api/`), then run the same schema + loader scripts against localhost.

## What it does

- **Creates a Postgres schema** for voter/citizen entities (tables live in `db/*.sql`).
- **Loads reference data** (constituencies, postcodes, names, places, addresses) from CSVs.
- **Generates synthetic people** (births, marriages, divorces, etc.) and **registers voters**.
- Optionally runs a **REST API** for querying/updating the dataset (`voters-api/`).

## Repository layout

- `bin/`
  - `setup-aws.sh`: waits for the AWS infrastructure, uploads the data and loads it
  - `teardown-aws.sh`: destroys the AWS infrastructure
  - `create-tables.sh`: creates tables from `db/*.sql`
  - `load-data.sh`: orchestrates the Python loader pipeline
  - `upload-data.sh`, `mgr-ssh.sh`: utilities for manager VM workflows (AWS)
  - `db-query.sh`: helper to inspect tables/counts/rows (expects a db env file)
- `infra/aws/`
  - `vpc`, `peering`, `db`, `data-volume`, `mgr-vm`: Terraform root modules for the VPC, its peering with the EKS cluster's VPC, the RDS database, the data EBS volume and the manager VM
  - `modules/`: the `vpc` and `rds` modules they use
  - `flux/`: the tofu-controller `Terraform` objects that apply them, deployed to the EKS cluster by Flux
- `db/`
  - `*.sql`: schema (tables include `"con-postcodes"` and `"citizen-changes"` etc.)
  - `load-*.py`: Python loaders/generators used by `bin/load-data.sh`
  - `requirements.txt`: Python deps for loaders
- `voters-api/`
  - Spring Boot REST API (see `voters-api/README.md`)

## Data inputs

The loader pipeline expects a data bundle mounted/available at **`/data`** (this is how the manager VM is set up):

- `/data/parl_constituencies_2025.csv`
- `/data/postcodes_with_con.csv`
- `/data/addresses/` (folder of address CSVs)
- `/data/names/data/` (folder of name CSVs)

The default orchestration script `bin/load-data.sh` uses these paths directly.

## Quick start (local dev)

### 1) Start Postgres locally

There’s a ready-to-use Docker Compose file in `voters-api/`.

From `voters/voters-api/`:

```bash
docker-compose up -d
```

This brings up Postgres with the defaults used by the scripts when no env file is present:

- host `localhost`, port `5432`
- db `voters`, user `postgres`, password `password`

### 2) Create tables

From `voters/`:

```bash
./bin/create-tables.sh --delete
```

### 3) Load data

Make sure your data bundle is available at `/data` on your machine (or edit `bin/load-data.sh` to point at your data folder).

From `voters/`:

```bash
./bin/load-data.sh
```

### 4) Run the API (optional)

From `voters/`:

```bash
./bin/build-run.sh
```

Or see `voters-api/README.md` for `mvn spring-boot:run`, Swagger/OpenAPI, etc.

## Quick start (AWS)

The AWS infrastructure is created by [tofu-controller](https://github.com/flux-iac/tofu-controller) running on an EKS cluster, created and set up by the [mac-k8s](https://github.com/pc-dae-gitops/mac-k8s) scripts using the [aws-eks-voters](https://github.com/pc-dae-gitops/aws-eks-voters) cluster repository. Its `target-cluster/flux/voters-infra.yaml` deploys the `Terraform` objects in `infra/aws/flux` from this repository:

| Terraform | Module | Creates | Depends on |
| --- | --- | --- | --- |
| `voters-vpc` | `infra/aws/vpc` | VPC, `10.1.0.0/16`, with public and private subnets in two availability zones, no NAT gateway | |
| `voters-peering` | `infra/aws/peering` | Peering with the EKS cluster's VPC, routes both ways and DNS resolution of private names | `voters-vpc` |
| `voters-db` | `infra/aws/db` | RDS PostgreSQL 15 in the private subnets, reachable from the voters and EKS VPCs | `voters-vpc` |
| `voters-data-volume` | `infra/aws/data-volume` | EBS volume for the data, in the manager VM's availability zone | `voters-vpc` |
| `voters-mgr-vm` | `infra/aws/mgr-vm` | Manager VM in a public subnet, with the data volume at `/data`, SSH from the EKS cluster's `ssh_cidrs` | `voters-vpc`, `voters-db`, `voters-data-volume` |

The settings, i.e. region, state bucket and lock table, EKS cluster name and the CIDR blocks allowed to SSH to the manager VM, are in the EKS cluster's `tf-config` ConfigMap, the state is kept under `voters-infra/` in the EKS cluster's state bucket. The runner pods use the EKS cluster's `tf-runner` IAM role, using EKS Pod Identity, so no AWS credentials are needed. The database's connection details are written to the `voters-db-outputs` secret in `flux-system`, and the manager VM's public IP address and SSH key to `voters-mgr-vm-outputs`.

The modules use a partial S3 backend, which the `Terraform` objects configure. To run them locally, pass the backend settings to `tofu init` or `terraform init`, e.g. `-backend-config=bucket=<bucket> -backend-config=key=voters-infra/vpc/terraform.tfstate -backend-config=region=eu-west-1`, and the variables in `tf-config`.

### 1) Wait for the infrastructure, upload and load the data

Use a shell with `kubectl` pointing at the EKS cluster, e.g. in the cluster repository's `target-cluster` folder, or `export KUBECONFIG=~/.kube/eks-voters.yaml`. From `voters/`:

```bash
./bin/setup-aws.sh
```

It waits for the `Terraform` objects to be ready, writes the manager VM's IP address and SSH key to `infra/aws/mgr-vm/instance-ip.txt` and `infra/aws/mgr-vm/loader.key`, waits for cloud-init to set up the VM, uploads `../data` to `/data` using `bin/upload-data.sh`, then runs `create-tables.sh --delete` and `load-data.sh` on the VM. You can skip parts:

```bash
./bin/setup-aws.sh --skip-data-upload --skip-data-load
```

To see progress, see [Viewing Terraform plans and output](#viewing-terraform-plans-and-output):

```bash
kubectl get terraform -n flux-system
```

#### Viewing Terraform plans and output

Set `tf` to the `Terraform` object's name, e.g. `voters-vpc`, `voters-peering`, `voters-db`, `voters-data-volume` or `voters-mgr-vm`:

```bash
tf=voters-db
```

Status, the last applied and planned revisions and any error:

```bash
kubectl get terraform -n flux-system ${tf}
kubectl get terraform -n flux-system ${tf} -o jsonpath='{range .status.conditions[*]}{.type}{": "}{.reason}{" - "}{.message}{"\n"}{end}'
kubectl describe terraform -n flux-system ${tf}
kubectl get events -n flux-system --field-selector involvedObject.name=${tf} --sort-by=.lastTimestamp
```

The latest plan. The `Terraform` objects have `storeReadablePlan: human`, so tofu-controller writes it to the `tfplan-default-<name>` ConfigMap, each plan replaces the previous one. The runner pod's logs don't have the plan:

```bash
kubectl get configmap -n flux-system tfplan-default-${tf} -o jsonpath='{.data.tfplan}'
```

The apply output, in the runner pod's logs. The runner pod is deleted once it has finished, so this only works while it is running:

```bash
kubectl logs -n flux-system ${tf}-tf-runner -f
```

Earlier runs' output is kept by Loki, query it in Grafana's Explore page, `https://grafana.<local_dns>`, using the Loki data source, e.g. for `voters-db`:

```
{k8s_namespace_name="flux-system", k8s_pod_name="voters-db-tf-runner"}
```

Use `{service_name="tf-runner"}` for all the runner pods, and add `!= "\"logger\":"` for only the Terraform output, without the runner's own log lines.

The outputs, for objects with `writeOutputsToSecret`, i.e. `voters-db` and `voters-mgr-vm`. The values are secret, so this only lists their names:

```bash
kubectl get secret -n flux-system ${tf}-outputs -o json | jq -r '.data | keys[]'
```

To plan and apply now, rather than at the object's interval:

```bash
kubectl annotate terraform -n flux-system ${tf} --overwrite reconcile.fluxcd.io/requestedAt="$(date +%s)"
```

### 2) Query the database from the EKS cluster

The `debug` folder deploys a debug pod with `psql` and the database's connection details. The cluster repository's `target-cluster/apps/inputs/apps.yaml` deploys it as the `voters-debug` app in the `voters` namespace. Its `voters-db` ExternalSecret reads the details from Vault at `apps/voters-debug/voters-db`, which `bin/db-vault-secret.sh` writes from the `voters-db-outputs` secret. `setup-aws.sh` runs it if `VAULT_ADDR` and `VAULT_TOKEN` are set, e.g. in a shell in the cluster repository's `target-cluster` folder, otherwise run it there:

```bash
./bin/db-vault-secret.sh
```

The details are mounted at `/etc/voters-db`, a file per `PG*` variable and `db-env.sh`, which exports them, so `psql` connects without any arguments. The database is reachable from the EKS cluster through the VPC peering.

#### Interactive session

Use a shell with `kubectl` pointing at the EKS cluster, e.g. in the cluster repository's `target-cluster` folder:

```bash
kubectl exec -it -n voters deploy/voters-debug -- bash
source /etc/voters-db/db-env.sh
psql
```

Useful `psql` commands:

| Command | Does |
| --- | --- |
| `\dt` | List the tables |
| `\d citizen` | Describe a table's columns, indexes and foreign keys |
| `\x auto` | Show wide rows one column per line |
| `\timing` | Show how long each query takes |
| `\i /tmp/queries.sql` | Run the queries in a file, `/tmp` is the only writable folder |
| `\q` | Quit |

Table names with hyphens must be double quoted, e.g. `"con-postcodes"`. Postcodes are stored without spaces, e.g. `SW1A2AA`, and a birth's date is in `births.date`.

#### Single queries from your machine

```bash
kubectl exec -n voters deploy/voters-debug -- bash -c \
  'source /etc/voters-db/db-env.sh && psql -c "SELECT count(*) FROM voters"'
```

To run a file of queries, copy it to the pod first:

```bash
pod=$(kubectl get pod -n voters -l app=voters-debug -o jsonpath='{.items[0].metadata.name}')
kubectl cp queries.sql voters/${pod}:/tmp/queries.sql
kubectl exec -n voters deploy/voters-debug -- bash -c 'source /etc/voters-db/db-env.sh && psql -f /tmp/queries.sql'
```

#### Sample queries

The tables and their row counts:

```sql
SELECT relname AS table, n_live_tup AS rows FROM pg_stat_user_tables ORDER BY relname;
```

Constituencies per nation:

```sql
SELECT nation, count(*) AS constituencies
FROM constituencies
GROUP BY nation
ORDER BY constituencies DESC;
```

The constituency of a postcode:

```sql
SELECT p.postcode, c.name AS constituency, c.region
FROM "con-postcodes" p
JOIN constituencies c ON c.code = p.con_code
WHERE p.postcode = 'SW1A2AA';
```

A sample of voters with their names, gender and address:

```sql
SELECT v.id AS voter, f.name AS first_name, s.name AS surname, c.gender,
       a.address, pl.name AS place, a.postcode, v.registration_date
FROM voters v
JOIN citizen c ON c.id = v.citizen_id
JOIN first_names f ON f.id = c.first_name_id
JOIN surnames s ON s.id = c.surname_id
JOIN addresses a ON a.id = v.address_id
LEFT JOIN places pl ON pl.id = a.place_id
ORDER BY v.id
LIMIT 10;
```

Voters per constituency. Addresses don't have a constituency, it is found from their postcode:

```sql
SELECT con.name AS constituency, count(*) AS voters
FROM voters v
JOIN addresses a ON a.id = v.address_id
JOIN "con-postcodes" p ON p.postcode = a.postcode
JOIN constituencies con ON con.code = p.con_code
GROUP BY con.name
ORDER BY voters DESC
LIMIT 10;
```

People by citizenship status and gender:

```sql
SELECT cs.description AS status, c.gender, count(*) AS people
FROM citizen c
JOIN citizen_status cs ON cs.id = c.status_id
GROUP BY cs.description, c.gender
ORDER BY cs.description, c.gender;
```

Age distribution of living people, in ten year bands:

```sql
SELECT (date_part('year', age(b.date)) / 10)::int * 10 AS age_band, count(*) AS people
FROM citizen c
JOIN births b ON b.citizen_id = c.id
WHERE c.died IS NULL
GROUP BY age_band
ORDER BY age_band;
```

Marriages, divorces and the average length of the marriages that ended in divorce:

```sql
SELECT count(*) AS marriages,
       count(divorced_date) AS divorces,
       round(avg(divorced_date - married_date) FILTER (WHERE divorced_date IS NOT NULL) / 365.25, 1) AS avg_years_before_divorce
FROM marriages;
```

The most recently born people and their parents:

```sql
SELECT cf.name || ' ' || cs.name AS child, b.date AS born,
       mf.name || ' ' || ms.name AS mother,
       ff.name || ' ' || fs.name AS father
FROM births b
JOIN first_names cf ON cf.id = b.first_name_id
JOIN surnames cs ON cs.id = b.surname_id
JOIN citizen m ON m.id = b.mother_id
JOIN first_names mf ON mf.id = m.first_name_id
JOIN surnames ms ON ms.id = m.surname_id
JOIN citizen f ON f.id = b.father_id
JOIN first_names ff ON ff.id = f.first_name_id
JOIN surnames fs ON fs.id = f.surname_id
ORDER BY b.date DESC
LIMIT 10;
```

The most common surnames among voters:

```sql
SELECT s.name AS surname, count(*) AS voters
FROM voters v
JOIN citizen c ON c.id = v.citizen_id
JOIN surnames s ON s.id = c.surname_id
GROUP BY s.name
ORDER BY voters DESC
LIMIT 10;
```

Voters on the open register:

```sql
SELECT open_register, count(*) AS voters FROM voters GROUP BY open_register;
```

### 3) Access the manager VM

```bash
./bin/mgr-ssh.sh
```

### 4) Tear everything down

```bash
./bin/teardown-aws.sh
```

It suspends the `voters-infra` Kustomization and deletes the `Terraform` objects, tofu-controller destroys their resources. Use `flux resume kustomization voters-infra -n flux-system` to create them again.

## Design and architecture

### High-level components

- **Terraform modules (`infra/`)**
  - Create network + database + a “manager” compute instance.
  - The manager VM is the execution environment for the data pipeline: it gets a `/data` volume and runs `create-tables.sh` and `load-data.sh`.
- **Schema (`db/*.sql`)**
  - SQL defines the canonical schema; `bin/create-tables.sh` applies it in a dependency-aware order.
  - Some tables contain hyphens (e.g. `"con-postcodes"`, `"citizen-changes"`). Scripts use quoted identifiers where needed.
- **Loader pipeline (`db/load-*.py` orchestrated by `bin/load-data.sh`)**
  - The bash orchestration script runs each loader and **aborts on the first failure**.
  - Loaders are written to be resilient to data quality issues (warnings vs errors) and to stop early on repeated true errors (error limits).
- **API (`voters-api/`)**
  - Spring Boot + JPA on top of the same Postgres schema.
  - Intended for demos and downstream apps that want a clean REST interface.

### Database connection strategy

Scripts connect to Postgres via standard `PG*` environment variables:

- `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`

In cloud mode, the manager VM's cloud-init writes `infra/db/db-env.sh`, which exports these variables, from the database module's outputs.

**Important**: `db-env.sh` contains credentials and must not be committed. It is already ignored via `.gitignore`.

### “Manager VM” pattern (why it exists)

The data bundle can be large, and loading can be CPU/IO intensive. The manager VM pattern:

- Keeps the database private (VPC-only access) while still allowing controlled data ingestion.
- Makes runs reproducible: infra provisioning + schema + loaders happen in a consistent environment.
- Lets you upload data once and re-run loaders as needed.

## Troubleshooting

- **Infrastructure not created**: see [Viewing Terraform plans and output](#viewing-terraform-plans-and-output).
- **Local load needs data**: either place inputs under `/data`, or edit the `DATA_DIR` and file variables in `bin/load-data.sh`.
- **Schema mismatches**: rerun `./bin/create-tables.sh --delete` before loading.
- **Quoting issues**: table names with hyphens must be double-quoted in SQL queries.

## Safety / security notes

- Do not commit:
  - any `**/db-env.sh` file
  - SSH keys such as `loader.key`
- Treat the dataset as **synthetic** unless you explicitly load real data into `/data`.

