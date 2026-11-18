package dae.pc.voters.controller;

import dae.pc.voters.dto.StatisticsDto;
import dae.pc.voters.service.StatisticsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for the voter register's statistics.
 */
@RestController
@CrossOrigin(origins = "*")
public class StatisticsController {

    private final StatisticsService statisticsService;

    @Autowired
    public StatisticsController(StatisticsService statisticsService) {
        this.statisticsService = statisticsService;
    }

    @GetMapping("/api/statistics")
    public StatisticsDto statistics() {
        return statisticsService.statistics();
    }
}
