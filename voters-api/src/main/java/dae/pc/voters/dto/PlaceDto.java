package dae.pc.voters.dto;

import jakarta.validation.constraints.*;

/**
 * A place, the country name is read-only.
 */
public record PlaceDto(
        Integer id,
        @NotBlank String name,
        Integer countryId,
        String countryName
) {
}
