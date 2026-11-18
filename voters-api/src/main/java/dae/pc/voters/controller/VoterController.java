package dae.pc.voters.controller;

import dae.pc.voters.dto.VoterDto;
import dae.pc.voters.service.VoterService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for voter registrations, see CrudController and VoterService for the list filters.
 */
@RestController
@RequestMapping("/api/voters")
public class VoterController extends CrudController<VoterDto, Long> {

    private final VoterService voterService;

    @Autowired
    public VoterController(VoterService service) {
        super(service);
        this.voterService = service;
    }

    /**
     * Get a citizen's voter registration.
     */
    @GetMapping("/citizen/{citizenId}")
    public VoterDto getByCitizen(@PathVariable Integer citizenId) {
        return voterService.getByCitizen(citizenId);
    }

    /**
     * Add a voter to, or remove them from, the open register.
     */
    @PutMapping("/{id}/open-register")
    public VoterDto setOpenRegister(@PathVariable Long id, @RequestParam boolean onOpenRegister) {
        return voterService.setOpenRegister(id, onOpenRegister);
    }
}
