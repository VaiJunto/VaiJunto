package com.vaijunto.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

/**
 * Envio de e-mails transacionais.
 *
 * Fase de testes: SMTP do Gmail (500/dia, remetente = a própria conta Gmail
 * autenticada). Para produção, trocar {@code spring.mail.host/port/username/
 * password} por um provedor transacional (Resend, Brevo, MailerSend) com
 * domínio próprio verificado (SPF+DKIM+DMARC) — sem isso, e-mail para domínio
 * @gov.br (Fatec/CPS) corre risco real de ser rejeitado ou cair em spam.
 * A troca é só configuração; nada aqui muda.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.mail.from}")
    private String fromAddress;

    public void sendVerificationCode(String toEmail, String userName, String code) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, "UTF-8");

            helper.setFrom(fromAddress);
            helper.setTo(toEmail);
            helper.setSubject("Seu código de confirmação — VaiJunto");
            helper.setText(buildHtml(userName, code), true);

            mailSender.send(message);
        } catch (MessagingException ex) {
            // Falha de envio não deve derrubar o cadastro em si — o usuário
            // ainda pode pedir reenvio depois. Só registramos o erro.
            log.error("Falha ao enviar e-mail de verificação para {}", toEmail, ex);
        }
    }

    /**
     * Layout em tabelas (não flexbox/grid) de propósito — é o que sobrevive ao
     * sanitizador de HTML do Gmail/Outlook. Cores e gradiente batem com a
     * marca do app ({@code Color(0xFF1E88E5)}→{@code 0xFF1565C0} no Flutter).
     * Ícones são emoji nativo, não `<img>`: renderizam sempre, mesmo com
     * imagens externas bloqueadas por padrão no Gmail.
     */
    private String buildHtml(String userName, String code) {
        String firstName = (userName == null || userName.isBlank())
                ? "" : userName.trim().split("\\s+")[0];
        String greeting = firstName.isEmpty() ? "Oi!" : "Oi, " + firstName + "!";

        return """
                <!DOCTYPE html>
                <html>
                <body style="margin:0; padding:0; background-color:#EEF3F8;">
                  <table role="presentation" width="100%%" cellpadding="0" cellspacing="0" style="background-color:#EEF3F8; padding:32px 16px;">
                    <tr><td align="center">
                      <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="max-width:480px; width:100%%; background-color:#FFFFFF; border-radius:20px; overflow:hidden; box-shadow:0 8px 28px rgba(21,101,192,0.14);">

                        <tr><td style="background:linear-gradient(135deg,#1E88E5 0%%,#1565C0 100%%); padding:36px 32px 28px; text-align:center;">
                          <table role="presentation" cellpadding="0" cellspacing="0" align="center"><tr><td style="width:60px; height:60px; background-color:rgba(255,255,255,0.20); border-radius:16px; text-align:center; vertical-align:middle; font-size:30px; line-height:60px;">🚐</td></tr></table>
                          <div style="font-family:'Trebuchet MS',Verdana,sans-serif; font-size:25px; font-weight:700; color:#FFFFFF; letter-spacing:0.5px; margin-top:14px;">VaiJunto</div>
                          <div style="font-family:Arial,sans-serif; font-size:12px; color:rgba(255,255,255,0.85); margin-top:2px; letter-spacing:1.5px; text-transform:uppercase;">Caronas universitárias</div>
                        </td></tr>

                        <tr><td style="padding:0 40px;">
                          <table role="presentation" width="100%%" cellpadding="0" cellspacing="0" style="margin-top:-13px;">
                            <tr>
                              <td width="13" style="font-size:0;"><div style="width:13px; height:13px; border-radius:50%%; background:#FFFFFF; border:3px solid #1565C0;"></div></td>
                              <td style="border-top:2px dashed #90CAF9; font-size:0;">&nbsp;</td>
                              <td width="13" style="font-size:0;"><div style="width:13px; height:13px; border-radius:50%%; background:#FFC107;"></div></td>
                            </tr>
                          </table>
                        </td></tr>

                        <tr><td style="padding:28px 40px 4px;">
                          <p style="font-family:Arial,sans-serif; font-size:17px; color:#263238; margin:0 0 6px;">%s 👋</p>
                          <p style="font-family:Arial,sans-serif; font-size:14.5px; color:#607D8B; line-height:1.6; margin:0;">Use o código abaixo para confirmar seu e-mail institucional e liberar seu acesso ao VaiJunto.</p>
                        </td></tr>

                        <tr><td style="padding:24px 40px 0;">
                          <table role="presentation" width="100%%" cellpadding="0" cellspacing="0" style="background:linear-gradient(135deg,#E3F2FD 0%%,#BBDEFB 100%%); border-radius:16px; border:1.5px dashed #64B5F6;">
                            <tr><td style="padding:22px; text-align:center;">
                              <div style="font-family:'Courier New',monospace; font-size:36px; font-weight:800; letter-spacing:9px; color:#0D47A1;">%s</div>
                            </td></tr>
                          </table>
                        </td></tr>

                        <tr><td style="padding:18px 40px 36px;">
                          <p style="font-family:Arial,sans-serif; font-size:12.5px; color:#90A4AE; text-align:center; margin:0;">⏱ Expira em 15 minutos · Se você não pediu isso, ignore este e-mail.</p>
                        </td></tr>

                        <tr><td style="background-color:#F5F7FA; padding:22px 32px; text-align:center; border-top:1px solid #ECEFF1;">
                          <p style="font-family:Arial,sans-serif; font-size:12px; color:#B0BEC5; margin:0;">VaiJunto · Conectando estudantes, uma carona de cada vez 🎓</p>
                        </td></tr>

                      </table>
                    </td></tr>
                  </table>
                </body>
                </html>
                """.formatted(greeting, code);
    }
}
