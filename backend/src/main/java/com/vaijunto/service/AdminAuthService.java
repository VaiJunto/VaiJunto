package com.vaijunto.service;

import com.vaijunto.domain.entities.AdminAuditEvent;
import com.vaijunto.dto.AdminLoginRequest;
import com.vaijunto.dto.AdminLoginResponse;
import com.vaijunto.repository.AdminAccountRepository;
import com.vaijunto.repository.AdminAuditEventRepository;
import com.vaijunto.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service @RequiredArgsConstructor
public class AdminAuthService {
    private final AdminAccountRepository accounts;
    private final AdminAuditEventRepository audits;
    private final PasswordEncoder passwords;
    private final JwtTokenProvider tokens;

    @Transactional
    public AdminLoginResponse login(AdminLoginRequest request) {
        var account = accounts.findByEmail(request.getEmail().trim().toLowerCase())
                .orElseThrow(() -> new IllegalArgumentException("Credenciais administrativas inválidas."));
        if (!Boolean.TRUE.equals(account.getIsActive()) || !passwords.matches(request.getPassword(), account.getPassword())
                || !Totp.verify(account.getTotpSecret(), request.getTotpCode())) {
            throw new IllegalArgumentException("Credenciais administrativas inválidas.");
        }
        audits.save(AdminAuditEvent.builder().admin(account).eventType("ADMIN_LOGIN").build());
        return AdminLoginResponse.builder().token(tokens.generateAdminToken(account.getEmail(), account.getId(), account.getRole()))
                .role(account.getRole()).build();
    }
}
