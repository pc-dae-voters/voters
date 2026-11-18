package dae.pc.voters.controller;

import dae.pc.voters.dto.PlaceDto;
import dae.pc.voters.service.PlaceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for places, see CrudController and PlaceService for the list filters.
 */
@RestController
@RequestMapping("/api/places")
public class PlaceController extends CrudController<PlaceDto, Integer> {

    @Autowired
    public PlaceController(PlaceService service) {
        super(service);
    }
}
