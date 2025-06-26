package dae.pc.voters.controller;

import dae.pc.voters.entity.Voter;
import dae.pc.voters.service.VoterService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * REST controller for Voter operations.
 */
@RestController
@RequestMapping("/api/voters")
@CrossOrigin(origins = "*")
public class VoterController {
    
    private final VoterService voterService;
    
    @Autowired
    public VoterController(VoterService voterService) {
        this.voterService = voterService;
    }
    
    /**
     * Get all voters with pagination.
     */
    @GetMapping
    public ResponseEntity<Page<Voter>> getAllVoters(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Voter> voters = voterService.findAll(pageable);
        return ResponseEntity.ok(voters);
    }
    
    /**
     * Get all voters (no pagination).
     */
    @GetMapping("/all")
    public ResponseEntity<List<Voter>> getAllVoters() {
        List<Voter> voters = voterService.findAll();
        return ResponseEntity.ok(voters);
    }
    
    /**
     * Get voter by ID.
     */
    @GetMapping("/{id}")
    public ResponseEntity<Voter> getVoterById(@PathVariable Long id) {
        Optional<Voter> voter = voterService.findById(id);
        return voter.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
    /**
     * Get voter by citizen ID.
     */
    @GetMapping("/citizen/{citizenId}")
    public ResponseEntity<Voter> getVoterByCitizenId(@PathVariable Integer citizenId) {
        Optional<Voter> voter = voterService.findByCitizenId(citizenId);
        return voter.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
    /**
     * Get voters by constituency ID.
     */
    @GetMapping("/constituency/{constituencyId}")
    public ResponseEntity<List<Voter>> getVotersByConstituencyId(@PathVariable Integer constituencyId) {
        List<Voter> voters = voterService.findByConstituencyId(constituencyId);
        return ResponseEntity.ok(voters);
    }
    
    /**
     * Get voters by constituency name.
     */
    @GetMapping("/constituency/name/{constituencyName}")
    public ResponseEntity<List<Voter>> getVotersByConstituencyName(@PathVariable String constituencyName) {
        List<Voter> voters = voterService.findByConstituencyName(constituencyName);
        return ResponseEntity.ok(voters);
    }
    
    /**
     * Get voters by postcode.
     */
    @GetMapping("/postcode/{postcode}")
    public ResponseEntity<List<Voter>> getVotersByPostcode(@PathVariable String postcode) {
        List<Voter> voters = voterService.findByPostcode(postcode);
        return ResponseEntity.ok(voters);
    }
    
    /**
     * Get voters by place name.
     */
    @GetMapping("/place/{placeName}")
    public ResponseEntity<List<Voter>> getVotersByPlaceName(@PathVariable String placeName) {
        List<Voter> voters = voterService.findByPlaceName(placeName);
        return ResponseEntity.ok(voters);
    }
    
    /**
     * Get voters by country name.
     */
    @GetMapping("/country/{countryName}")
    public ResponseEntity<List<Voter>> getVotersByCountryName(@PathVariable String countryName) {
        List<Voter> voters = voterService.findByCountryName(countryName);
        return ResponseEntity.ok(voters);
    }
    
    /**
     * Get voters on the open register.
     */
    @GetMapping("/open-register")
    public ResponseEntity<List<Voter>> getVotersOnOpenRegister() {
        List<Voter> voters = voterService.findOnOpenRegister();
        return ResponseEntity.ok(voters);
    }
    
    /**
     * Get voters on the open register with pagination.
     */
    @GetMapping("/open-register/paged")
    public ResponseEntity<Page<Voter>> getVotersOnOpenRegisterPaged(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Voter> voters = voterService.findOnOpenRegister(pageable);
        return ResponseEntity.ok(voters);
    }
    
    /**
     * Get voters not on the open register.
     */
    @GetMapping("/closed-register")
    public ResponseEntity<List<Voter>> getVotersNotOnOpenRegister() {
        List<Voter> voters = voterService.findNotOnOpenRegister();
        return ResponseEntity.ok(voters);
    }
    
    /**
     * Get voters by registration date.
     */
    @GetMapping("/registration-date")
    public ResponseEntity<List<Voter>> getVotersByRegistrationDate(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate registrationDate) {
        List<Voter> voters = voterService.findByRegistrationDate(registrationDate);
        return ResponseEntity.ok(voters);
    }
    
    /**
     * Get voters registered between two dates.
     */
    @GetMapping("/registration-date/range")
    public ResponseEntity<List<Voter>> getVotersByRegistrationDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<Voter> voters = voterService.findByRegistrationDateBetween(startDate, endDate);
        return ResponseEntity.ok(voters);
    }
    
    /**
     * Register a new voter.
     */
    @PostMapping
    public ResponseEntity<Voter> registerVoter(@RequestBody Voter voter) {
        Voter registeredVoter = voterService.registerVoter(voter);
        return ResponseEntity.status(HttpStatus.CREATED).body(registeredVoter);
    }
    
    /**
     * Update an existing voter registration.
     */
    @PutMapping("/{id}")
    public ResponseEntity<Voter> updateVoter(@PathVariable Long id, @RequestBody Voter voter) {
        try {
            Voter updatedVoter = voterService.updateVoter(id, voter);
            return ResponseEntity.ok(updatedVoter);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    /**
     * Update voter's open register status.
     */
    @PutMapping("/{id}/open-register")
    public ResponseEntity<Voter> updateOpenRegisterStatus(
            @PathVariable Long id,
            @RequestParam boolean onOpenRegister) {
        try {
            Voter updatedVoter = voterService.updateOpenRegisterStatus(id, onOpenRegister);
            return ResponseEntity.ok(updatedVoter);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    /**
     * Update voter's address.
     */
    @PutMapping("/{id}/address")
    public ResponseEntity<Voter> updateAddress(
            @PathVariable Long id,
            @RequestParam Integer addressId) {
        try {
            Voter updatedVoter = voterService.updateAddress(id, addressId);
            return ResponseEntity.ok(updatedVoter);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    /**
     * Deregister a voter.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deregisterVoter(@PathVariable Long id) {
        voterService.deregisterVoter(id);
        return ResponseEntity.noContent().build();
    }
    
    /**
     * Get voter statistics.
     */
    @GetMapping("/statistics")
    public ResponseEntity<VoterService.VoterStatistics> getStatistics() {
        VoterService.VoterStatistics statistics = voterService.getStatistics();
        return ResponseEntity.ok(statistics);
    }
} 