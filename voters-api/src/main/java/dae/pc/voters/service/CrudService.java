package dae.pc.voters.service;

import dae.pc.voters.repository.BaseRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

/**
 * Create, read, update, delete and filtered list operations for an entity, exchanged with clients as a DTO.
 * Subclasses map between the entity and the DTO and define the list filters.
 *
 * @param <E>  the entity
 * @param <D>  the DTO
 * @param <ID> the entity's id type
 */
@Transactional
public abstract class CrudService<E, D, ID> {

    protected final BaseRepository<E, ID> repository;
    private final String resourceName;

    protected CrudService(BaseRepository<E, ID> repository, String resourceName) {
        this.repository = repository;
        this.resourceName = resourceName;
    }

    /** Converts an entity to its DTO. */
    protected abstract D toDto(E entity);

    /** A new, empty entity. */
    protected abstract E newEntity();

    /** Copies the DTO's writable fields to the entity, resolving references to other entities. */
    protected abstract void apply(D dto, E entity);

    /** The list filters for the request's query parameters, all records by default. */
    protected Specification<E> filter(Filters<E> filters) {
        return filters.build();
    }

    /** The list order if the request does not give one. */
    protected Sort defaultSort() {
        return Sort.by("id");
    }

    @Transactional(readOnly = true)
    public Page<D> list(Map<String, String> params, Pageable pageable) {
        if (pageable.getSort().isUnsorted()) {
            pageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), defaultSort());
        }
        return repository.findAll(filter(new Filters<>(params)), pageable).map(this::toDto);
    }

    @Transactional(readOnly = true)
    public D get(ID id) {
        return toDto(find(id));
    }

    public D create(D dto) {
        E entity = newEntity();
        apply(dto, entity);
        return toDto(repository.saveAndFlush(entity));
    }

    public D update(ID id, D dto) {
        E entity = find(id);
        apply(dto, entity);
        return toDto(repository.saveAndFlush(entity));
    }

    /**
     * Deletes the record, the database rejects it with a conflict if other records reference it.
     */
    public void delete(ID id) {
        repository.delete(find(id));
        repository.flush();
    }

    public String getResourceName() {
        return resourceName;
    }

    protected E find(ID id) {
        return repository.findById(id).orElseThrow(() -> new NotFoundException(resourceName, id));
    }

    /**
     * The referenced entity, null if the id is null, a bad request if it does not exist.
     */
    protected static <T, K> T reference(JpaRepository<T, K> repository, K id, String name) {
        if (id == null) {
            return null;
        }
        return repository.findById(id).orElseThrow(() -> new BadRequestException(name + " " + id + " does not exist"));
    }
}
