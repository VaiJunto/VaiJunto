package com.vaijunto.dto;

import com.vaijunto.domain.enums.OfferStatus;
import lombok.*;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OfferDto {
    private UUID id;
    private UUID routeId;
    private UUID driverId;
    private Integer availableSeats;
    private BigDecimal price;
    private OffsetDateTime departureAt;
    private OfferStatus status;
}
