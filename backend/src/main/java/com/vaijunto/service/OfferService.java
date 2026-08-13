package com.vaijunto.service;

import com.vaijunto.domain.entities.Offer;
import com.vaijunto.domain.entities.Route;
import com.vaijunto.domain.entities.User;
import com.vaijunto.domain.entities.Vehicle;
import com.vaijunto.dto.CreateOfferRequest;
import com.vaijunto.dto.LocationDto;
import com.vaijunto.dto.OfferDto;
import com.vaijunto.repository.OfferRepository;
import com.vaijunto.repository.RouteRepository;
import com.vaijunto.repository.UserRepository;
import com.vaijunto.repository.VehicleRepository;
import lombok.RequiredArgsConstructor;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class OfferService {

    private final OfferRepository offerRepository;
    private final RouteRepository routeRepository;
    private final UserRepository userRepository;
    private final VehicleRepository vehicleRepository;

    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    public List<OfferDto> findActiveOffersNearOrigin(double lat, double lon, double distanceMeters) {
        List<Offer> offers = offerRepository.findActiveOffersNearOrigin(
                lon, lat, distanceMeters, OffsetDateTime.now()
        );

        return offers.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public OfferDto createOffer(CreateOfferRequest request, String driverEmail) {
        User driver = userRepository.findByEmail(driverEmail)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado"));

        Vehicle vehicle = null;
        if (request.getVehicleId() != null) {
            vehicle = vehicleRepository.findById(request.getVehicleId())
                    .orElseThrow(() -> new IllegalArgumentException("Veículo não encontrado"));
        }

        Route route = Route.builder()
                .driver(driver)
                .vehicle(vehicle)
                .name(request.getRouteName())
                .originName(request.getOriginName())
                .originLocation(toPoint(request.getOriginLocation()))
                .destinationName(request.getDestinationName())
                .destinationLocation(toPoint(request.getDestinationLocation()))
                .departureTime(request.getDepartureTime())
                .daysOfWeek(request.getDaysOfWeek())
                .isRecurrent(request.getIsRecurrent() != null ? request.getIsRecurrent() : true)
                .build();
        route = routeRepository.save(route);

        Offer offer = Offer.builder()
                .route(route)
                .driver(driver)
                .availableSeats(request.getAvailableSeats())
                .price(request.getPrice() != null ? request.getPrice() : BigDecimal.ZERO)
                .departureAt(request.getDepartureAt())
                .build();

        return mapToDto(offerRepository.save(offer));
    }

    private Point toPoint(LocationDto location) {
        return geometryFactory.createPoint(new Coordinate(location.getLongitude(), location.getLatitude()));
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
