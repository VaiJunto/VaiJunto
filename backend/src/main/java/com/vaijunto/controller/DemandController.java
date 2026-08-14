package com.vaijunto.controller;

import com.vaijunto.dto.CreateDemandRequest;
import com.vaijunto.dto.DemandDto;
import com.vaijunto.service.DemandService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/demands")
@RequiredArgsConstructor
public class DemandController {

    private final DemandService demandService;

    @GetMapping("/mine") public List<DemandDto> mine(Authentication authentication) { return demandService.findMine(authentication.getName()); }
    @GetMapping public com.vaijunto.dto.PageResponse<DemandDto> browse(@RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) { return demandService.browse(page, size); }

    @GetMapping("/nearby")
    public ResponseEntity<List<DemandDto>> getNearbyDemands(
            @RequestParam double lat,
            @RequestParam double lon,
            @RequestParam(defaultValue = "5000") double distanceMeters) {

        List<DemandDto> demands = demandService.findOpenDemandsNearOrigin(lat, lon, distanceMeters);
        return ResponseEntity.ok(demands);
    }

    @PostMapping
    public ResponseEntity<DemandDto> createDemand(
            @RequestBody CreateDemandRequest request,
            Authentication authentication) {

        DemandDto demand = demandService.createDemand(request, authentication.getName());
        return ResponseEntity.status(HttpStatus.CREATED).body(demand);
    }
    @PutMapping("/{id}") public DemandDto update(@PathVariable java.util.UUID id, @RequestBody CreateDemandRequest request, Authentication authentication) { return demandService.updateDemand(id, request, authentication.getName()); }
    @DeleteMapping("/{id}") public ResponseEntity<Void> cancel(@PathVariable java.util.UUID id, Authentication authentication) { demandService.cancelDemand(id, authentication.getName()); return ResponseEntity.noContent().build(); }
}
