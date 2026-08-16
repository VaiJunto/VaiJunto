package com.vaijunto.dto;

import com.vaijunto.domain.enums.PassengerStatus;
import lombok.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TripPassengerDto {
    private UUID id;
    private UUID tripInstanceId;
    private UUID passengerId;
    private String passengerName;
    private PassengerStatus status;
    private OffsetDateTime checkedInAt;
    private UUID demandId;
    private String cancellationReason;
}
