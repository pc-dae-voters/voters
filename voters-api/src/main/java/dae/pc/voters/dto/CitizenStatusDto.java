package dae.pc.voters.dto;

import jakarta.validation.constraints.*;

/**
 * A citizenship status.
 */
public record CitizenStatusDto(
        Integer id,
        @NotBlank @Size(max = 10) String code,
        String description
) {
}
