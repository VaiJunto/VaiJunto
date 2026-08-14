package com.vaijunto.controller;

import com.vaijunto.dto.HealthResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.info.BuildProperties;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/health")
public class HealthController {

    private final Optional<BuildProperties> buildProperties;

    @Value("${spring.application.name}")
    private String serviceName;

    public HealthController(Optional<BuildProperties> buildProperties) {
        this.buildProperties = buildProperties;
    }

    @GetMapping
    public ResponseEntity<HealthResponse> health() {
        String version = buildProperties.map(BuildProperties::getVersion).orElse("dev");
        return ResponseEntity.ok(new HealthResponse("UP", serviceName, version, Instant.now()));
    }
}
