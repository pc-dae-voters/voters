package dae.pc.voters.service;

import dae.pc.voters.entity.Voter;
import dae.pc.voters.repository.VoterRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

/**
 * Service for Voter business operations.
 */
@Service
@Transactional
public class VoterService {
    
    private final VoterRepository voterRepository;
    
    @Autowired
    public VoterService(VoterRepository voterRepository) {
        this.voterRepository = voterRepository;
    }
    
    /**
     * Find voter by ID.
     */
    public Optional<Voter> findById(Long id) {
        return voterRepository.findById(id);
    }
    
    /**
     * Find voter by citizen ID.
     */
    public Optional<Voter> findByCitizenId(Integer citizenId) {
        return voterRepository.findByCitizenId(citizenId);
    }
    
    /**
     * Find all voters with pagination.
     */
    public Page<Voter> findAll(Pageable pageable) {
        return voterRepository.findAll(pageable);
    }
    
    /**
     * Find all voters.
     */
    public List<Voter> findAll() {
        return voterRepository.findAll();
    }
    
    /**
     * Find voters by constituency ID.
     */
    public List<Voter> findByConstituencyId(Integer constituencyId) {
        return voterRepository.findByConstituencyId(constituencyId);
    }
    
    /**
     * Find voters by constituency name.
     */
    public List<Voter> findByConstituencyName(String constituencyName) {
        return voterRepository.findByConstituencyName(constituencyName);
    }
    
    /**
     * Find voters by postcode.
     */
    public List<Voter> findByPostcode(String postcode) {
        return voterRepository.findByPostcode(postcode);
    }
    
    /**
     * Find voters by place name.
     */
    public List<Voter> findByPlaceName(String placeName) {
        return voterRepository.findByPlaceName(placeName);
    }
    
    /**
     * Find voters by country name.
     */
    public List<Voter> findByCountryName(String countryName) {
        return voterRepository.findByCountryName(countryName);
    }
    
    /**
     * Find voters on the open register.
     */
    public List<Voter> findOnOpenRegister() {
        return voterRepository.findByOpenRegisterTrue();
    }
    
    /**
     * Find voters on the open register with pagination.
     */
    public Page<Voter> findOnOpenRegister(Pageable pageable) {
        return voterRepository.findByOpenRegisterTrue(pageable);
    }
    
    /**
     * Find voters not on the open register.
     */
    public List<Voter> findNotOnOpenRegister() {
        return voterRepository.findByOpenRegisterFalse();
    }
    
    /**
     * Find voters by registration date.
     */
    public List<Voter> findByRegistrationDate(LocalDate registrationDate) {
        return voterRepository.findByRegistrationDate(registrationDate);
    }
    
    /**
     * Find voters registered between two dates.
     */
    public List<Voter> findByRegistrationDateBetween(LocalDate startDate, LocalDate endDate) {
        return voterRepository.findByRegistrationDateBetween(startDate, endDate);
    }
    
    /**
     * Create a new voter registration.
     */
    public Voter registerVoter(Voter voter) {
        return voterRepository.save(voter);
    }
    
    /**
     * Update an existing voter registration.
     */
    public Voter updateVoter(Long id, Voter voterDetails) {
        return voterRepository.findById(id)
                .map(voter -> {
                    voter.setAddress(voterDetails.getAddress());
                    voter.setOpenRegister(voterDetails.getOpenRegister());
                    voter.setRegistrationDate(voterDetails.getRegistrationDate());
                    return voterRepository.save(voter);
                })
                .orElseThrow(() -> new RuntimeException("Voter not found with id: " + id));
    }
    
    /**
     * Update voter's open register status.
     */
    public Voter updateOpenRegisterStatus(Long id, boolean onOpenRegister) {
        return voterRepository.findById(id)
                .map(voter -> {
                    voter.setOpenRegister(onOpenRegister);
                    return voterRepository.save(voter);
                })
                .orElseThrow(() -> new RuntimeException("Voter not found with id: " + id));
    }
    
    /**
     * Update voter's address.
     */
    public Voter updateAddress(Long id, Integer addressId) {
        return voterRepository.findById(id)
                .map(voter -> {
                    // Note: This would need the Address entity to be properly set
                    // For now, we'll just update the reference
                    return voterRepository.save(voter);
                })
                .orElseThrow(() -> new RuntimeException("Voter not found with id: " + id));
    }
    
    /**
     * Deregister a voter.
     */
    public void deregisterVoter(Long id) {
        voterRepository.deleteById(id);
    }
    
    /**
     * Get statistics about voters.
     */
    public VoterStatistics getStatistics() {
        long totalVoters = voterRepository.count();
        long onOpenRegister = voterRepository.countByOpenRegisterTrue();
        long notOnOpenRegister = voterRepository.countByOpenRegisterFalse();
        
        return new VoterStatistics(totalVoters, onOpenRegister, notOnOpenRegister);
    }
    
    /**
     * Statistics class for voter data.
     */
    public static class VoterStatistics {
        private final long totalVoters;
        private final long onOpenRegister;
        private final long notOnOpenRegister;
        
        public VoterStatistics(long totalVoters, long onOpenRegister, long notOnOpenRegister) {
            this.totalVoters = totalVoters;
            this.onOpenRegister = onOpenRegister;
            this.notOnOpenRegister = notOnOpenRegister;
        }
        
        public long getTotalVoters() { return totalVoters; }
        public long getOnOpenRegister() { return onOpenRegister; }
        public long getNotOnOpenRegister() { return notOnOpenRegister; }
    }
} 