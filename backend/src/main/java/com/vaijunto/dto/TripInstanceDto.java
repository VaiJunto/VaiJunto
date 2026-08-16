package com.vaijunto.dto;

import com.vaijunto.domain.enums.TripStatus;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TripInstanceDto {
    private UUID id;
    private UUID offerId;
    private UUID routeId;
    private UUID driverId;
    private OffsetDateTime scheduledDeparture;
    private OffsetDateTime actualStart;
    private OffsetDateTime actualEnd;
    private String finishReason;
    private TripStatus status;
}
