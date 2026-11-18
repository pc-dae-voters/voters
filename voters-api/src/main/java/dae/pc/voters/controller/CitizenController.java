package dae.pc.voters.controller;

import dae.pc.voters.dto.CitizenDto;
import dae.pc.voters.service.CitizenService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * REST controller for citizens, see CrudController and CitizenService for the list filters. A citizen's birth
 * record, marriages, changes, children and voter registration are listed with /api/births?citizenId=,
 * /api/marriages?citizenId=, /api/citizen-changes?citizenId=, /api/births?parentId= and /api/voters/citizen/{id}.
 */
@RestController
@RequestMapping("/api/citizens")
public class CitizenController extends CrudController<CitizenDto, Integer> {

    private final CitizenService citizenService;

    @Autowired
    public CitizenController(CitizenService service) {
        super(service);
        this.citizenService = service;
    }

    /**
     * Mark a citizen as deceased.
     */
    @PutMapping("/{id}/deceased")
    public CitizenDto markAsDeceased(@PathVariable Integer id,
                                     @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate deathDate) {
        return citizenService.markAsDeceased(id, deathDate);
    }
}
