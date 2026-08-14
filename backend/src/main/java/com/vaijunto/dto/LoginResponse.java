package com.vaijunto.dto;

import lombok.*;

/**
 * Resposta do login com duas formas possíveis, discriminadas por
 * {@code deviceVerificationRequired}:
 *
 * <ul>
 *   <li>{@code false} — device já conhecido: {@code token}/{@code user}
 *       preenchidos, {@code challengeToken} nulo. Igual ao login de sempre.</li>
 *   <li>{@code true} — device novo: só {@code challengeToken} preenchido,
 *       nenhum JWT de sessão ainda. O app troca esse token + o código
 *       recebido por e-mail em {@code POST /auth/verify-device}.</li>
 * </ul>
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginResponse {

    private boolean deviceVerificationRequired;
    private String challengeToken;

    private String token;
    private String tokenType;
    private UserDto user;

    public static LoginResponse authenticated(String token, UserDto user) {
        return LoginResponse.builder()
                .deviceVerificationRequired(false)
                .token(token)
                .tokenType("Bearer")
                .user(user)
                .build();
    }

    public static LoginResponse challenge(String challengeToken) {
        return LoginResponse.builder()
                .deviceVerificationRequired(true)
                .challengeToken(challengeToken)
                .build();
    }
}
