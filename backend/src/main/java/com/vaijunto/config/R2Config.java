package com.vaijunto.config;

import java.net.URI;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

@Configuration
public class R2Config {
 @Bean public R2Properties r2Properties(@Value("${app.r2.endpoint:}") String endpoint,@Value("${app.r2.bucket:}") String bucket,@Value("${app.r2.region:auto}") String region,@Value("${app.r2.access-key-id:}") String key,@Value("${app.r2.secret-access-key:}") String secret,@Value("${app.r2.max-storage-gb:30}") long maxGb){return new R2Properties(endpoint,bucket,region,key,secret,maxGb);}
 @Bean public S3Client r2Client(R2Properties p){if(!p.configured())return null;return S3Client.builder().endpointOverride(URI.create(p.endpoint())).region(Region.of(p.region())).credentialsProvider(StaticCredentialsProvider.create(AwsBasicCredentials.create(p.accessKeyId(),p.secretAccessKey()))).forcePathStyle(true).build();}
 @Bean public S3Presigner r2Presigner(R2Properties p){if(!p.configured())return null;return S3Presigner.builder().endpointOverride(URI.create(p.endpoint())).region(Region.of(p.region())).credentialsProvider(StaticCredentialsProvider.create(AwsBasicCredentials.create(p.accessKeyId(),p.secretAccessKey()))).build();}
 public record R2Properties(String endpoint,String bucket,String region,String accessKeyId,String secretAccessKey,long maxStorageGb){public boolean configured(){return StringUtils.hasText(endpoint)&&StringUtils.hasText(bucket)&&StringUtils.hasText(accessKeyId)&&StringUtils.hasText(secretAccessKey);}public boolean isCloudflareR2(){try{var host=URI.create(endpoint).getHost();return host!=null&&host.endsWith(".r2.cloudflarestorage.com");}catch(Exception error){return false;}}public long maxBytes(){return maxStorageGb*1024L*1024L*1024L;}}
}
