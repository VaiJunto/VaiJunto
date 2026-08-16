package com.vaijunto.controller;

import com.vaijunto.dto.*;
import com.vaijunto.service.TripService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/trips")
@RequiredArgsConstructor
public class TripController {
    private final TripService tripService;

    @PostMapping("/from-offer/{offerId}")
    public ResponseEntity<TripInstanceDto> createTripFromOffer(@PathVariable UUID offerId) { return ResponseEntity.status(HttpStatus.CREATED).body(tripService.createTripFromOffer(offerId)); }

    /** Passageiro autenticado pede exatamente uma vaga; nunca aceita um id de usuário do cliente. */
    @PostMapping("/offers/{offerId}/requests")
    public ResponseEntity<TripPassengerDto> requestSeat(@PathVariable UUID offerId, Authentication authentication) { return ResponseEntity.status(HttpStatus.CREATED).body(tripService.requestSeatForOffer(offerId, authentication.getName())); }
    @PostMapping("/demands/{demandId}/proposals")
    public ResponseEntity<TripPassengerDto> propose(@PathVariable UUID demandId, Authentication authentication) { return ResponseEntity.status(HttpStatus.CREATED).body(tripService.propose(demandId, authentication.getName())); }
    @PostMapping("/participants/{id}/accept") public TripPassengerDto accept(@PathVariable UUID id, Authentication auth) { return tripService.accept(id, auth.getName()); }
    @PostMapping("/participants/{id}/decline") public TripPassengerDto decline(@PathVariable UUID id, Authentication auth) { return tripService.decline(id, auth.getName()); }
    @PostMapping("/participants/{id}/withdraw") public TripPassengerDto withdraw(@PathVariable UUID id, Authentication auth) { return tripService.withdrawProposal(id, auth.getName()); }
    @PostMapping("/participants/{id}/cancel") public TripPassengerDto cancel(@PathVariable UUID id, @Valid @RequestBody(required=false) CancelParticipationRequest request, Authentication auth) { return tripService.cancel(id, request == null ? new CancelParticipationRequest(null, null) : request, auth.getName()); }
    @PostMapping("/{tripId}/checkin") public ResponseEntity<Void> checkIn(@PathVariable UUID tripId, @RequestParam UUID passengerId, @RequestParam boolean isAttending) { tripService.performCheckIn(tripId, passengerId, isAttending); return ResponseEntity.ok().build(); }
    @PostMapping("/{tripId}/start") public TripInstanceDto start(@PathVariable UUID tripId, @RequestBody(required=false) StartTripRequest request, Authentication auth) { return tripService.start(tripId, request, auth.getName()); }
    @PostMapping("/{tripId}/finish") public TripInstanceDto finish(@PathVariable UUID tripId, @RequestBody(required=false) FinishTripRequest request, Authentication auth) { return tripService.finish(tripId, request, auth.getName()); }
    @PostMapping("/{tripId}/destination-presence") public void destinationPresence(@PathVariable UUID tripId, @RequestParam double latitude, @RequestParam double longitude, Authentication auth) { tripService.destinationPresence(tripId, latitude, longitude, auth.getName()); }
    @PostMapping("/participants/{id}/absence-contest") public TripPassengerDto contestAbsence(@PathVariable UUID id, @RequestParam String explanation, Authentication auth) { return tripService.contestAbsence(id, explanation, auth.getName()); }
    @PostMapping("/{tripId}/reviews") public void review(@PathVariable UUID tripId, @Valid @RequestBody ReviewRideRequest request, Authentication auth) { tripService.review(tripId, request, auth.getName()); }
    @GetMapping("/{tripId}/passengers") public List<TripPassengerDto> passengers(@PathVariable UUID tripId, Authentication auth) { return tripService.getTripPassengers(tripId, auth.getName()); }
    @GetMapping("/mine") public List<TripInstanceDto> mine(Authentication auth) { return tripService.mine(auth.getName()); }
}
