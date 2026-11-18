package dae.pc.voters.dto;

import jakarta.validation.constraints.*;

/**
 * A surname.
 */
public record SurnameDto(
        Integer id,
        @NotBlank String name
) {
}
