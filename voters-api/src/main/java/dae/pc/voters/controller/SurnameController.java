package dae.pc.voters.controller;

import dae.pc.voters.dto.SurnameDto;
import dae.pc.voters.service.SurnameService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for surnames, see CrudController and SurnameService for the list filters.
 */
@RestController
@RequestMapping("/api/surnames")
public class SurnameController extends CrudController<SurnameDto, Integer> {

    @Autowired
    public SurnameController(SurnameService service) {
        super(service);
    }
}
