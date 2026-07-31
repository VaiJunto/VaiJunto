package com.vaijunto.dto;

import lombok.*;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GpsLocationMessage {
    private UUID tripInstanceId;
    private double latitude;
    private double longitude;
    private Double speed;
    private Double heading;
    private String timestamp;
}
