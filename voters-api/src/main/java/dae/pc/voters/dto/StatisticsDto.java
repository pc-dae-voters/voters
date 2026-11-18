package dae.pc.voters.dto;

import java.util.Map;

/**
 * Row counts of the voter register's tables, plus voter and citizen breakdowns.
 */
public record StatisticsDto(
        Map<String, Long> counts,
        long votersOnOpenRegister,
        long citizensAlive,
        long citizensMale,
        long citizensFemale
) {
}
