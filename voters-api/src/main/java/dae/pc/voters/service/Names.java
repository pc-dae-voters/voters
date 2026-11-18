package dae.pc.voters.service;

import dae.pc.voters.entity.Citizen;
import dae.pc.voters.entity.FirstName;
import dae.pc.voters.entity.Surname;
import dae.pc.voters.repository.FirstNameRepository;
import dae.pc.voters.repository.SurnameRepository;
import jakarta.persistence.criteria.From;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Component;

import java.util.Arrays;
import java.util.function.Function;

/**
 * Resolves first names and surnames given by name or id, and matches citizens by name.
 */
@Component
public class Names {

    private final FirstNameRepository firstNameRepository;
    private final SurnameRepository surnameRepository;

    @Autowired
    public Names(FirstNameRepository firstNameRepository, SurnameRepository surnameRepository) {
        this.firstNameRepository = firstNameRepository;
        this.surnameRepository = surnameRepository;
    }

    /**
     * The first name, by name if given, adding it if it does not exist, otherwise by id, null if neither is given.
     */
    public FirstName firstName(Integer id, String name, String gender) {
        if (name != null && !name.isBlank()) {
            return firstNameRepository.findByNameIgnoreCase(name.trim()).orElseGet(() -> {
                FirstName firstName = new FirstName();
                firstName.setName(name.trim());
                firstName.setGender(gender);
                return firstNameRepository.save(firstName);
            });
        }
        return CrudService.reference(firstNameRepository, id, "First name");
    }

    /**
     * The surname, by name if given, adding it if it does not exist, otherwise by id, null if neither is given.
     */
    public Surname surname(Integer id, String name) {
        if (name != null && !name.isBlank()) {
            return surnameRepository.findByNameIgnoreCase(name.trim()).orElseGet(() -> {
                Surname surname = new Surname();
                surname.setName(name.trim());
                return surnameRepository.save(surname);
            });
        }
        return CrudService.reference(surnameRepository, id, "Surname");
    }

    /**
     * Matches citizens whose first name or surname contains each of the search's words, e.g. "jo smi" matches John
     * Smith.
     *
     * @param citizen the citizen, from the record being matched
     */
    public static <X> Specification<X> matching(String search, Function<Root<X>, From<?, Citizen>> citizen) {
        String[] words = search.trim().split("\\s+");
        return (root, query, cb) -> {
            From<?, Citizen> c = citizen.apply(root);
            var first = c.join("firstName", JoinType.LEFT);
            var last = c.join("surname", JoinType.LEFT);
            return cb.and(Arrays.stream(words)
                    .map(w -> cb.or(Filters.contains(cb, first.get("name"), w), Filters.contains(cb, last.get("name"), w)))
                    .toArray(Predicate[]::new));
        };
    }

    /**
     * The citizen's name, null if there is no citizen.
     */
    public static String of(Citizen citizen) {
        return citizen != null ? citizen.getFullName() : null;
    }
}
