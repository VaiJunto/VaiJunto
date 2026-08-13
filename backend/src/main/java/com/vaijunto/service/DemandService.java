package com.vaijunto.service;

import com.vaijunto.domain.entities.Demand;
import com.vaijunto.domain.entities.User;
import com.vaijunto.dto.CreateDemandRequest;
import com.vaijunto.dto.DemandDto;
import com.vaijunto.dto.LocationDto;
import com.vaijunto.repository.DemandRepository;
import com.vaijunto.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DemandService {

    private final DemandRepository demandRepository;
    private final UserRepository userRepository;

    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    public List<DemandDto> findOpenDemandsNearOrigin(double lat, double lon, double distanceMeters) {
        List<Demand> demands = demandRepository.findOpenDemandsNearOrigin(
                lon, lat, distanceMeters, OffsetDateTime.now()
        );

        return demands.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public DemandDto createDemand(CreateDemandRequest request, String passengerEmail) {
        User passenger = userRepository.findByEmail(passengerEmail)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado"));

        Demand demand = Demand.builder()
                .passenger(passenger)
                .originName(request.getOriginName())
                .originLocation(toPoint(request.getOriginLocation()))
                .destinationName(request.getDestinationName())
                .destinationLocation(toPoint(request.getDestinationLocation()))
                .desiredTime(request.getDesiredTime())
                .build();

        return mapToDto(demandRepository.save(demand));
    }

    private Point toPoint(LocationDto location) {
        return geometryFactory.createPoint(new Coordinate(location.getLongitude(), location.getLatitude()));
    }

    private DemandDto mapToDto(Demand demand) {
        return DemandDto.builder()
                .id(demand.getId())
                .passengerId(demand.getPassenger().getId())
                .originName(demand.getOriginName())
                .originLocation(new LocationDto(demand.getOriginLocation().getY(), demand.getOriginLocation().getX()))
                .destinationName(demand.getDestinationName())
                .destinationLocation(new LocationDto(demand.getDestinationLocation().getY(), demand.getDestinationLocation().getX()))
                .desiredTime(demand.getDesiredTime())
                .status(demand.getStatus())
                .build();
    }
}
