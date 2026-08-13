package com.vaijunto.dto;

import com.vaijunto.domain.enums.DemandStatus;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DemandDto {
    private UUID id;
    private UUID passengerId;
    private String passengerName;
    private String originName;
    private LocationDto originLocation;
    private String destinationName;
    private LocationDto destinationLocation;
    private OffsetDateTime desiredTime;
    private DemandStatus status;
}
