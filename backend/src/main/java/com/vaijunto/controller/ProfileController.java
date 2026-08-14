package com.vaijunto.controller;

import com.vaijunto.dto.PublicProfileDto;
import com.vaijunto.dto.UpdateProfileRequest;
import com.vaijunto.dto.NameChangeRequest;
import com.vaijunto.dto.UserDto;
import com.vaijunto.exception.ApiException;
import com.vaijunto.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class ProfileController {
    private final UserRepository users;
    private final com.vaijunto.service.AccountLifecycleService lifecycle;

    @GetMapping("/{id}/profile")
    public PublicProfileDto publicProfile(@PathVariable UUID id) {
        return PublicProfileDto.fromEntity(users.findById(id).orElseThrow(ApiException::userNotFound));
    }

    @PatchMapping("/me/profile")
    public UserDto update(@RequestBody UpdateProfileRequest request, Authentication auth) {
        var user = users.findByEmail(auth.getName()).orElseThrow(ApiException::userNotFound);
        if (request.getCourse() != null) user.setCourse(request.getCourse().trim());
        if (request.getPhotoUrl() != null && !request.getPhotoUrl().equals(user.getPhotoUrl())) {
            user.setPhotoUrl(request.getPhotoUrl().trim());
            user.setVerificationBadgeActive(false);
        }
        return UserDto.fromEntity(users.save(user));
    }

    @PostMapping("/me/deletion-request")
    public ResponseEntity<Void> requestDeletion(Authentication auth) {
        var user = users.findByEmail(auth.getName()).orElseThrow(ApiException::userNotFound);
        lifecycle.requestDeletion(user.getId());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/me/name-change")
    public ResponseEntity<Void> requestNameChange(@RequestBody NameChangeRequest request, Authentication auth) {
        String name = request.getFullName() == null ? "" : request.getFullName().trim();
        if (name.length() < 3) throw new IllegalArgumentException("Informe seu nome completo.");
        var user = users.findByEmail(auth.getName()).orElseThrow(ApiException::userNotFound);
        user.setRequestedFullName(name); user.setNameChangeStatus("PENDING"); users.save(user);
        return ResponseEntity.accepted().build();
    }
}
