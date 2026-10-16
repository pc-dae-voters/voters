package dae.pc.voters;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Main Spring Boot application for the Voters API.
 * Provides REST endpoints for managing voter data, citizens, marriages, and related entities.
 */
@SpringBootApplication
public class VotersApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(VotersApiApplication.class, args);
    }
} 