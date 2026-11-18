package dae.pc.voters.controller;

import dae.pc.voters.dto.FirstNameDto;
import dae.pc.voters.service.FirstNameService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for first names, see CrudController and FirstNameService for the list filters.
 */
@RestController
@RequestMapping("/api/first-names")
public class FirstNameController extends CrudController<FirstNameDto, Integer> {

    @Autowired
    public FirstNameController(FirstNameService service) {
        super(service);
    }
}
