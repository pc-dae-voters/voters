package dae.pc.voters.service;

import dae.pc.voters.dto.StatisticsDto;
import dae.pc.voters.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Row counts for the dashboard and the CLI's stats command.
 */
@Service
@Transactional(readOnly = true)
public class StatisticsService {

    private final Map<String, BaseRepository<?, ?>> repositories = new LinkedHashMap<>();
    private final VoterRepository voterRepository;
    private final CitizenRepository citizenRepository;

    @Autowired
    public StatisticsService(VoterRepository voterRepository, CitizenRepository citizenRepository,
                             ConstituencyRepository constituencyRepository, ConPostcodeRepository conPostcodeRepository,
                             AddressRepository addressRepository, PlaceRepository placeRepository,
                             CountryRepository countryRepository, BirthRepository birthRepository,
                             MarriageRepository marriageRepository, CitizenChangeRepository citizenChangeRepository,
                             FirstNameRepository firstNameRepository, SurnameRepository surnameRepository) {
        this.voterRepository = voterRepository;
        this.citizenRepository = citizenRepository;
        // The keys are the API's paths, /api/<key>
        repositories.put("voters", voterRepository);
        repositories.put("citizens", citizenRepository);
        repositories.put("constituencies", constituencyRepository);
        repositories.put("postcodes", conPostcodeRepository);
        repositories.put("addresses", addressRepository);
        repositories.put("places", placeRepository);
        repositories.put("countries", countryRepository);
        repositories.put("births", birthRepository);
        repositories.put("marriages", marriageRepository);
        repositories.put("citizen-changes", citizenChangeRepository);
        repositories.put("first-names", firstNameRepository);
        repositories.put("surnames", surnameRepository);
    }

    public StatisticsDto statistics() {
        Map<String, Long> counts = new LinkedHashMap<>();
        repositories.forEach((name, repository) -> counts.put(name, repository.count()));
        return new StatisticsDto(counts, voterRepository.countByOpenRegisterTrue(), citizenRepository.countByDiedIsNull(),
                citizenRepository.countByGender("M"), citizenRepository.countByGender("F"));
    }
}
