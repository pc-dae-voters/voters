package dae.pc.voters.service;

/**
 * Thrown when a request is invalid, e.g. it references a record that does not exist, the API returns 400 Bad Request.
 */
public class BadRequestException extends RuntimeException {

    public BadRequestException(String message) {
        super(message);
    }
}
