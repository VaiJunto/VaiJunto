package com.vaijunto.service;

import com.vaijunto.domain.entities.Offer;
import com.vaijunto.domain.entities.Route;
import com.vaijunto.domain.entities.User;
import com.vaijunto.domain.entities.Vehicle;
import com.vaijunto.dto.CreateOfferRequest;
import com.vaijunto.dto.LocationDto;
import com.vaijunto.dto.OfferDto;
import com.vaijunto.dto.UpdateOfferRequest;
import com.vaijunto.dto.CancelOfferRequest;
import com.vaijunto.domain.enums.*;
import com.vaijunto.repository.OfferRepository;
import com.vaijunto.repository.RouteRepository;
import com.vaijunto.repository.UserRepository;
import com.vaijunto.repository.VehicleRepository;
import com.vaijunto.repository.TripPassengerRepository;
import com.vaijunto.repository.TripInstanceRepository;
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
    private final TripPassengerRepository passengers;
    private final TripInstanceRepository trips;
    private final NotificationService notifications;
    private final BlockService blocks;
    private final RealtimeEventPublisher realtimeEvents;

    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    @Transactional
    public List<OfferDto> findActiveOffersNearOrigin(double lat, double lon, double distanceMeters, String email) {
        User viewer = userRepository.findByEmail(email).orElseThrow();
        List<Offer> offers = offerRepository.findActiveOffersNearOrigin(
                lon, lat, distanceMeters, OffsetDateTime.now()
        );

        offers.forEach(this::advanceRecurrence);
        return offers.stream()
                .filter(o -> !blocks.blocked(viewer.getId(), o.getDriver().getId())).map(this::mapToDto)
                .collect(Collectors.toList());
    }

    @Transactional
    public OfferDto createOffer(CreateOfferRequest request, String driverEmail) {
        User driver = userRepository.findByEmail(driverEmail)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado"));

        if (request.getAvailableSeats() == null || request.getAvailableSeats() < 1) throw new IllegalArgumentException("Informe ao menos uma vaga.");
        boolean recurrent = Boolean.TRUE.equals(request.getIsRecurrent());
        if (recurrent) {
            validateRecurrence(request);
            request.setDepartureAt(nextOccurrence(request.getDepartureTime(), request.getDaysOfWeek(), OffsetDateTime.now()));
        }
        if (request.getDepartureAt() == null || !request.getDepartureAt().isAfter(OffsetDateTime.now())) throw new IllegalArgumentException("Informe um horário futuro.");
        if (!hasFatecEndpoint(request.getOriginName(), request.getDestinationName())) throw new IllegalArgumentException("A Fatec deve ser origem ou destino da carona.");
        Vehicle vehicle = null;
        if (request.getVehicleId() != null) {
            vehicle = vehicleRepository.findById(request.getVehicleId())
                    .orElseThrow(() -> new IllegalArgumentException("Veículo não encontrado"));
            if (!vehicle.getDriver().getId().equals(driver.getId()) || vehicle.getArchivedAt() != null) {
                throw new IllegalArgumentException("Veículo não encontrado");
            }
        } else {
            vehicle = vehicleRepository.findByDriverIdAndArchivedAtIsNullOrderByIsDefaultDescCreatedAtDesc(driver.getId())
                    .stream().findFirst().orElseThrow(() -> new IllegalArgumentException("Cadastre um veículo antes de oferecer uma carona."));
        }
        if (request.getAvailableSeats() > vehicle.getCapacity()) throw new IllegalArgumentException("As vagas não podem exceder a capacidade do veículo.");
        if (offerRepository.existsOverlappingOffer(driver.getId(), request.getDepartureAt().minusMinutes(90), request.getDepartureAt().plusMinutes(90))) throw new IllegalArgumentException("Você já possui uma oferta em horário sobreposto.");
        BigDecimal requestedPrice = request.getPrice() == null ? BigDecimal.ZERO : request.getPrice();
        BigDecimal assistanceLimit = assistanceLimit(request, vehicle);
        if (requestedPrice.compareTo(assistanceLimit) > 0) requestedPrice = assistanceLimit;

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
                .isRecurrent(recurrent)
                .build();
        route = routeRepository.save(route);

        Offer offer = Offer.builder()
                .route(route)
                .driver(driver)
                .availableSeats(request.getAvailableSeats())
                .price(requestedPrice)
                .departureAt(request.getDepartureAt())
                .build();

        Offer saved = offerRepository.save(offer);
        realtimeEvents.afterCommit(allUserEmails(), com.vaijunto.dto.RealtimeEventDto.create(
                "OFFER_CREATED", "OFFER", saved.getId(), java.util.Map.of("offerId", saved.getId().toString())));
        return mapToDto(saved);
    }

    private Point toPoint(LocationDto location) {
        if (location == null) throw new IllegalArgumentException("Informe os dois pontos da rota.");
        return geometryFactory.createPoint(new Coordinate(location.getLongitude(), location.getLatitude()));
    }

    @Transactional
    public List<OfferDto> findMine(String email) {
        User user = userRepository.findByEmail(email).orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado"));
        var mine = offerRepository.findByDriverIdOrderByDepartureAtAsc(user.getId());
        mine.forEach(this::advanceRecurrence);
        return mine.stream().map(o -> mapToDto(o, true)).collect(Collectors.toList());
    }

    @Transactional
    public com.vaijunto.dto.PageResponse<OfferDto> browse(int page, int size, String email) {
        User viewer = userRepository.findByEmail(email).orElseThrow();
        int safeSize = Math.min(Math.max(size, 1), 50);
        var result = offerRepository.findByStatusInAndDepartureAtAfterOrderByDepartureAtAsc(List.of(com.vaijunto.domain.enums.OfferStatus.ACTIVE, com.vaijunto.domain.enums.OfferStatus.FULL), OffsetDateTime.now(), org.springframework.data.domain.PageRequest.of(Math.max(page, 0), safeSize));
        result.forEach(this::advanceRecurrence);
        var visible = result.stream().filter(o -> !blocks.blocked(viewer.getId(), o.getDriver().getId())).toList();
        return new com.vaijunto.dto.PageResponse<>(visible.stream().map(this::mapToDto).toList(), result.getNumber(), result.getSize(), visible.size(), result.getTotalPages(), result.hasNext());
    }

    @Transactional public OfferDto update(java.util.UUID id, UpdateOfferRequest request, String email) {
        Offer offer = offerRepository.findByIdForUpdate(id).orElseThrow(() -> new IllegalArgumentException("Oferta não encontrada."));
        if (!offer.getDriver().getEmail().equals(email)) throw new org.springframework.security.access.AccessDeniedException("Oferta de outro motorista.");
        OffsetDateTime now=OffsetDateTime.now(); if (!offer.getDepartureAt().isAfter(now.plusHours(1))) throw new IllegalStateException("Na última hora, cancele a oferta com um motivo.");
        boolean reconfirm = (request.getDepartureAt()!=null && !request.getDepartureAt().equals(offer.getDepartureAt())) || request.getVehicleId()!=null || (request.getPrice()!=null && request.getPrice().compareTo(offer.getPrice())>0) || request.getOriginName()!=null || request.getDestinationName()!=null;
        if (reconfirm && !offer.getDepartureAt().isAfter(now.plusHours(3))) throw new IllegalStateException("Mudanças que exigem reconfirmação fecham 3 horas antes.");
        int accepted=(int)passengers.findByTripInstanceId(tripFor(offer).getId()).stream().filter(p->p.getStatus()==PassengerStatus.CONFIRMED||p.getStatus()==PassengerStatus.CHECKED_IN).count();
        if(request.getAvailableSeats()!=null){if(request.getAvailableSeats()<accepted)throw new IllegalArgumentException("Não reduza vagas abaixo das pessoas aceitas.");offer.setAvailableSeats(request.getAvailableSeats()-accepted);}
        if(request.getDepartureAt()!=null)offer.setDepartureAt(request.getDepartureAt()); if(request.getPrice()!=null)offer.setPrice(request.getPrice());
        if(request.getVehicleId()!=null){Vehicle vehicle=vehicleRepository.findById(request.getVehicleId()).orElseThrow(()->new IllegalArgumentException("Veículo não encontrado."));if(!vehicle.getDriver().getId().equals(offer.getDriver().getId()))throw new IllegalArgumentException("Veículo inválido.");offer.getRoute().setVehicle(vehicle);}
        if(request.getOriginName()!=null)offer.getRoute().setOriginName(request.getOriginName());if(request.getDestinationName()!=null)offer.getRoute().setDestinationName(request.getDestinationName());
        if(reconfirm)passengers.findByTripInstanceId(tripFor(offer).getId()).stream().filter(p->p.getStatus()==PassengerStatus.CONFIRMED).forEach(p->{p.setStatus(PassengerStatus.REQUESTED);notifications.createAndSendNotification(p.getPassenger().getId(),"Mudança na carona","Confirme novamente sua participação até uma hora antes.","RIDE_RECONFIRM",json(tripFor(offer).getId()),null);});
        return mapToDto(offer);
    }
    @Transactional public void cancel(java.util.UUID id, CancelOfferRequest request, String email) { Offer offer=offerRepository.findByIdForUpdate(id).orElseThrow(()->new IllegalArgumentException("Oferta não encontrada."));if(!offer.getDriver().getEmail().equals(email))throw new org.springframework.security.access.AccessDeniedException("Oferta de outro motorista."); if(!java.util.Set.of("IMPREVISTO_PESSOAL","VEICULO","SAUDE_EMERGENCIA","COMPROMISSO","SEGURANCA","OUTRO").contains(request.reason()))throw new IllegalArgumentException("Motivo inválido.");if("OUTRO".equals(request.reason())&&(request.note()==null||request.note().isBlank()))throw new IllegalArgumentException("Explique o motivo OUTRO.");offer.setStatus(OfferStatus.CANCELLED);var trip=tripFor(offer);trip.setStatus(TripStatus.CANCELLED);passengers.findByTripInstanceId(trip.getId()).forEach(p->{if(p.getStatus()==PassengerStatus.CONFIRMED||p.getStatus()==PassengerStatus.REQUESTED){p.setStatus(PassengerStatus.CANCELLED);notifications.createAndSendNotification(p.getPassenger().getId(),"Carona cancelada","O motorista cancelou: "+request.reason(),"RIDE_OFFER_CANCELLED",json(trip.getId()),null);}}); }
    private com.vaijunto.domain.entities.TripInstance tripFor(Offer offer){return trips.findByDriverId(offer.getDriver().getId()).stream().filter(t->t.getOffer()!=null&&t.getOffer().getId().equals(offer.getId())).findFirst().orElseGet(()->trips.save(com.vaijunto.domain.entities.TripInstance.builder().offer(offer).route(offer.getRoute()).driver(offer.getDriver()).scheduledDeparture(offer.getDepartureAt()).status(TripStatus.SCHEDULED).build()));}
    private String json(java.util.UUID id){return "{\\\"tripId\\\":\\\""+id+"\\\"}";}

    private boolean hasFatecEndpoint(String origin, String destination) {
        return (origin != null && origin.toUpperCase().contains("FATEC")) || (destination != null && destination.toUpperCase().contains("FATEC"));
    }

    private void validateRecurrence(CreateOfferRequest request) {
        if (request.getDepartureTime() == null) throw new IllegalArgumentException("Informe o horário da recorrência.");
        if (request.getDaysOfWeek() == null || request.getDaysOfWeek().length == 0) {
            throw new IllegalArgumentException("Escolha ao menos um dia da semana.");
        }
        if (java.util.Arrays.stream(request.getDaysOfWeek()).anyMatch(day -> day == null || day < 1 || day > 7)) {
            throw new IllegalArgumentException("Os dias da recorrência são inválidos.");
        }
    }

    private OffsetDateTime nextOccurrence(java.time.LocalTime time, Integer[] days, OffsetDateTime now) {
        var selected = java.util.Set.of(days);
        for (int offset = 0; offset <= 7; offset++) {
            var date = now.toLocalDate().plusDays(offset);
            var candidate = date.atTime(time).atOffset(now.getOffset());
            if (selected.contains(date.getDayOfWeek().getValue()) && candidate.isAfter(now)) return candidate;
        }
        throw new IllegalArgumentException("Não foi possível calcular a próxima ocorrência.");
    }

    private void advanceRecurrence(Offer offer) {
        Route route = offer.getRoute();
        if (route == null || !Boolean.TRUE.equals(route.getIsRecurrent()) ||
                offer.getDepartureAt().isAfter(OffsetDateTime.now())) return;
        offer.setDepartureAt(nextOccurrence(route.getDepartureTime(), route.getDaysOfWeek(), OffsetDateTime.now()));
    }

    private java.util.List<String> allUserEmails() {
        return userRepository.findAll().stream().map(User::getEmail)
                .filter(java.util.Objects::nonNull).toList();
    }

    private BigDecimal assistanceLimit(CreateOfferRequest request, Vehicle vehicle) {
        double km = request.getDistanceKm() != null && request.getDistanceKm() > 0 ? request.getDistanceKm() : straightLineKm(request.getOriginLocation(), request.getDestinationLocation()) * 1.25;
        double consumption = vehicle.getAverageConsumption() != null && vehicle.getAverageConsumption() > 0 ? vehicle.getAverageConsumption() : 10d;
        double total = (km * 1.10 / consumption) * 6.0;
        return BigDecimal.valueOf(total / (request.getAvailableSeats() + 1d)).setScale(2, java.math.RoundingMode.DOWN);
    }

    private double straightLineKm(LocationDto a, LocationDto b) {
        double dLat = Math.toRadians(b.getLatitude() - a.getLatitude()), dLon = Math.toRadians(b.getLongitude() - a.getLongitude());
        double h = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(Math.toRadians(a.getLatitude())) * Math.cos(Math.toRadians(b.getLatitude())) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return 6371d * 2d * Math.atan2(Math.sqrt(h), Math.sqrt(1d - h));
    }

    private OfferDto mapToDto(Offer offer) { return mapToDto(offer, false); }
    private OfferDto mapToDto(Offer offer, boolean owner) {
        return OfferDto.builder()
                .id(offer.getId())
                .routeId(offer.getRoute() != null ? offer.getRoute().getId() : null)
                .vehicleId(offer.getRoute() != null && offer.getRoute().getVehicle() != null ? offer.getRoute().getVehicle().getId() : null)
                .driverId(offer.getDriver().getId())
                .driverName(offer.getDriver().getName())
                .routeName(offer.getRoute() != null ? offer.getRoute().getName() : null)
                .originName(owner && offer.getRoute() != null ? offer.getRoute().getOriginName() : publicRegion(offer.getRoute() != null ? offer.getRoute().getOriginName() : null))
                .destinationName(owner && offer.getRoute() != null ? offer.getRoute().getDestinationName() : publicRegion(offer.getRoute() != null ? offer.getRoute().getDestinationName() : null))
                .originLocation(owner && offer.getRoute() != null ? new LocationDto(offer.getRoute().getOriginLocation().getY(), offer.getRoute().getOriginLocation().getX()) : null)
                .destinationLocation(owner && offer.getRoute() != null ? new LocationDto(offer.getRoute().getDestinationLocation().getY(), offer.getRoute().getDestinationLocation().getX()) : null)
                .availableSeats(offer.getAvailableSeats())
                .price(offer.getPrice())
                .departureAt(offer.getDepartureAt())
                .isRecurrent(offer.getRoute() != null && Boolean.TRUE.equals(offer.getRoute().getIsRecurrent()))
                .status(offer.getStatus())
                .build();
    }
    private String publicRegion(String value) { return value != null && value.toUpperCase().contains("FATEC") ? "FATEC" : "Região aproximada"; }
}
