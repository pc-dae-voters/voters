package dae.pc.voters.dto;

import jakarta.validation.constraints.*;

/**
 * A parliamentary constituency.
 */
public record ConstituencyDto(
        Integer id,
        @Size(max = 255) String code,
        @NotBlank String name,
        @Size(max = 3) String tla,
        String nation,
        String region,
        String ctype,
        Float area
) {
}
