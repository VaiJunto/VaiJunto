package com.vaijunto.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginRequest {

    private String email;
    private String password;

    /**
     * Identificador estável gerado uma vez pelo app e salvo no
     * flutter_secure_storage — é o que diferencia "device já conhecido" de
     * "primeiro login neste device" (dispara o desafio por e-mail).
     */
    private String deviceId;
}
