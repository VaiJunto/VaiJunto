package com.vaijunto.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GeocodingResultDto {
    private String displayName;
    private double latitude;
    private double longitude;
}
