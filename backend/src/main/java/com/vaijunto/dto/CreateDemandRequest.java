package com.vaijunto.dto;

import lombok.*;

import java.time.OffsetDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateDemandRequest {
    private String originName;
    private LocationDto originLocation;
    private String destinationName;
    private LocationDto destinationLocation;
    private OffsetDateTime desiredTime;
}
