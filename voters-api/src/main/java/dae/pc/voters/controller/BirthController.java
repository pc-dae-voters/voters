package dae.pc.voters.controller;

import dae.pc.voters.dto.BirthDto;
import dae.pc.voters.service.BirthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for birth records, see CrudController and BirthService for the list filters.
 */
@RestController
@RequestMapping("/api/births")
public class BirthController extends CrudController<BirthDto, Integer> {

    @Autowired
    public BirthController(BirthService service) {
        super(service);
    }
}
