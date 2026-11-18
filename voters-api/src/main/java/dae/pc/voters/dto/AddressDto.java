package dae.pc.voters.dto;

import jakarta.validation.constraints.*;

/**
 * An address. The place, country and constituency names are read-only. The constituency is the address's
 * constituency_id or, if that is not set, the postcode's constituency.
 */
public record AddressDto(
        Integer id,
        @NotBlank String address,
        Integer placeId,
        String placeName,
        @NotBlank @Size(max = 10) String postcode,
        Integer constituencyId,
        String constituencyName,
        Integer countryId,
        String countryName
) {
}
