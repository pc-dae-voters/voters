package dae.pc.voters.controller;

import dae.pc.voters.dto.ConstituencyDto;
import dae.pc.voters.service.ConstituencyService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * REST controller for constituencies, see CrudController and ConstituencyService for the list filters. A
 * constituency's voters, addresses and postcodes are listed with /api/voters?constituencyId=,
 * /api/addresses?constituencyId= and /api/postcodes?conCode=.
 */
@RestController
@RequestMapping("/api/constituencies")
public class ConstituencyController extends CrudController<ConstituencyDto, Integer> {

    private final ConstituencyService constituencyService;

    @Autowired
    public ConstituencyController(ConstituencyService service) {
        super(service);
        this.constituencyService = service;
    }

    @GetMapping("/nations")
    public List<String> nations() {
        return constituencyService.nations();
    }

    @GetMapping("/regions")
    public List<String> regions() {
        return constituencyService.regions();
    }
}
