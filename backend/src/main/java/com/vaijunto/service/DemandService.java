package com.vaijunto.service;

import com.vaijunto.domain.entities.Demand;
import com.vaijunto.dto.DemandDto;
import com.vaijunto.dto.LocationDto;
import com.vaijunto.repository.DemandRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DemandService {

    private final DemandRepository demandRepository;

    public List<DemandDto> findOpenDemandsNearOrigin(double lat, double lon, double distanceMeters) {
        List<Demand> demands = demandRepository.findOpenDemandsNearOrigin(
                lon, lat, distanceMeters, OffsetDateTime.now()
        );

        return demands.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
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
