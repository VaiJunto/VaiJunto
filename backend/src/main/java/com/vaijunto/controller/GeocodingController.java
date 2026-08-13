package com.vaijunto.controller;

import com.vaijunto.dto.GeocodingResultDto;
import com.vaijunto.service.GeocodingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/geocoding")
@RequiredArgsConstructor
public class GeocodingController {

    private final GeocodingService geocodingService;

    @GetMapping("/search")
    public ResponseEntity<List<GeocodingResultDto>> search(@RequestParam String q) {
        if (q.trim().length() < 3) {
            return ResponseEntity.ok(List.of());
        }
        return ResponseEntity.ok(geocodingService.search(q.trim()));
    }
}
