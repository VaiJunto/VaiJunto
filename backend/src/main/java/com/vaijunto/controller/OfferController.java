package com.vaijunto.controller;

import com.vaijunto.dto.OfferDto;
import com.vaijunto.service.OfferService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
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
}
