package dae.pc.voters.service;

/**
 * Thrown when a requested record does not exist, the API returns 404 Not Found.
 */
public class NotFoundException extends RuntimeException {

    public NotFoundException(String resource, Object id) {
        super(resource + " " + id + " not found");
    }
}
