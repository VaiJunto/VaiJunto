package com.vaijunto.integration;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.HeadObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

@EnabledIfEnvironmentVariable(named = "RUN_R2_INTEGRATION", matches = "true")
class R2ConnectionIntegrationTest {
    @Test
    void putsHeadsAndDeletesTemporaryObject() {
        String bucket = System.getenv("R2_BUCKET");
        String key = "healthcheck/codex-" + UUID.randomUUID();
        try (S3Client client = S3Client.builder()
                .endpointOverride(URI.create(System.getenv("R2_ENDPOINT")))
                .region(Region.of(System.getenv().getOrDefault("R2_REGION", "auto")))
                .credentialsProvider(StaticCredentialsProvider.create(AwsBasicCredentials.create(
                        System.getenv("R2_ACCESS_KEY_ID"), System.getenv("R2_SECRET_ACCESS_KEY"))))
                .forcePathStyle(true).build()) {
            client.putObject(PutObjectRequest.builder().bucket(bucket).key(key).contentType("text/plain").build(),
                    RequestBody.fromString("temporary R2 connectivity check", StandardCharsets.UTF_8));
            assertTrue(client.headObject(HeadObjectRequest.builder().bucket(bucket).key(key).build()).contentLength() > 0);
            client.deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(key).build());
        }
    }
}
