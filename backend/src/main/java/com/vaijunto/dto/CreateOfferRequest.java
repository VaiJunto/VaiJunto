package com.vaijunto.dto;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Cria a rota e a oferta juntas — ainda não existe um fluxo separado de
 * cadastro de rotas, então o motorista publica as duas de uma vez.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateOfferRequest {
    private String routeName;
    private String originName;
    private LocationDto originLocation;
    private String destinationName;
    private LocationDto destinationLocation;
    private LocalTime departureTime;
    private Integer[] daysOfWeek;
    private Boolean isRecurrent;
    private UUID vehicleId;
    private Integer availableSeats;
    private BigDecimal price;
    private OffsetDateTime departureAt;
}
