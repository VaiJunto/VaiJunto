package com.vaijunto.controller;

import com.vaijunto.dto.DemandDto;
import com.vaijunto.service.DemandService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/demands")
@RequiredArgsConstructor
public class DemandController {

    private final DemandService demandService;

    @GetMapping("/nearby")
    public ResponseEntity<List<DemandDto>> getNearbyDemands(
            @RequestParam double lat,
            @RequestParam double lon,
            @RequestParam(defaultValue = "5000") double distanceMeters) {
        
        List<DemandDto> demands = demandService.findOpenDemandsNearOrigin(lat, lon, distanceMeters);
        return ResponseEntity.ok(demands);
    }
}
