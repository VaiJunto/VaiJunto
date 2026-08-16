package com.vaijunto.dto;
import lombok.Data; import java.math.BigDecimal; import java.time.OffsetDateTime; import java.util.UUID;
@Data public class UpdateOfferRequest { private String originName; private String destinationName; private OffsetDateTime departureAt; private UUID vehicleId; private Integer availableSeats; private BigDecimal price; }
