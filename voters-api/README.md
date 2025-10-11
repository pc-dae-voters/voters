# Voters API

A Spring Boot REST API for managing voter data, citizens, marriages, and related entities.

## Features

- **Citizen Management**: CRUD operations for citizens with name, gender, and status tracking
- **Voter Registration**: Manage voter registrations with open/closed register status
- **Address Management**: Handle addresses with place and constituency associations
- **Marriage Records**: Track marriages and divorces between citizens
- **Birth Records**: Maintain birth records with parent relationships
- **Change Tracking**: Flexible JSON-based change tracking for citizen records
- **Statistics**: Comprehensive statistics for citizens and voters
- **Pagination**: Support for paginated results
- **Search**: Name-based search functionality

## Technology Stack

- **Java 21**
- **Spring Boot 3.4.2**
- **Spring Data JPA**
- **PostgreSQL**
- **Maven**

## Getting Started

### Prerequisites

- Java 21 or higher
- Maven 3.6+
- PostgreSQL database

### Database Setup

1. Create a PostgreSQL database named `voters`
2. Run the database setup scripts in the `../db/` directory
3. Load the data using the scripts in the `../bin/` directory

#### Using Docker
For a consistent development environment, you can use the provided Docker Compose file to run a PostgreSQL database.

```bash
# From the voters-api directory
docker-compose up -d
```

This will start a PostgreSQL container with the correct database and credentials. You can then run the setup and data loading scripts against this container.

### Configuration

The application uses the following environment variables:

- `DB_USERNAME`: Database username (default: postgres)
- `DB_PASSWORD`: Database password (default: password)

### Running the Application

```bash
# From the voters-api directory
mvn spring-boot:run

# Or build and run
mvn clean package
java -jar target/voters-api-0.0.1.jar
```

The API will be available at `http://localhost:8080`

## Maven Coordinates

- **groupId:** `dae.pc`
- **artifactId:** `voter-management` (parent), `voters-api` (module)

## API Endpoints

### Citizens

#### Get Citizens
- `GET /api/citizens` - Get all citizens (paginated)
- `GET /api/citizens/all` - Get all citizens (no pagination)
- `GET /api/citizens/{id}` - Get citizen by ID
- `GET /api/citizens/gender/{gender}` - Get citizens by gender (M/F)
- `GET /api/citizens/status/{statusCode}` - Get citizens by status
- `GET /api/citizens/surname/{surname}` - Get citizens by surname
- `GET /api/citizens/firstname/{firstName}` - Get citizens by first name
- `GET /api/citizens/name?firstName=X&surname=Y` - Get citizens by full name
- `GET /api/citizens/alive` - Get alive citizens
- `GET /api/citizens/alive/paged` - Get alive citizens (paginated)
- `GET /api/citizens/search?searchTerm=X` - Search citizens by name
- `GET /api/citizens/statistics` - Get citizen statistics

#### Create/Update Citizens
- `POST /api/citizens` - Create a new citizen
- `PUT /api/citizens/{id}` - Update an existing citizen
- `PUT /api/citizens/{id}/deceased?deathDate=YYYY-MM-DD` - Mark citizen as deceased
- `DELETE /api/citizens/{id}` - Delete a citizen

### Voters

#### Get Voters
- `GET /api/voters` - Get all voters (paginated)
- `GET /api/voters/all` - Get all voters (no pagination)
- `GET /api/voters/{id}` - Get voter by ID
- `GET /api/voters/citizen/{citizenId}` - Get voter by citizen ID
- `GET /api/voters/constituency/{constituencyId}` - Get voters by constituency
- `GET /api/voters/constituency/name/{constituencyName}` - Get voters by constituency name
- `GET /api/voters/postcode/{postcode}` - Get voters by postcode
- `GET /api/voters/place/{placeName}` - Get voters by place name
- `GET /api/voters/country/{countryName}` - Get voters by country name
- `GET /api/voters/open-register` - Get voters on open register
- `GET /api/voters/open-register/paged` - Get voters on open register (paginated)
- `GET /api/voters/closed-register` - Get voters not on open register
- `GET /api/voters/registration-date?registrationDate=YYYY-MM-DD` - Get voters by registration date
- `GET /api/voters/registration-date/range?startDate=X&endDate=Y` - Get voters by registration date range
- `GET /api/voters/statistics` - Get voter statistics

#### Create/Update Voters
- `POST /api/voters` - Register a new voter
- `PUT /api/voters/{id}` - Update voter registration
- `PUT /api/voters/{id}/open-register?onOpenRegister=true` - Update open register status
- `PUT /api/voters/{id}/address?addressId=X` - Update voter's address
- `DELETE /api/voters/{id}` - Deregister a voter

## Data Models

### Citizen
```json
{
  "id": 1,
  "status": { "id": 1, "code": "ACTIVE", "description": "Active citizen" },
  "surname": { "id": 1, "name": "Smith" },
  "firstName": { "id": 1, "name": "John", "gender": "M" },
  "gender": "M",
  "died": null
}
```

### Voter
```json
{
  "id": 1,
  "citizen": { "id": 1, "fullName": "John Smith" },
  "address": { "id": 1, "address": "123 Main St", "postcode": "AB12 3CD" },
  "openRegister": true,
  "registrationDate": "2020-01-15"
}
```

## API Documentation

With the inclusion of `springdoc-openapi`, the API documentation is automatically generated.

- **Swagger UI**: `http://localhost:8080/swagger-ui.html`
- **OpenAPI 3.0 Spec (JSON)**: `http://localhost:8080/v3/api-docs`

## Pagination

Most endpoints support pagination with the following query parameters:
- `page`: Page number (0-based, default: 0)
- `size`: Page size (default: 20)

Example: `GET /api/citizens?page=0&size=10`

## Error Handling

The API returns appropriate HTTP status codes:
- `200 OK`: Successful operation
- `201 Created`: Resource created successfully
- `204 No Content`: Resource deleted successfully
- `400 Bad Request`: Invalid request data
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

## Health Check

- `GET /actuator/health` - Application health status
- `GET /actuator/info` - Application information
- `GET /actuator/metrics` - Application metrics

## Development

### Building
```bash
mvn clean compile
```

### Testing
```bash
mvn test
```

### Running Tests with Coverage
```bash
mvn clean test jacoco:report
```

## Database Schema

The API works with the following main tables:
- `citizen` - Citizen records
- `voters` - Voter registrations
- `addresses` - Address records
- `places` - Place/location records
- `constituencies` - Parliamentary constituencies
- `marriages` - Marriage records
- `births` - Birth records
- `citizen-changes` - Change tracking records

See the `../db/` directory for complete database schema and setup scripts. 