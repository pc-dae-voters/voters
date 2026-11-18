package dae.pc.voters.controller;

import dae.pc.voters.dto.AddressDto;
import dae.pc.voters.service.AddressService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for addresses, see CrudController and AddressService for the list filters.
 */
@RestController
@RequestMapping("/api/addresses")
public class AddressController extends CrudController<AddressDto, Integer> {

    @Autowired
    public AddressController(AddressService service) {
        super(service);
    }
}
