package dae.pc.voters.controller;

import dae.pc.voters.service.CrudService;
import io.swagger.v3.oas.annotations.Parameter;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * REST operations for a resource:
 * <ul>
 *   <li>GET /api/&lt;resource&gt;?page=0&amp;size=20&amp;sort=name,asc&amp;&lt;filter&gt;=&lt;value&gt; - a page of records,
 *   the filters are described on each resource's service</li>
 *   <li>GET /api/&lt;resource&gt;/{id} - a record</li>
 *   <li>POST /api/&lt;resource&gt; - create a record, returns it with its id</li>
 *   <li>PUT /api/&lt;resource&gt;/{id} - replace a record's fields</li>
 *   <li>DELETE /api/&lt;resource&gt;/{id} - delete a record, 409 Conflict if other records reference it</li>
 * </ul>
 */
@CrossOrigin(origins = "*")
public abstract class CrudController<D, ID> {

    protected final CrudService<?, D, ID> service;

    protected CrudController(CrudService<?, D, ID> service) {
        this.service = service;
    }

    @GetMapping
    public Page<D> list(@Parameter(hidden = true) @RequestParam Map<String, String> params,
                        @PageableDefault(size = 20) Pageable pageable) {
        return service.list(params, pageable);
    }

    @GetMapping("/{id}")
    public D get(@PathVariable ID id) {
        return service.get(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public D create(@Valid @RequestBody D dto) {
        return service.create(dto);
    }

    @PutMapping("/{id}")
    public D update(@PathVariable ID id, @Valid @RequestBody D dto) {
        return service.update(id, dto);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable ID id) {
        service.delete(id);
    }
}
