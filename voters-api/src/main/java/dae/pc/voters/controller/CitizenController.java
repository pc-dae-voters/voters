package dae.pc.voters.controller;

import dae.pc.voters.entity.Citizen;
import dae.pc.voters.service.CitizenService;
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
 * REST controller for Citizen operations.
 */
@RestController
@RequestMapping("/api/citizens")
@CrossOrigin(origins = "*")
public class CitizenController {
    
    private final CitizenService citizenService;
    
    @Autowired
    public CitizenController(CitizenService citizenService) {
        this.citizenService = citizenService;
    }
    
    /**
     * Get all citizens with pagination.
     */
    @GetMapping
    public ResponseEntity<Page<Citizen>> getAllCitizens(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Citizen> citizens = citizenService.findAll(pageable);
        return ResponseEntity.ok(citizens);
    }
    
    /**
     * Get all citizens (no pagination).
     */
    @GetMapping("/all")
    public ResponseEntity<List<Citizen>> getAllCitizens() {
        List<Citizen> citizens = citizenService.findAll();
        return ResponseEntity.ok(citizens);
    }
    
    /**
     * Get citizen by ID.
     */
    @GetMapping("/{id}")
    public ResponseEntity<Citizen> getCitizenById(@PathVariable Integer id) {
        Optional<Citizen> citizen = citizenService.findById(id);
        return citizen.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
    /**
     * Get citizens by gender.
     */
    @GetMapping("/gender/{gender}")
    public ResponseEntity<List<Citizen>> getCitizensByGender(@PathVariable Citizen.Gender gender) {
        List<Citizen> citizens = citizenService.findByGender(gender);
        return ResponseEntity.ok(citizens);
    }
    
    /**
     * Get citizens by status code.
     */
    @GetMapping("/status/{statusCode}")
    public ResponseEntity<List<Citizen>> getCitizensByStatus(@PathVariable String statusCode) {
        List<Citizen> citizens = citizenService.findByStatusCode(statusCode);
        return ResponseEntity.ok(citizens);
    }
    
    /**
     * Get citizens by surname.
     */
    @GetMapping("/surname/{surname}")
    public ResponseEntity<List<Citizen>> getCitizensBySurname(@PathVariable String surname) {
        List<Citizen> citizens = citizenService.findBySurname(surname);
        return ResponseEntity.ok(citizens);
    }
    
    /**
     * Get citizens by first name.
     */
    @GetMapping("/firstname/{firstName}")
    public ResponseEntity<List<Citizen>> getCitizensByFirstName(@PathVariable String firstName) {
        List<Citizen> citizens = citizenService.findByFirstName(firstName);
        return ResponseEntity.ok(citizens);
    }
    
    /**
     * Get citizens by full name.
     */
    @GetMapping("/name")
    public ResponseEntity<List<Citizen>> getCitizensByFullName(
            @RequestParam String firstName,
            @RequestParam String surname) {
        List<Citizen> citizens = citizenService.findByFullName(firstName, surname);
        return ResponseEntity.ok(citizens);
    }
    
    /**
     * Get alive citizens.
     */
    @GetMapping("/alive")
    public ResponseEntity<List<Citizen>> getAliveCitizens() {
        List<Citizen> citizens = citizenService.findAlive();
        return ResponseEntity.ok(citizens);
    }
    
    /**
     * Get alive citizens with pagination.
     */
    @GetMapping("/alive/paged")
    public ResponseEntity<Page<Citizen>> getAliveCitizensPaged(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Citizen> citizens = citizenService.findAlive(pageable);
        return ResponseEntity.ok(citizens);
    }
    
    /**
     * Search citizens by name.
     */
    @GetMapping("/search")
    public ResponseEntity<List<Citizen>> searchCitizensByName(@RequestParam String searchTerm) {
        List<Citizen> citizens = citizenService.searchByName(searchTerm);
        return ResponseEntity.ok(citizens);
    }
    
    /**
     * Create a new citizen.
     */
    @PostMapping
    public ResponseEntity<Citizen> createCitizen(@RequestBody Citizen citizen) {
        Citizen createdCitizen = citizenService.createCitizen(citizen);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdCitizen);
    }
    
    /**
     * Update an existing citizen.
     */
    @PutMapping("/{id}")
    public ResponseEntity<Citizen> updateCitizen(@PathVariable Integer id, @RequestBody Citizen citizen) {
        try {
            Citizen updatedCitizen = citizenService.updateCitizen(id, citizen);
            return ResponseEntity.ok(updatedCitizen);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    /**
     * Mark a citizen as deceased.
     */
    @PutMapping("/{id}/deceased")
    public ResponseEntity<Citizen> markAsDeceased(
            @PathVariable Integer id,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate deathDate) {
        try {
            Citizen updatedCitizen = citizenService.markAsDeceased(id, deathDate);
            return ResponseEntity.ok(updatedCitizen);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    /**
     * Delete a citizen.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCitizen(@PathVariable Integer id) {
        citizenService.deleteCitizen(id);
        return ResponseEntity.noContent().build();
    }
    
    /**
     * Get citizen statistics.
     */
    @GetMapping("/statistics")
    public ResponseEntity<CitizenService.CitizenStatistics> getStatistics() {
        CitizenService.CitizenStatistics statistics = citizenService.getStatistics();
        return ResponseEntity.ok(statistics);
    }
} 