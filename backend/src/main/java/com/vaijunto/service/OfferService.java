package com.vaijunto.service;

import com.vaijunto.domain.entities.Offer;
import com.vaijunto.dto.OfferDto;
import com.vaijunto.repository.OfferRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OfferService {

    private final OfferRepository offerRepository;

    public List<OfferDto> findActiveOffersNearOrigin(double lat, double lon, double distanceMeters) {
        List<Offer> offers = offerRepository.findActiveOffersNearOrigin(
                lon, lat, distanceMeters, OffsetDateTime.now()
        );

        return offers.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    private OfferDto mapToDto(Offer offer) {
        return OfferDto.builder()
                .id(offer.getId())
                .routeId(offer.getRoute() != null ? offer.getRoute().getId() : null)
                .driverId(offer.getDriver().getId())
                .availableSeats(offer.getAvailableSeats())
                .price(offer.getPrice())
                .departureAt(offer.getDepartureAt())
                .status(offer.getStatus())
                .build();
    }
}
