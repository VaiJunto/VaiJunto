package com.vaijunto.service;

import com.vaijunto.domain.enums.VerificationCodePurpose;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;
import org.springframework.web.util.HtmlUtils;

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

    @Value("${app.verification.code-expiry-minutes:15}")
    private int codeExpiryMinutes;

    public void sendVerificationCode(
            String toEmail,
            String userName,
            String code,
            VerificationCodePurpose purpose
    ) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromAddress);
            helper.setTo(toEmail);
            helper.setSubject(subjectFor(purpose));
            helper.setText(
                    buildPlainText(userName, code, purpose),
                    buildHtml(toEmail, userName, code, purpose)
            );

            mailSender.send(message);
        } catch (MessagingException ex) {
            // Falha de envio não deve derrubar o cadastro em si — o usuário
            // ainda pode pedir reenvio depois. Só registramos o erro.
            log.error("Falha ao enviar e-mail de verificação para {}", toEmail, ex);
        }
    }

    public void sendAdminLink(String email, String subject, String message, String token) {
        try {
            MimeMessage mail = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mail, false, "UTF-8");
            helper.setFrom(fromAddress); helper.setTo(email); helper.setSubject(subject);
            helper.setText(message + "\n\nCódigo seguro: " + token + "\nExpira em 30 minutos.");
            mailSender.send(mail);
        } catch (MessagingException ex) { log.error("Falha ao enviar e-mail administrativo para {}", email, ex); }
    }

    String subjectFor(VerificationCodePurpose purpose) {
        if (purpose == VerificationCodePurpose.DEVICE_CHALLENGE) {
            return "Código para confirmar seu dispositivo — VaiJunto";
        }
        return "Código para confirmar seu e-mail — VaiJunto";
    }

    String buildPlainText(String userName, String code, VerificationCodePurpose purpose) {
        String firstName = (userName == null || userName.isBlank())
                ? "" : userName.trim().split("\\s+")[0];
        String greeting = firstName.isEmpty() ? "Olá!" : "Olá, " + firstName + "!";
        boolean deviceChallenge = purpose == VerificationCodePurpose.DEVICE_CHALLENGE;
        String title = deviceChallenge ? "Confirme este dispositivo" : "Confirme seu e-mail";
        String description = deviceChallenge
                ? "Recebemos uma tentativa de acesso em um dispositivo novo."
                : "Confirme seu e-mail institucional para concluir a criação da sua conta.";

        return """
                %s

                %s
                %s

                CÓDIGO DE 6 DÍGITOS: %s

                Volte ao VaiJunto e digite esse código no campo "Código de 6 dígitos".
                O código expira em %d minutos.

                Não compartilhe este código. Se você não solicitou esta confirmação,
                ignore este e-mail com segurança.

                VaiJunto · Mobilidade universitária
                """.formatted(greeting, title, description, code, codeExpiryMinutes);
    }

    /**
     * Layout em tabelas e estilos inline de propósito: é o formato mais estável
     * no Gmail e Outlook. A identidade vem de blocos, códigos operacionais e
     * contraste — não de imagens externas ou animações que podem ser bloqueadas.
     */
    String buildHtml(
            String toEmail,
            String userName,
            String code,
            VerificationCodePurpose purpose
    ) {
        String firstName = (userName == null || userName.isBlank())
                ? "" : userName.trim().split("\\s+")[0];
        String safeFirstName = HtmlUtils.htmlEscape(firstName);
        String safeEmail = HtmlUtils.htmlEscape(toEmail == null ? "" : toEmail);
        String safeCode = HtmlUtils.htmlEscape(code == null ? "" : code);
        String greeting = safeFirstName.isEmpty() ? "Olá!" : "Olá, " + safeFirstName + "!";

        boolean deviceChallenge = purpose == VerificationCodePurpose.DEVICE_CHALLENGE;
        String operationCode = deviceChallenge ? "VJ//DEVICE_VERIFY" : "VJ//EMAIL_VERIFY";
        String title = deviceChallenge ? "Confirme este dispositivo" : "Confirme seu e-mail";
        String description = deviceChallenge
                ? "Recebemos uma tentativa de acesso em um dispositivo novo. Use o código abaixo para confirmar que é você."
                : "Use o código abaixo para confirmar seu e-mail institucional e concluir a criação da sua conta.";
        String purposeLabel = deviceChallenge ? "Confirmar dispositivo" : "Confirmar e-mail";
        String preheader = deviceChallenge
                ? "Seu código de 6 dígitos para confirmar o novo dispositivo é " + safeCode + "."
                : "Seu código de 6 dígitos para confirmar o e-mail é " + safeCode + ".";

        return """
                <!DOCTYPE html>
                <html lang="pt-BR">
                <head>
                  <meta charset="UTF-8">
                  <meta name="viewport" content="width=device-width, initial-scale=1.0">
                  <meta name="color-scheme" content="light only">
                  <meta name="supported-color-schemes" content="light">
                  <title>%s</title>
                  <style>
                    @media screen and (max-width:620px) {
                      .email-shell { width:100%% !important; }
                      .mobile-padding { padding-left:22px !important; padding-right:22px !important; }
                      .verification-code { font-size:40px !important; letter-spacing:7px !important; }
                      .receipt-label { width:108px !important; }
                    }
                  </style>
                </head>
                <body style="margin:0; padding:0; background-color:#0E0D14;">
                  <div style="display:none; max-height:0; overflow:hidden; opacity:0; color:transparent;">%s</div>
                  <table role="presentation" width="100%%" cellpadding="0" cellspacing="0" border="0" bgcolor="#0E0D14" style="width:100%%; background-color:#0E0D14;">
                    <tr>
                      <td align="center" style="padding:32px 12px;">
                        <table role="presentation" class="email-shell" width="600" cellpadding="0" cellspacing="0" border="0" bgcolor="#F3F0E8" style="width:600px; max-width:600px; background-color:#F3F0E8; border:3px solid #111014; box-shadow:7px 7px 0 #D91568;">
                          <tr>
                            <td width="58%%" height="9" bgcolor="#D91568" style="height:9px; background-color:#D91568; font-size:0; line-height:0;">&nbsp;</td>
                            <td width="18%%" height="9" bgcolor="#00B8D9" style="height:9px; background-color:#00B8D9; font-size:0; line-height:0;">&nbsp;</td>
                            <td width="24%%" height="9" bgcolor="#F3F0E8" style="height:9px; background-color:#F3F0E8; font-size:0; line-height:0;">&nbsp;</td>
                          </tr>

                          <tr>
                            <td colspan="3" class="mobile-padding" style="padding:24px 34px 22px; border-bottom:3px solid #111014;">
                              <table role="presentation" width="100%%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                  <td width="62" valign="middle">
                                    <table role="presentation" width="54" height="54" cellpadding="0" cellspacing="0" border="0" bgcolor="#5146D8" style="width:54px; height:54px; background-color:#5146D8; border:3px solid #111014; box-shadow:4px 4px 0 #111014;">
                                      <tr><td align="center" valign="middle" style="font-family:'Courier New',monospace; font-size:21px; line-height:54px; font-weight:900; color:#FFFFFF;">VJ</td></tr>
                                    </table>
                                  </td>
                                  <td valign="middle" style="padding-left:12px;">
                                    <div style="font-family:Arial,Helvetica,sans-serif; font-size:25px; line-height:28px; font-weight:900; letter-spacing:1px; color:#111014;">VAIJUNTO</div>
                                    <div style="font-family:'Courier New',monospace; font-size:11px; line-height:16px; font-weight:700; letter-spacing:1px; color:#5146D8;">MOBILIDADE UNIVERSITÁRIA</div>
                                  </td>
                                  <td align="right" valign="middle" style="font-family:'Courier New',monospace; font-size:11px; line-height:16px; font-weight:700; color:#D91568;">CÓDIGO ATIVO</td>
                                </tr>
                              </table>
                            </td>
                          </tr>

                          <tr>
                            <td colspan="3" class="mobile-padding" style="padding:30px 34px 0;">
                              <div style="font-family:'Courier New',monospace; font-size:12px; line-height:18px; font-weight:700; letter-spacing:1px; color:#00A2C0;">%s</div>
                              <h1 style="font-family:Arial,Helvetica,sans-serif; font-size:31px; line-height:35px; font-weight:900; letter-spacing:-0.5px; color:#111014; margin:6px 0 16px;">%s</h1>
                              <p style="font-family:Arial,Helvetica,sans-serif; font-size:18px; line-height:27px; font-weight:700; color:#111014; margin:0 0 8px;">%s</p>
                              <p style="font-family:Arial,Helvetica,sans-serif; font-size:16px; line-height:25px; font-weight:400; color:#35323C; margin:0;">%s</p>
                            </td>
                          </tr>

                          <tr>
                            <td colspan="3" class="mobile-padding" style="padding:26px 34px 0;">
                              <table role="presentation" width="100%%" cellpadding="0" cellspacing="0" border="0" bgcolor="#FFFFFF" style="width:100%%; background-color:#FFFFFF; border:3px solid #111014; box-shadow:5px 5px 0 #111014;">
                                <tr><td height="7" bgcolor="#D91568" style="height:7px; background-color:#D91568; font-size:0; line-height:0;">&nbsp;</td></tr>
                                <tr>
                                  <td align="center" style="padding:20px 12px 23px;">
                                    <div style="font-family:'Courier New',monospace; font-size:12px; line-height:18px; font-weight:700; letter-spacing:1px; color:#5146D8;">SEU CÓDIGO DE 6 DÍGITOS</div>
                                    <div class="verification-code" aria-label="Código %s" style="font-family:'Courier New',Consolas,monospace; font-size:48px; line-height:58px; font-weight:900; letter-spacing:10px; color:#111014; margin-top:7px; mso-line-height-rule:exactly;">%s</div>
                                  </td>
                                </tr>
                              </table>
                            </td>
                          </tr>

                          <tr>
                            <td colspan="3" class="mobile-padding" style="padding:24px 34px 0;">
                              <p style="font-family:Arial,Helvetica,sans-serif; font-size:17px; line-height:26px; font-weight:700; color:#111014; margin:0;">Volte ao VaiJunto e digite este código no campo “Código de 6 dígitos”.</p>
                            </td>
                          </tr>

                          <tr>
                            <td colspan="3" class="mobile-padding" style="padding:24px 34px 0;">
                              <table role="presentation" width="100%%" cellpadding="0" cellspacing="0" border="0" style="width:100%%; border:2px dashed #111014;">
                                <tr>
                                  <td colspan="2" bgcolor="#1A1723" style="padding:10px 14px; background-color:#1A1723; font-family:'Courier New',monospace; font-size:12px; line-height:17px; font-weight:700; letter-spacing:1px; color:#F4F0E6;">COMPROVANTE DE CONFIRMAÇÃO</td>
                                </tr>
                                <tr>
                                  <td class="receipt-label" width="126" valign="top" style="padding:13px 8px 10px 14px; border-bottom:1px solid #C7C2B9; font-family:'Courier New',monospace; font-size:11px; line-height:17px; font-weight:700; color:#6B6670;">FINALIDADE</td>
                                  <td valign="top" style="padding:13px 14px 10px 8px; border-bottom:1px solid #C7C2B9; font-family:Arial,Helvetica,sans-serif; font-size:14px; line-height:19px; font-weight:700; color:#111014;">%s</td>
                                </tr>
                                <tr>
                                  <td class="receipt-label" width="126" valign="top" style="padding:10px 8px 10px 14px; border-bottom:1px solid #C7C2B9; font-family:'Courier New',monospace; font-size:11px; line-height:17px; font-weight:700; color:#6B6670;">DESTINATÁRIO</td>
                                  <td valign="top" style="padding:10px 14px 10px 8px; border-bottom:1px solid #C7C2B9; font-family:Arial,Helvetica,sans-serif; font-size:14px; line-height:19px; color:#111014; word-break:break-word;">%s</td>
                                </tr>
                                <tr>
                                  <td class="receipt-label" width="126" valign="top" style="padding:10px 8px 13px 14px; font-family:'Courier New',monospace; font-size:11px; line-height:17px; font-weight:700; color:#6B6670;">VALIDADE</td>
                                  <td valign="top" style="padding:10px 14px 13px 8px; font-family:Arial,Helvetica,sans-serif; font-size:14px; line-height:19px; font-weight:700; color:#D91568;">%d minutos</td>
                                </tr>
                              </table>
                            </td>
                          </tr>

                          <tr>
                            <td colspan="3" class="mobile-padding" style="padding:22px 34px 30px;">
                              <table role="presentation" width="100%%" cellpadding="0" cellspacing="0" border="0" bgcolor="#E9E5DC" style="width:100%%; background-color:#E9E5DC; border-left:5px solid #5146D8;">
                                <tr><td style="padding:13px 15px; font-family:Arial,Helvetica,sans-serif; font-size:14px; line-height:21px; color:#35323C;"><strong style="color:#111014;">Não compartilhe este código.</strong> Se você não solicitou esta confirmação, pode ignorar este e-mail com segurança.</td></tr>
                              </table>
                            </td>
                          </tr>

                          <tr>
                            <td colspan="3" bgcolor="#1A1723" style="padding:18px 34px; background-color:#1A1723; border-top:3px solid #111014;">
                              <table role="presentation" width="100%%" cellpadding="0" cellspacing="0" border="0">
                                <tr>
                                  <td style="font-family:Arial,Helvetica,sans-serif; font-size:12px; line-height:18px; color:#D8D3CA;">VaiJunto · Mobilidade universitária</td>
                                  <td align="right" style="font-family:'Courier New',monospace; font-size:11px; line-height:18px; font-weight:700; color:#00B8D9;">ROTA · HORÁRIO · ENCONTRO</td>
                                </tr>
                              </table>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                </body>
                </html>
                """.formatted(
                title,
                preheader,
                operationCode,
                title,
                greeting,
                description,
                safeCode,
                safeCode,
                purposeLabel,
                safeEmail,
                codeExpiryMinutes
        );
    }
}
