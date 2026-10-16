# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Infrastructure + data pipeline for a synthetic UK voter register dataset, plus an optional Spring Boot REST API (`voters-api/`) to query and update it. It runs in two modes: a cloud "manager VM" mode (Terraform provisions DB + manager machine; loaders run on the manager against a `/data` bundle) and a local dev mode (Postgres via Docker Compose, loaders run against localhost).

## Commands

### Local dev database
```bash
cd voters-api && docker-compose up -d      # Postgres on localhost:5432, db=voters, user=postgres, password=password
```

### Schema
```bash
./bin/create-tables.sh --delete            # drop + recreate all tables, dependency-ordered
./bin/create-tables.sh --tables citizen,voters   # create/update specific tables only
```

### Data loading
```bash
./bin/load-data.sh
```
Orchestrates the Python loader pipeline in dependency order (constituencies → con-postcodes → names → places → address-places → addresses → synthetic-people → voters). Creates/reuses a venv at `.venv` and installs `db/requirements.txt`. Aborts on first loader failure. Expects input CSVs under `/data` (paths are hardcoded in the script, not env-configurable). Individual loaders can be run directly, e.g. `python3 db/load-synthetic-people.py --num-people 10000 --random-seed 12345`.

### API (voters-api/, Java 21 + Spring Boot 3.4.2 + Maven)
```bash
cd voters-api && mvn spring-boot:run                    # run from source
mvn clean package -DskipTests && java -jar target/voters-api-0.0.1.jar
mvn clean compile          # build only
mvn test                   # run tests
mvn clean test jacoco:report   # tests with coverage
./bin/build-run.sh          # sources infra/aws/db/db-env.sh, builds, runs against RDS
```
There is currently no `src/test` directory in `voters-api` — no existing tests to model new ones on.
API runs on `http://localhost:8080`; Swagger UI at `/swagger-ui.html`, OpenAPI spec at `/v3/api-docs`, health at `/actuator/health`.

### Cloud environment (AWS, via tofu-controller on an EKS cluster)
```bash
./bin/setup-aws.sh [--skip-data-upload --skip-data-load]   # waits for the infra, uploads ../data, loads it on the manager VM
./bin/teardown-aws.sh
./bin/mgr-ssh.sh          # SSH to the manager VM
./bin/db-query.sh         # inspect tables/counts/rows (needs a db env file, run it on the manager VM)
kubectl get terraform -n flux-system   # infra status, kubectl must use the EKS cluster, e.g. KUBECONFIG=~/.kube/eks-voters.yaml
```

## Architecture

- **`infra/aws/`** — Terraform root modules: `vpc`, `peering` (with the EKS cluster's VPC), `db` (RDS), `data-volume` (EBS) and `mgr-vm`, plus `modules/vpc` and `modules/rds`. They are applied by tofu-controller on the EKS cluster from the `Terraform` objects in `infra/aws/flux`, which the aws-eks-voters cluster repository deploys; settings come from the EKS cluster's `tf-config` ConfigMap and AWS access from its `tf-runner` Pod Identity role. Modules share outputs using `terraform_remote_state` on `voters-infra/<module>/terraform.tfstate`, and use a partial S3 backend configured by the `Terraform` objects. The manager VM is the execution environment for the pipeline — it mounts `/data` and runs `create-tables.sh` + `load-data.sh` there, keeping the DB network-private. Its cloud-init writes `infra/db/db-env.sh` exporting `PGHOST`/`PGPORT`/`PGDATABASE`/`PGUSER`/`PGPASSWORD`, which the bin/ scripts source.
- **`db/*.sql` + `db/load-*.py`** — SQL files are the canonical schema; `bin/create-tables.sh` reads a hardcoded `TABLE_DEPENDENCIES` map to apply them in the correct order (and to compute what to drop with `--delete`). Table names with hyphens (`"con-postcodes"`, `"citizen-changes"`) require quoted identifiers in SQL. The Python loaders are idempotent-ish generators/importers; they distinguish data-quality *warnings* from true *errors* and stop early after repeated true errors — treat repeated loader errors as a real data or schema problem, not noise.
- **`voters-api/`** — Spring Boot + Spring Data JPA on the same Postgres schema, no service-layer surprises: `controller/` → `service/` → `repository/` (Spring Data interfaces) → `entity/` (JPA entities mapping 1:1 to the `db/*.sql` tables). Adding a field to a table means updating the `.sql` file, `create-tables.sh`'s dependency map if it's a new table, the JPA `entity/`, and the relevant loader in `db/` — these four tend to move together.
- Cross-cutting scripts (`bin/create-tables.sh`, `bin/load-data.sh`) live above both `db/` and `infra/`, and are the integration point between schema, data, and infra — check them first when a table or column needs to change.

## Conventions

- **Log every session**: for each user request handled in this repo, append a new entry to `docs/AI/session_log.md` (request, response summary, files modified) — do not edit or overwrite previous entries, only add new ones.
- Never commit `**/db-env.sh` or `loader.key` — these carry live credentials and are already gitignored.
- Treat the dataset as synthetic unless real data has explicitly been loaded into `/data`.
