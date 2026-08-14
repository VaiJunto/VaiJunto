package com.vaijunto.controller;
import com.vaijunto.dto.AdminLoginRequest;
import com.vaijunto.dto.AdminLoginResponse;
import com.vaijunto.dto.AdminInviteAcceptRequest;
import com.vaijunto.dto.AdminRecoveryConfirmRequest;
import com.vaijunto.service.AdminAuthService;
import com.vaijunto.service.AdminProvisioningService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/v1/admin/auth") @RequiredArgsConstructor
public class AdminAuthController {
    private final AdminAuthService service;
    private final AdminProvisioningService provisioning;
    @PostMapping("/login") public ResponseEntity<AdminLoginResponse> login(@RequestBody AdminLoginRequest request) { return ResponseEntity.ok(service.login(request)); }
    @PostMapping("/invite/accept") public ResponseEntity<Void> acceptInvite(@RequestBody AdminInviteAcceptRequest request) { provisioning.accept(request); return ResponseEntity.noContent().build(); }
    @PostMapping("/recovery/request") public ResponseEntity<Void> requestRecovery(@RequestBody java.util.Map<String,String> request) { provisioning.requestRecovery(request.getOrDefault("email", "")); return ResponseEntity.noContent().build(); }
    @PostMapping("/recovery/confirm") public ResponseEntity<Void> confirmRecovery(@RequestBody AdminRecoveryConfirmRequest request) { provisioning.confirmRecovery(request); return ResponseEntity.noContent().build(); }
}
