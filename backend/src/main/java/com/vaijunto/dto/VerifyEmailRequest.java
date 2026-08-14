package com.vaijunto.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VerifyEmailRequest {

    private String email;
    private String code;

    /**
     * Opcional — quando enviado, este device já sai do cadastro marcado como
     * conhecido (ver {@link com.vaijunto.service.AuthService#verifyEmail}),
     * pra não pedir o desafio de MFA de novo no próximo login do mesmo
     * aparelho logo em seguida.
     */
    private String deviceId;
}
