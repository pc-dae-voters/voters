package dae.pc.voters.controller;

import dae.pc.voters.dto.PostcodeDto;
import dae.pc.voters.service.PostcodeService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST controller for postcodes' constituencies, see CrudController and PostcodeService for the list filters.
 */
@RestController
@RequestMapping("/api/postcodes")
public class PostcodeController extends CrudController<PostcodeDto, String> {

    @Autowired
    public PostcodeController(PostcodeService service) {
        super(service);
    }
}
