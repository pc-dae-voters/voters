package dae.pc.voters.controller;

import dae.pc.voters.dto.CitizenChangeDto;
import dae.pc.voters.service.CitizenChangeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for changes to citizens' records, see CrudController and CitizenChangeService for the list filters.
 */
@RestController
@RequestMapping("/api/citizen-changes")
public class CitizenChangeController extends CrudController<CitizenChangeDto, Integer> {

    @Autowired
    public CitizenChangeController(CitizenChangeService service) {
        super(service);
    }
}
