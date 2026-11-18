package dae.pc.voters.dto;

import jakarta.validation.constraints.*;

import java.time.LocalDate;
import java.util.Map;

/**
 * A change to a citizen's record, the citizen's name is read-only.
 */
public record CitizenChangeDto(
        Integer id,
        @NotNull Integer citizenId,
        String citizenName,
        @NotNull LocalDate changeDate,
        Map<String, Object> details
) {
}
