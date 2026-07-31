package com.vaijunto.service;

import com.vaijunto.domain.entities.Offer;
import com.vaijunto.domain.entities.TripInstance;
import com.vaijunto.domain.entities.TripPassenger;
import com.vaijunto.domain.entities.User;
import com.vaijunto.domain.enums.PassengerStatus;
import com.vaijunto.domain.enums.TripStatus;
import com.vaijunto.dto.TripInstanceDto;
import com.vaijunto.dto.TripPassengerDto;
import com.vaijunto.repository.OfferRepository;
import com.vaijunto.repository.TripInstanceRepository;
import com.vaijunto.repository.TripPassengerRepository;
import com.vaijunto.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TripService {

    private final TripInstanceRepository tripRepository;
    private final TripPassengerRepository passengerRepository;
    private final OfferRepository offerRepository;
    private final UserRepository userRepository;

    @Transactional
    public TripInstanceDto createTripFromOffer(UUID offerId) {
        Offer offer = offerRepository.findById(offerId)
                .orElseThrow(() -> new IllegalArgumentException("Oferta não encontrada"));

        TripInstance trip = TripInstance.builder()
                .offer(offer)
                .route(offer.getRoute())
                .driver(offer.getDriver())
                .scheduledDeparture(offer.getDepartureAt())
                .status(TripStatus.SCHEDULED)
                .build();

        return mapToTripDto(tripRepository.save(trip));
    }

    @Transactional
    public TripPassengerDto requestSeat(UUID tripId, UUID passengerId) {
        TripInstance trip = tripRepository.findById(tripId)
                .orElseThrow(() -> new IllegalArgumentException("Viagem não encontrada"));

        User passenger = userRepository.findById(passengerId)
                .orElseThrow(() -> new IllegalArgumentException("Passageiro não encontrado"));

        TripPassenger tripPassenger = TripPassenger.builder()
                .tripInstance(trip)
                .passenger(passenger)
                .status(PassengerStatus.REQUESTED)
                .build();

        return mapToPassengerDto(passengerRepository.save(tripPassenger));
    }

    @Transactional
    public void performCheckIn(UUID tripId, UUID passengerId, boolean isAttending) {
        TripPassenger tp = passengerRepository.findByTripInstanceIdAndPassengerId(tripId, passengerId)
                .orElseThrow(() -> new IllegalArgumentException("Vínculo de passageiro não encontrado"));

        if (isAttending) {
            tp.setStatus(PassengerStatus.CHECKED_IN);
            tp.setCheckedInAt(OffsetDateTime.now());
        } else {
            tp.setStatus(PassengerStatus.ABSENT);
        }

        passengerRepository.save(tp);
    }

    public List<TripPassengerDto> getTripPassengers(UUID tripId) {
        return passengerRepository.findByTripInstanceId(tripId).stream()
                .map(this::mapToPassengerDto)
                .collect(Collectors.toList());
    }

    private TripInstanceDto mapToTripDto(TripInstance trip) {
        return TripInstanceDto.builder()
                .id(trip.getId())
                .offerId(trip.getOffer() != null ? trip.getOffer().getId() : null)
                .routeId(trip.getRoute() != null ? trip.getRoute().getId() : null)
                .driverId(trip.getDriver().getId())
                .scheduledDeparture(trip.getScheduledDeparture())
                .status(trip.getStatus())
                .build();
    }

    private TripPassengerDto mapToPassengerDto(TripPassenger tp) {
        return TripPassengerDto.builder()
                .id(tp.getId())
                .tripInstanceId(tp.getTripInstance().getId())
                .passengerId(tp.getPassenger().getId())
                .passengerName(tp.getPassenger().getName())
                .status(tp.getStatus())
                .checkedInAt(tp.getCheckedInAt())
                .build();
    }
}
