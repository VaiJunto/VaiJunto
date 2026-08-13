package com.vaijunto.service;

import com.vaijunto.domain.entities.EmailVerificationCode;
import com.vaijunto.domain.entities.University;
import com.vaijunto.domain.entities.User;
import com.vaijunto.domain.enums.ProfileType;
import com.vaijunto.dto.*;
import com.vaijunto.exception.ApiException;
import com.vaijunto.repository.EmailVerificationCodeRepository;
import com.vaijunto.repository.UniversityRepository;
import com.vaijunto.repository.UserRepository;
import com.vaijunto.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.EnumSet;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final UniversityRepository universityRepository;
    private final EmailVerificationCodeRepository verificationCodeRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider tokenProvider;
    private final EmailService emailService;

    private static final SecureRandom RANDOM = new SecureRandom();

    /** Domínios institucionais aceitos para criar conta. */
    private static final Set<String> INSTITUTIONAL_DOMAINS = Set.of(
            "aluno.cps.sp.gov.br",
            "fatec.sp.gov.br"
    );

    @Value("${app.verification.code-expiry-minutes:15}")
    private int codeExpiryMinutes;

    @Value("${app.verification.resend-cooldown-seconds:60}")
    private int resendCooldownSeconds;

    @Transactional
    public RegisterResponse register(RegisterRequest request) {
        String email = normalizeAndValidateEmail(request.getEmail());
        request.setEmail(email);

        validatePassword(request.getPassword());

        if (userRepository.existsByEmail(email)) {
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
                .emailVerified(false)
                .build();

        User savedUser = userRepository.save(user);

        issueAndSendCode(savedUser);

        return RegisterResponse.builder()
                .email(savedUser.getEmail())
                .message("Enviamos um código de confirmação para o seu e-mail institucional.")
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        String email = request.getEmail() == null ? "" : request.getEmail().trim().toLowerCase();

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(email, request.getPassword())
        );

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("Usuário não encontrado."));

        // Senha correta, mas o e-mail institucional ainda não foi confirmado —
        // sem token aqui. O app reconhece o code EMAIL_NOT_VERIFIED e leva
        // para a tela de confirmação em vez de só mostrar um erro genérico.
        if (!Boolean.TRUE.equals(user.getEmailVerified())) {
            throw ApiException.emailNotVerified();
        }

        String token = tokenProvider.generateToken(authentication, user.getId());

        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .user(UserDto.fromEntity(user))
                .build();
    }

    /**
     * Confirma o código e, se válido, já autentica — a identidade acabou de
     * ser provada pelo código, não faz sentido pedir a senha de novo.
     */
    @Transactional
    public AuthResponse verifyEmail(VerifyEmailRequest request) {
        String email = request.getEmail() == null ? "" : request.getEmail().trim().toLowerCase();
        String code = request.getCode() == null ? "" : request.getCode().trim();

        User user = userRepository.findByEmail(email)
                .orElseThrow(ApiException::userNotFound);

        if (Boolean.TRUE.equals(user.getEmailVerified())) {
            throw ApiException.alreadyVerified();
        }

        EmailVerificationCode verification = verificationCodeRepository
                .findFirstByUserIdOrderByCreatedAtDesc(user.getId())
                .orElseThrow(ApiException::invalidOrExpiredCode);

        verification.setAttempts(verification.getAttempts() + 1);

        // Limite de tentativas: um código de 6 dígitos sem isso é força-bruta
        // viável (1 milhão de combinações, sem essa trava o endpoint deixaria
        // tentar todas). Passado o limite, só resta pedir reenvio.
        boolean tooManyAttempts = verification.getAttempts() > 5;

        if (verification.isConsumed() || verification.isExpired() || tooManyAttempts
                || !verification.getCode().equals(code)) {
            verificationCodeRepository.save(verification);
            throw ApiException.invalidOrExpiredCode();
        }

        verification.setConsumedAt(OffsetDateTime.now());
        verificationCodeRepository.save(verification);

        user.setEmailVerified(true);
        userRepository.save(user);

        String token = tokenProvider.generateToken(user.getEmail(), user.getId());

        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .user(UserDto.fromEntity(user))
                .build();
    }

    @Transactional
    public void resendVerificationCode(ResendVerificationRequest request) {
        String email = request.getEmail() == null ? "" : request.getEmail().trim().toLowerCase();

        User user = userRepository.findByEmail(email)
                .orElseThrow(ApiException::userNotFound);

        if (Boolean.TRUE.equals(user.getEmailVerified())) {
            throw ApiException.alreadyVerified();
        }

        verificationCodeRepository.findFirstByUserIdOrderByCreatedAtDesc(user.getId())
                .ifPresent(last -> {
                    long secondsSinceLast = ChronoUnit.SECONDS.between(last.getCreatedAt(), OffsetDateTime.now());
                    if (secondsSinceLast < resendCooldownSeconds) {
                        throw ApiException.rateLimited((int) (resendCooldownSeconds - secondsSinceLast));
                    }
                });

        issueAndSendCode(user);
    }

    private void issueAndSendCode(User user) {
        String code = String.format("%06d", RANDOM.nextInt(1_000_000));

        EmailVerificationCode verification = EmailVerificationCode.builder()
                .user(user)
                .code(code)
                .expiresAt(OffsetDateTime.now().plusMinutes(codeExpiryMinutes))
                .attempts(0)
                .build();

        verificationCodeRepository.save(verification);
        emailService.sendVerificationCode(user.getEmail(), user.getName(), code);
    }

    /**
     * Normaliza o e-mail e garante que pertence a um domínio institucional.
     * A validação no app é apenas conveniência de UX — esta aqui é a que vale.
     */
    private String normalizeAndValidateEmail(String rawEmail) {
        String email = rawEmail == null ? "" : rawEmail.trim().toLowerCase();

        if (!email.matches("^[\\w.+-]+@[\\w-]+(\\.[\\w-]+)+$")) {
            throw new IllegalArgumentException("E-mail inválido.");
        }

        String domain = email.substring(email.indexOf('@') + 1);
        if (!INSTITUTIONAL_DOMAINS.contains(domain)) {
            throw new IllegalArgumentException(
                    "Use seu e-mail institucional (@aluno.cps.sp.gov.br ou @fatec.sp.gov.br).");
        }

        return email;
    }

    /** Mesmas regras exibidas no checklist do app. */
    private void validatePassword(String password) {
        if (password == null
                || password.length() < 8
                || !password.matches(".*[A-Z].*")
                || !password.matches(".*[a-z].*")
                || !password.matches(".*[0-9].*")) {
            throw new IllegalArgumentException(
                    "A senha precisa ter ao menos 8 caracteres, incluindo maiúscula, minúscula e número.");
        }
    }
}
