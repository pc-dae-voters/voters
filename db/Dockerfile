# PostgreSQL with the voters schema, created by bin/create-tables.sh from db/*.sql when the database is first
# initialised, i.e. when its data volume is empty. Built from the repository root by bin/kind-build-images.sh:
#   docker build -f db/Dockerfile -t voters-db .
FROM postgres:16
COPY bin/create-tables.sh /opt/voters/bin/create-tables.sh
COPY db/*.sql /opt/voters/db/
COPY db/docker-init.sh /docker-entrypoint-initdb.d/voters-schema.sh
