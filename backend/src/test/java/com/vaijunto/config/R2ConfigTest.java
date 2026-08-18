package com.vaijunto.config;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Duration;
import org.junit.jupiter.api.Test;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

class R2ConfigTest {
    @Test
    void presignerUsesPathStyleLikeClient() {
        var config = new R2Config();
        var properties = new R2Config.R2Properties(
                "https://account.r2.cloudflarestorage.com", "vai-junto", "auto",
                "key", "secret", 30);
        try (var presigner = config.r2Presigner(properties)) {
            var url = presigner.presignGetObject(GetObjectPresignRequest.builder()
                    .signatureDuration(Duration.ofMinutes(5))
                    .getObjectRequest(GetObjectRequest.builder()
                            .bucket("vai-junto").key("chat/file.jpg").build())
                    .build()).url();
            assertEquals("account.r2.cloudflarestorage.com", url.getHost());
            assertTrue(url.getPath().startsWith("/vai-junto/chat/file.jpg"));
            assertTrue(url.getQuery().contains("X-Amz-Signature"));
        }
    }
}
