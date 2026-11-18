package dae.pc.voters.dto;

import jakarta.validation.constraints.*;

/**
 * A first name.
 */
public record FirstNameDto(
        Integer id,
        @NotBlank String name,
        @Pattern(regexp = "[MF]") String gender
) {
}
