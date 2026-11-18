package dae.pc.voters.controller;

import dae.pc.voters.dto.CitizenStatusDto;
import dae.pc.voters.service.CitizenStatusService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for citizenship statuses, see CrudController and CitizenStatusService for the list filters.
 */
@RestController
@RequestMapping("/api/citizen-statuses")
public class CitizenStatusController extends CrudController<CitizenStatusDto, Integer> {

    @Autowired
    public CitizenStatusController(CitizenStatusService service) {
        super(service);
    }
}
