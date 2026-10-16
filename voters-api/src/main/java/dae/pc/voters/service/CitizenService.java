package dae.pc.voters.service;

import dae.pc.voters.entity.Citizen;
import dae.pc.voters.entity.CitizenStatus;
import dae.pc.voters.entity.FirstName;
import dae.pc.voters.entity.Surname;
import dae.pc.voters.repository.CitizenRepository;
import dae.pc.voters.repository.CitizenStatusRepository;
import dae.pc.voters.repository.FirstNameRepository;
import dae.pc.voters.repository.SurnameRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Service for Citizen business operations.
 */
@Service
@Transactional
public class CitizenService {
    
    private final CitizenRepository citizenRepository;
    private final CitizenStatusRepository citizenStatusRepository;
    private final FirstNameRepository firstNameRepository;
    private final SurnameRepository surnameRepository;
    
    @Autowired
    public CitizenService(CitizenRepository citizenRepository,
                         CitizenStatusRepository citizenStatusRepository,
                         FirstNameRepository firstNameRepository,
                         SurnameRepository surnameRepository) {
        this.citizenRepository = citizenRepository;
        this.citizenStatusRepository = citizenStatusRepository;
        this.firstNameRepository = firstNameRepository;
        this.surnameRepository = surnameRepository;
    }
    
    /**
     * Find citizen by ID.
     */
    public Optional<Citizen> findById(Integer id) {
        return citizenRepository.findById(id);
    }
    
    /**
     * Find all citizens with pagination.
     */
    public Page<Citizen> findAll(Pageable pageable) {
        return citizenRepository.findAll(pageable);
    }
    
    /**
     * Find all citizens.
     */
    public List<Citizen> findAll() {
        return citizenRepository.findAll();
    }
    
    /**
     * Find citizens by gender.
     */
    public List<Citizen> findByGender(Citizen.Gender gender) {
        return citizenRepository.findByGender(gender);
    }
    
    /**
     * Find citizens by status code.
     */
    public List<Citizen> findByStatusCode(String statusCode) {
        return citizenRepository.findByStatusCode(statusCode);
    }
    
    /**
     * Find citizens by surname.
     */
    public List<Citizen> findBySurname(String surname) {
        return citizenRepository.findBySurname(surname);
    }
    
    /**
     * Find citizens by first name.
     */
    public List<Citizen> findByFirstName(String firstName) {
        return citizenRepository.findByFirstName(firstName);
    }
    
    /**
     * Find citizens by full name.
     */
    public List<Citizen> findByFullName(String firstName, String surname) {
        return citizenRepository.findByFullName(firstName, surname);
    }
    
    /**
     * Find alive citizens.
     */
    public List<Citizen> findAlive() {
        return citizenRepository.findByDiedIsNull();
    }
    
    /**
     * Find alive citizens with pagination.
     */
    public Page<Citizen> findAlive(Pageable pageable) {
        return citizenRepository.findByDiedIsNull(pageable);
    }
    
    /**
     * Search citizens by name.
     */
    public List<Citizen> searchByName(String searchTerm) {
        return citizenRepository.searchByName(searchTerm);
    }
    
    /**
     * Create a new citizen.
     */
    public Citizen createCitizen(Citizen citizen) {
        return citizenRepository.save(citizen);
    }
    
    /**
     * Update an existing citizen.
     */
    public Citizen updateCitizen(Integer id, Citizen citizenDetails) {
        return citizenRepository.findById(id)
                .map(citizen -> {
                    citizen.setStatus(citizenDetails.getStatus());
                    citizen.setSurname(citizenDetails.getSurname());
                    citizen.setFirstName(citizenDetails.getFirstName());
                    citizen.setGender(citizenDetails.getGender());
                    citizen.setDied(citizenDetails.getDied());
                    return citizenRepository.save(citizen);
                })
                .orElseThrow(() -> new RuntimeException("Citizen not found with id: " + id));
    }
    
    /**
     * Mark a citizen as deceased.
     */
    public Citizen markAsDeceased(Integer id, LocalDate deathDate) {
        return citizenRepository.findById(id)
                .map(citizen -> {
                    citizen.setDied(deathDate);
                    return citizenRepository.save(citizen);
                })
                .orElseThrow(() -> new RuntimeException("Citizen not found with id: " + id));
    }
    
    /**
     * Delete a citizen.
     */
    public void deleteCitizen(Integer id) {
        citizenRepository.deleteById(id);
    }
    
    /**
     * Get statistics about citizens.
     */
    public CitizenStatistics getStatistics() {
        long totalCitizens = citizenRepository.count();
        long aliveCitizens = citizenRepository.countByDiedIsNull();
        long maleCitizens = citizenRepository.countByGender(Citizen.Gender.M);
        long femaleCitizens = citizenRepository.countByGender(Citizen.Gender.F);
        
        return new CitizenStatistics(totalCitizens, aliveCitizens, maleCitizens, femaleCitizens);
    }
    
    /**
     * Statistics class for citizen data.
     */
    public static class CitizenStatistics {
        private final long totalCitizens;
        private final long aliveCitizens;
        private final long maleCitizens;
        private final long femaleCitizens;
        
        public CitizenStatistics(long totalCitizens, long aliveCitizens, long maleCitizens, long femaleCitizens) {
            this.totalCitizens = totalCitizens;
            this.aliveCitizens = aliveCitizens;
            this.maleCitizens = maleCitizens;
            this.femaleCitizens = femaleCitizens;
        }
        
        public long getTotalCitizens() { return totalCitizens; }
        public long getAliveCitizens() { return aliveCitizens; }
        public long getMaleCitizens() { return maleCitizens; }
        public long getFemaleCitizens() { return femaleCitizens; }
        public long getDeceasedCitizens() { return totalCitizens - aliveCitizens; }
    }
} 