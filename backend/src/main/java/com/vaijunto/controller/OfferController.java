package com.vaijunto.controller;

import com.vaijunto.dto.CreateOfferRequest;
import com.vaijunto.dto.OfferDto;
import com.vaijunto.service.OfferService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/offers")
@RequiredArgsConstructor
public class OfferController {

    private final OfferService offerService;

    @GetMapping("/mine") public List<OfferDto> mine(Authentication authentication) { return offerService.findMine(authentication.getName()); }
    @GetMapping public com.vaijunto.dto.PageResponse<OfferDto> browse(@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size, Authentication authentication) { return offerService.browse(page, size, authentication.getName()); }
    @PatchMapping("/{id}") public OfferDto update(@PathVariable java.util.UUID id, @RequestBody com.vaijunto.dto.UpdateOfferRequest request, Authentication authentication) { return offerService.update(id, request, authentication.getName()); }
    @PostMapping("/{id}/cancel") public void cancel(@PathVariable java.util.UUID id, @jakarta.validation.Valid @RequestBody com.vaijunto.dto.CancelOfferRequest request, Authentication authentication) { offerService.cancel(id, request, authentication.getName()); }

    @GetMapping("/nearby")
    public ResponseEntity<List<OfferDto>> getNearbyOffers(
            @RequestParam double lat,
            @RequestParam double lon,
            @RequestParam(defaultValue = "5000") double distanceMeters, Authentication authentication) {

        List<OfferDto> offers = offerService.findActiveOffersNearOrigin(lat, lon, distanceMeters, authentication.getName());
        return ResponseEntity.ok(offers);
    }

    @PostMapping
    public ResponseEntity<OfferDto> createOffer(
            @RequestBody CreateOfferRequest request,
            Authentication authentication) {

        OfferDto offer = offerService.createOffer(request, authentication.getName());
        return ResponseEntity.status(HttpStatus.CREATED).body(offer);
    }
}
