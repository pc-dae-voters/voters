package dae.pc.voters.dto;

import jakarta.validation.constraints.*;

import java.time.LocalDate;

/**
 * A birth record. The names are read-only, apart from firstName and surname, which, like CitizenDto, can be
 * given instead of firstNameId and surnameId.
 */
public record BirthDto(
        Integer id,
        Integer citizenId,
        String citizenName,
        @NotNull LocalDate date,
        Integer firstNameId,
        String firstName,
        Integer surnameId,
        String surname,
        @Pattern(regexp = "[MF]") String gender,
        Integer placeId,
        String placeName,
        Integer fatherId,
        String fatherName,
        Integer motherId,
        String motherName
) {
}
