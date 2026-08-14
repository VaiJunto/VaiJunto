package com.vaijunto.service;

import com.vaijunto.domain.enums.VerificationCodePurpose;
import jakarta.mail.MessagingException;
import jakarta.mail.Session;
import jakarta.mail.internet.MimeMessage;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class EmailServiceTest {

    private EmailService emailService;

    @BeforeEach
    void setUp() {
        emailService = new EmailService(null);
        ReflectionTestUtils.setField(emailService, "codeExpiryMinutes", 15);
    }

    @Test
    void buildsEmailVerificationTemplateWithClearCodeAndAccessibleFallbacks() {
        String html = emailService.buildHtml(
                "aluno@fatec.sp.gov.br",
                "Gabriel <script>alert('x')</script>",
                "123456",
                VerificationCodePurpose.EMAIL_VERIFICATION
        );

        assertThat(html)
                .contains("VJ//EMAIL_VERIFY")
                .contains("Confirme seu e-mail")
                .contains("SEU CÓDIGO DE 6 DÍGITOS")
                .contains("123456")
                .contains("aluno@fatec.sp.gov.br")
                .contains("15 minutos")
                .contains("background-color:#F3F0E8")
                .doesNotContain("<script>alert('x')</script>")
                .doesNotContain("<img")
                .doesNotContain("<video");

        assertThat(emailService.buildPlainText(
                "Gabriel",
                "123456",
                VerificationCodePurpose.EMAIL_VERIFICATION
        ))
                .contains("Confirme seu e-mail")
                .contains("CÓDIGO DE 6 DÍGITOS: 123456")
                .contains("expira em 15 minutos");
    }

    @Test
    void adaptsSubjectAndInstructionsForDeviceChallenge() {
        String html = emailService.buildHtml(
                "aluno@fatec.sp.gov.br",
                "Gabriel",
                "654321",
                VerificationCodePurpose.DEVICE_CHALLENGE
        );

        assertThat(emailService.subjectFor(VerificationCodePurpose.DEVICE_CHALLENGE))
                .isEqualTo("Código para confirmar seu dispositivo — VaiJunto");
        assertThat(html)
                .contains("VJ//DEVICE_VERIFY")
                .contains("Confirme este dispositivo")
                .contains("Recebemos uma tentativa de acesso em um dispositivo novo")
                .contains("Confirmar dispositivo")
                .contains("654321");
    }

    @Test
    void sendsMessageWithPlainTextAndHtmlAlternatives() throws MessagingException {
        JavaMailSender mailSender = mock(JavaMailSender.class);
        MimeMessage message = new MimeMessage(Session.getInstance(new Properties()));
        when(mailSender.createMimeMessage()).thenReturn(message);

        EmailService sendingService = new EmailService(mailSender);
        ReflectionTestUtils.setField(sendingService, "fromAddress", "VaiJunto <noreply@vaijunto.app.br>");
        ReflectionTestUtils.setField(sendingService, "codeExpiryMinutes", 15);

        sendingService.sendVerificationCode(
                "aluno@fatec.sp.gov.br",
                "Gabriel",
                "123456",
                VerificationCodePurpose.EMAIL_VERIFICATION
        );

        verify(mailSender).send(message);
        message.saveChanges();
        assertThat(message.getContentType()).contains("multipart/mixed");
    }

}
