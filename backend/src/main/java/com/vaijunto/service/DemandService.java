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
    private final RealtimeEventPublisher realtimeEvents;

    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    @Transactional(readOnly = true)
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

        if (request.getDesiredTime() == null || request.getDesiredTime().isBefore(OffsetDateTime.now())) throw new IllegalArgumentException("Informe uma data e horário futuros.");
        if (!hasFatecEndpoint(request.getOriginName(), request.getDestinationName())) throw new IllegalArgumentException("A Fatec deve ser origem ou destino do pedido.");
        Demand demand = Demand.builder()
                .passenger(passenger)
                .originName(request.getOriginName())
                .originLocation(toPoint(request.getOriginLocation()))
                .destinationName(request.getDestinationName())
                .destinationLocation(toPoint(request.getDestinationLocation()))
                .desiredTime(request.getDesiredTime())
                .build();

        Demand saved = demandRepository.save(demand);
        realtimeEvents.afterCommit(allUserEmails(), com.vaijunto.dto.RealtimeEventDto.create(
                "DEMAND_CREATED", "DEMAND", saved.getId(), java.util.Map.of("demandId", saved.getId().toString())));
        return mapToDto(saved);
    }
    @Transactional(readOnly = true)
    public List<DemandDto> findMine(String email) {
        User user = userRepository.findByEmail(email).orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado"));
        return demandRepository.findByPassengerIdOrderByDesiredTimeAsc(user.getId()).stream().map(this::mapToDto).collect(Collectors.toList());
    }
    @Transactional(readOnly = true)
    public com.vaijunto.dto.PageResponse<DemandDto> browse(int page, int size) {
        int safeSize = Math.min(Math.max(size, 1), 50);
        var result = demandRepository.findByStatusAndDesiredTimeAfterOrderByDesiredTimeAsc(com.vaijunto.domain.enums.DemandStatus.OPEN, OffsetDateTime.now(), org.springframework.data.domain.PageRequest.of(Math.max(page, 0), safeSize));
        return com.vaijunto.dto.PageResponse.from(result.map(this::mapToDto));
    }

    @Transactional
    public DemandDto updateDemand(java.util.UUID id, CreateDemandRequest request, String email) {
        Demand demand = owned(id, email);
        if (demand.getStatus() != com.vaijunto.domain.enums.DemandStatus.OPEN) throw new IllegalArgumentException("Este pedido não pode mais ser alterado.");
        if (request.getDesiredTime() == null || request.getDesiredTime().isBefore(OffsetDateTime.now())) throw new IllegalArgumentException("Informe uma data e horário futuros.");
        if (!hasFatecEndpoint(request.getOriginName(), request.getDestinationName())) throw new IllegalArgumentException("A Fatec deve ser origem ou destino do pedido.");
        demand.setOriginName(request.getOriginName()); demand.setOriginLocation(toPoint(request.getOriginLocation())); demand.setDestinationName(request.getDestinationName()); demand.setDestinationLocation(toPoint(request.getDestinationLocation())); demand.setDesiredTime(request.getDesiredTime());
        return mapToDto(demand);
    }
    @Transactional public void cancelDemand(java.util.UUID id, String email) { Demand d = owned(id, email); if (d.getStatus() != com.vaijunto.domain.enums.DemandStatus.OPEN) throw new IllegalArgumentException("Use o fluxo de cancelamento da carona aceita."); d.setStatus(com.vaijunto.domain.enums.DemandStatus.CANCELLED); realtimeEvents.afterCommit(allUserEmails(), com.vaijunto.dto.RealtimeEventDto.create("DEMAND_CANCELLED", "DEMAND", d.getId(), java.util.Map.of("demandId", d.getId().toString()))); }
    private java.util.List<String> allUserEmails() { return userRepository.findAll().stream().map(User::getEmail).filter(java.util.Objects::nonNull).toList(); }
    private Demand owned(java.util.UUID id, String email) { Demand d = demandRepository.findById(id).orElseThrow(() -> new IllegalArgumentException("Pedido não encontrado")); if (!d.getPassenger().getEmail().equals(email)) throw new org.springframework.security.access.AccessDeniedException("Sem permissão para alterar este pedido."); return d; }
    private boolean hasFatecEndpoint(String origin, String destination) { return (origin != null && origin.toUpperCase().contains("FATEC")) || (destination != null && destination.toUpperCase().contains("FATEC")); }

    private Point toPoint(LocationDto location) {
        return geometryFactory.createPoint(new Coordinate(location.getLongitude(), location.getLatitude()));
    }

    private DemandDto mapToDto(Demand demand) {
        return DemandDto.builder()
                .id(demand.getId())
                .passengerId(demand.getPassenger().getId())
                .passengerName(demand.getPassenger().getName())
                .originName(publicRegion(demand.getOriginName()))
                .originLocation(null)
                .destinationName(publicRegion(demand.getDestinationName()))
                .destinationLocation(null)
                .desiredTime(demand.getDesiredTime())
                .status(demand.getStatus())
                .build();
    }
    private String publicRegion(String value) { return value != null && value.toUpperCase().contains("FATEC") ? "FATEC" : "Região aproximada"; }
}
