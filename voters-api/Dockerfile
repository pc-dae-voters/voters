# Voters API and web UI image, built from the repository root by bin/kind-build-images.sh:
#   docker build -f voters-api/Dockerfile -t voters-api .
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml .
COPY voters-api/pom.xml voters-api/
# Download the dependencies in their own layer, so source changes don't download them again
RUN mvn -B -q -pl voters-api -am dependency:go-offline
COPY voters-api/src voters-api/src
RUN mvn -B -q -pl voters-api -am package -DskipTests

FROM eclipse-temurin:21-jre
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin voters
COPY --from=build /src/voters-api/target/voters-api-*.jar /app/voters-api.jar
USER 10001
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "/app/voters-api.jar"]
