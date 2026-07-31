package com.vaijunto.controller;

import com.vaijunto.dto.TripInstanceDto;
import com.vaijunto.dto.TripPassengerDto;
import com.vaijunto.service.TripService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/trips")
@RequiredArgsConstructor
public class TripController {

    private final TripService tripService;

    @PostMapping("/from-offer/{offerId}")
    public ResponseEntity<TripInstanceDto> createTripFromOffer(@PathVariable UUID offerId) {
        TripInstanceDto trip = tripService.createTripFromOffer(offerId);
        return ResponseEntity.status(HttpStatus.CREATED).body(trip);
    }

    @PostMapping("/{tripId}/request-seat")
    public ResponseEntity<TripPassengerDto> requestSeat(
            @PathVariable UUID tripId,
            @RequestParam UUID passengerId) {
        TripPassengerDto request = tripService.requestSeat(tripId, passengerId);
        return ResponseEntity.status(HttpStatus.CREATED).body(request);
    }

    @PostMapping("/{tripId}/checkin")
    public ResponseEntity<Void> performCheckIn(
            @PathVariable UUID tripId,
            @RequestParam UUID passengerId,
            @RequestParam boolean isAttending) {
        tripService.performCheckIn(tripId, passengerId, isAttending);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/{tripId}/passengers")
    public ResponseEntity<List<TripPassengerDto>> getTripPassengers(@PathVariable UUID tripId) {
        return ResponseEntity.ok(tripService.getTripPassengers(tripId));
    }
}
