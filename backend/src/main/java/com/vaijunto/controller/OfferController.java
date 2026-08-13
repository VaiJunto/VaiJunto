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

    @GetMapping("/nearby")
    public ResponseEntity<List<OfferDto>> getNearbyOffers(
            @RequestParam double lat,
            @RequestParam double lon,
            @RequestParam(defaultValue = "5000") double distanceMeters) {

        List<OfferDto> offers = offerService.findActiveOffersNearOrigin(lat, lon, distanceMeters);
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
