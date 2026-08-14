package com.vaijunto.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Component
public class JwtTokenProvider {

    private static final String CHALLENGE_TYPE_CLAIM = "typ";
    private static final String DEVICE_CHALLENGE_TYPE = "device_challenge";

    private final SecretKey key;
    private final long jwtExpirationInMs;
    private final long deviceChallengeExpirationInMs;

    public JwtTokenProvider(
            @Value("${jwt.secret:404E635266556A586E3272357538782F413F4428472B4B6250655368566D5971}") String secret,
            @Value("${jwt.expiration-ms:86400000}") long jwtExpirationInMs,
            @Value("${jwt.device-challenge-expiration-ms:600000}") long deviceChallengeExpirationInMs) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.jwtExpirationInMs = jwtExpirationInMs;
        this.deviceChallengeExpirationInMs = deviceChallengeExpirationInMs;
    }

    public String generateToken(Authentication authentication, UUID userId) {
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        return generateToken(userDetails.getUsername(), userId);
    }

    /**
     * Gera o token direto a partir do e-mail, sem passar por
     * {@link org.springframework.security.authentication.AuthenticationManager}.
     *
     * Usado logo após confirmar o código de verificação: a identidade já foi
     * provada pela senha no cadastro, então não faz sentido pedir a senha de
     * novo só para emitir o token — o e-mail confirmado já é a prova aqui.
     */
    public String generateToken(String email, UUID userId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpirationInMs);

        return Jwts.builder()
                .subject(email)
                .claim("userId", userId.toString())
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key, Jwts.SIG.HS256)
                .compact();
    }

    public String getUsernameFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();

        return claims.getSubject();
    }

    public boolean validateToken(String authToken) {
        try {
            Jwts.parser().verifyWith(key).build().parseSignedClaims(authToken);
            return true;
        } catch (JwtException | IllegalArgumentException ex) {
            return false;
        }
    }

    /**
     * Token de curta duração (10 min por padrão) que só serve pra trocar por
     * um JWT de sessão em {@code POST /auth/verify-device}, depois de provar
     * posse do e-mail. Nunca autentica nada sozinho — {@link com.vaijunto.security.JwtAuthenticationFilter}
     * não aceita este tipo de token (não tem {@code userId} no formato que ele espera).
     */
    public String generateDeviceChallengeToken(UUID userId, String deviceId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + deviceChallengeExpirationInMs);

        return Jwts.builder()
                .claim(CHALLENGE_TYPE_CLAIM, DEVICE_CHALLENGE_TYPE)
                .claim("userId", userId.toString())
                .claim("deviceId", deviceId)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(key, Jwts.SIG.HS256)
                .compact();
    }

    /**
     * @throws JwtException se o token for inválido, expirado, ou não for do
     *         tipo {@code device_challenge} (ex: alguém tentando reusar um
     *         JWT de sessão normal neste endpoint).
     */
    public Claims parseDeviceChallengeToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();

        if (!DEVICE_CHALLENGE_TYPE.equals(claims.get(CHALLENGE_TYPE_CLAIM, String.class))) {
            throw new JwtException("Token não é um desafio de device válido.");
        }

        return claims;
    }
}
