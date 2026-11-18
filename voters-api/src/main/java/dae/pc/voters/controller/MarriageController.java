package dae.pc.voters.controller;

import dae.pc.voters.dto.MarriageDto;
import dae.pc.voters.service.MarriageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for marriages, see CrudController and MarriageService for the list filters.
 */
@RestController
@RequestMapping("/api/marriages")
public class MarriageController extends CrudController<MarriageDto, Integer> {

    @Autowired
    public MarriageController(MarriageService service) {
        super(service);
    }
}
