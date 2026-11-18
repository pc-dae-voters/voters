package dae.pc.voters.dto;

import jakarta.validation.constraints.*;

import java.time.LocalDate;

/**
 * A voter registration. The citizen, address and constituency details are read-only, registrationDate defaults
 * to today and openRegister to false.
 */
public record VoterDto(
        Long id,
        @NotNull Integer citizenId,
        String citizenName,
        @NotNull Integer addressId,
        String address,
        String postcode,
        String placeName,
        Integer constituencyId,
        String constituencyName,
        Boolean openRegister,
        LocalDate registrationDate
) {
}
