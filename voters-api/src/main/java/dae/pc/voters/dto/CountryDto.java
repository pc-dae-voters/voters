package dae.pc.voters.dto;

import jakarta.validation.constraints.*;

/**
 * A country.
 */
public record CountryDto(
        Integer id,
        @NotBlank String name
) {
}
