package dae.pc.voters.controller;

import dae.pc.voters.dto.CountryDto;
import dae.pc.voters.service.CountryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for countries, see CrudController and CountryService for the list filters.
 */
@RestController
@RequestMapping("/api/countries")
public class CountryController extends CrudController<CountryDto, Integer> {

    @Autowired
    public CountryController(CountryService service) {
        super(service);
    }
}
