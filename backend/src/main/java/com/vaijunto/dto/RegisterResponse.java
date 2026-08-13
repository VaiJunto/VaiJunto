package com.vaijunto.dto;

import lombok.*;

/**
 * Resposta do cadastro. Sem token de propósito — a conta só é autenticável
 * depois que {@code /auth/verify-email} confirmar o código enviado.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegisterResponse {

    private String email;
    private String message;
}
