package dae.pc.voters.dto;

import jakarta.validation.constraints.*;

/**
 * A postcode's constituency, the constituency id and name are read-only.
 */
public record PostcodeDto(
        @NotBlank @Size(max = 15) String postcode,
        @NotBlank String conCode,
        Integer constituencyId,
        String constituencyName
) {
}
