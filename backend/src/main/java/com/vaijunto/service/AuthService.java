package com.vaijunto.service;

import com.vaijunto.domain.entities.University;
import com.vaijunto.domain.entities.User;
import com.vaijunto.domain.enums.ProfileType;
import com.vaijunto.dto.*;
import com.vaijunto.repository.UniversityRepository;
import com.vaijunto.repository.UserRepository;
import com.vaijunto.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.EnumSet;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final UniversityRepository universityRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider tokenProvider;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("E-mail já cadastrado no sistema.");
        }

        University university = null;
        if (request.getUniversityId() != null) {
            university = universityRepository.findById(request.getUniversityId())
                    .orElse(null);
        }

        var profileTypes = (request.getProfileTypes() != null && !request.getProfileTypes().isEmpty())
                ? request.getProfileTypes()
                : EnumSet.of(ProfileType.PASSENGER);

        User user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .phone(request.getPhone())
                .profileTypes(profileTypes)
                .university(university)
                .isActive(true)
                .build();

        User savedUser = userRepository.save(user);

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        String token = tokenProvider.generateToken(authentication, savedUser.getId());

        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .user(UserDto.fromEntity(savedUser))
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword())
        );

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado."));

        String token = tokenProvider.generateToken(authentication, user.getId());

        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .user(UserDto.fromEntity(user))
                .build();
    }
}
