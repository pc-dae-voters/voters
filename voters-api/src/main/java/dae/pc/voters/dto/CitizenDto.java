package dae.pc.voters.dto;

import jakarta.validation.constraints.*;

import java.time.LocalDate;

/**
 * A citizen. On create and update the status can be given by statusId or statusCode and the names by id or
 * by name, a name that does not exist is added. birthDate and voterId are read-only.
 */
public record CitizenDto(
        Integer id,
        Integer statusId,
        String statusCode,
        String statusDescription,
        Integer firstNameId,
        String firstName,
        Integer surnameId,
        String surname,
        @Pattern(regexp = "[MF]") String gender,
        LocalDate died,
        LocalDate birthDate,
        Long voterId
) {
}
