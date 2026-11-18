package dae.pc.voters.dto;

import jakarta.validation.constraints.*;

import java.time.LocalDate;

/**
 * A marriage, the partners' names are read-only.
 */
public record MarriageDto(
        Integer id,
        @NotNull Integer partner1Id,
        String partner1Name,
        @NotNull Integer partner2Id,
        String partner2Name,
        @NotNull LocalDate marriedDate,
        LocalDate divorcedDate
) {
}
