package com.vaijunto.integration;

import static org.junit.jupiter.api.Assertions.assertFalse;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

@EnabledIfEnvironmentVariable(named = "RUN_FIREBASE_INTEGRATION", matches = "true")
class FirebaseCredentialsIntegrationTest {
    @Test
    void serviceAccountInitializesFirebaseAdmin() throws Exception {
        try (InputStream input = Files.newInputStream(Path.of(System.getenv("FIREBASE_SERVICE_ACCOUNT_PATH")))) {
            FirebaseApp.initializeApp(FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(input)).build(), "integration-test");
            assertFalse(FirebaseApp.getApps().isEmpty());
            FirebaseApp.getInstance("integration-test").delete();
        }
    }
}
