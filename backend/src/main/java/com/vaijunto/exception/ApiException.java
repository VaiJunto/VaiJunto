package com.vaijunto.exception;

import lombok.Getter;
import org.springframework.http.HttpStatus;

/**
 * Erro de negócio com um código de máquina além da mensagem legível.
 *
 * {@link IllegalArgumentException} basta quando o app só precisa mostrar a
 * mensagem num snackbar. Mas "e-mail não confirmado" precisa que o app tome
 * uma ação diferente (navegar para a tela de verificação) — daqui vem o
 * {@code code}, que o app usa para decidir o que fazer, sem ficar comparando
 * string de mensagem traduzida.
 */
@Getter
public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final String code;

    public ApiException(HttpStatus status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public static ApiException emailNotVerified() {
        return new ApiException(HttpStatus.FORBIDDEN, "EMAIL_NOT_VERIFIED",
                "Confirme seu e-mail institucional para continuar.");
    }

    /**
     * Cobre dígito errado, código vencido, já usado e tentativas esgotadas —
     * de propósito sem dizer qual dos casos é. Diferenciar "incorreto" de
     * "expirado" parecia mais preciso, mas na prática confunde: a tela de
     * verificação reaproveita o código mais recente do usuário, que pode ter
     * sido gerado bem antes desta tentativa (ex: login horas depois do
     * cadastro) — "expirado" soa como bug quando na verdade só passou tempo
     * demais desde o envio. Ambíguo e sempre sugerindo reenvio evita a
     * confusão nos dois sentidos.
     */
    public static ApiException invalidOrExpiredCode() {
        return new ApiException(HttpStatus.BAD_REQUEST, "INVALID_CODE",
                "Código incorreto ou expirado. Solicite um novo abaixo.");
    }

    public static ApiException alreadyVerified() {
        return new ApiException(HttpStatus.BAD_REQUEST, "ALREADY_VERIFIED",
                "Este e-mail já foi confirmado.");
    }

    public static ApiException rateLimited(int waitSeconds) {
        return new ApiException(HttpStatus.TOO_MANY_REQUESTS, "RATE_LIMITED",
                "Aguarde " + waitSeconds + "s antes de pedir um novo código.");
    }

    public static ApiException userNotFound() {
        return new ApiException(HttpStatus.NOT_FOUND, "USER_NOT_FOUND", "Usuário não encontrado.");
    }
}
