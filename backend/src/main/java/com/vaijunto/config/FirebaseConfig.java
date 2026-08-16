package com.vaijunto.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;

import jakarta.annotation.PostConstruct;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import org.springframework.beans.factory.annotation.Value;

@Slf4j
@Configuration
public class FirebaseConfig {
    @Value("${app.firebase.service-account-path:}")
    private String serviceAccountPath;

    @PostConstruct
    public void initialize() {
        try {
            // No MVP, se o arquivo não existir, não falhamos a inicialização, apenas logamos.
            InputStream serviceAccount = serviceAccountPath != null && !serviceAccountPath.isBlank()
                    ? Files.newInputStream(Path.of(serviceAccountPath))
                    : getClass().getClassLoader().getResourceAsStream("firebase-service-account.json");
            
            if (serviceAccount != null && FirebaseApp.getApps().isEmpty()) {
                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                FirebaseApp.initializeApp(options);
                log.info("Firebase Cloud Messaging (FCM) inicializado com sucesso.");
            } else {
                log.warn("Arquivo 'firebase-service-account.json' não encontrado. Firebase Push Notifications desativado no ambiente atual.");
            }
        } catch (Exception e) {
            log.error("Erro ao inicializar Firebase: {}", e.getMessage());
        }
    }
}
