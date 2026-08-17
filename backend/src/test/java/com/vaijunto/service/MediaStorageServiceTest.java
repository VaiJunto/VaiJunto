package com.vaijunto.service;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;

import com.vaijunto.config.R2Config.R2Properties;
import com.vaijunto.domain.entities.MediaObject;
import com.vaijunto.domain.entities.User;
import com.vaijunto.exception.ApiException;
import com.vaijunto.repository.ConversationRepository;
import com.vaijunto.repository.MediaObjectRepository;
import com.vaijunto.repository.UserRepository;
import java.util.Optional;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;

class MediaStorageServiceTest {
    @Test
    @SuppressWarnings("unchecked")
    void directMediaAccessIsForbiddenForUnrelatedUser() {
        UserRepository users = org.mockito.Mockito.mock(UserRepository.class);
        MediaObjectRepository media = org.mockito.Mockito.mock(MediaObjectRepository.class);
        ConversationRepository conversations = org.mockito.Mockito.mock(ConversationRepository.class);
        ObjectProvider<S3Client> clients = org.mockito.Mockito.mock(ObjectProvider.class);
        ObjectProvider<S3Presigner> presigners = org.mockito.Mockito.mock(ObjectProvider.class);
        MediaStorageService service = new MediaStorageService(
                new R2Properties("", "", "auto", "", "", 30), clients, presigners, media, users, conversations,
                org.mockito.Mockito.mock(com.vaijunto.repository.AdminAccountRepository.class));
        User stranger = User.builder().id(UUID.randomUUID()).email("other@fatec.sp.gov.br").build();
        User owner = User.builder().id(UUID.randomUUID()).email("owner@fatec.sp.gov.br").build();
        UUID mediaId = UUID.randomUUID();
        MediaObject object = MediaObject.builder().id(mediaId).owner(owner).status("ACTIVE").build();
        when(users.findByEmail(stranger.getEmail())).thenReturn(Optional.of(stranger));
        when(media.findById(mediaId)).thenReturn(Optional.of(object));

        assertThrows(ApiException.class, () -> service.downloadUrl(mediaId, stranger.getEmail()));
    }

    @Test
    @SuppressWarnings("unchecked")
    void storageLimitPurgesOnlyScheduledChatMedia() {
        UserRepository users = org.mockito.Mockito.mock(UserRepository.class);
        MediaObjectRepository media = org.mockito.Mockito.mock(MediaObjectRepository.class);
        ConversationRepository conversations = org.mockito.Mockito.mock(ConversationRepository.class);
        ObjectProvider<S3Client> clients = org.mockito.Mockito.mock(ObjectProvider.class);
        ObjectProvider<S3Presigner> presigners = org.mockito.Mockito.mock(ObjectProvider.class);
        MediaStorageService service = new MediaStorageService(
                new R2Properties("", "", "auto", "", "", 30), clients, presigners, media, users, conversations,
                org.mockito.Mockito.mock(com.vaijunto.repository.AdminAccountRepository.class));
        MediaObject scheduledChat = MediaObject.builder().id(UUID.randomUUID()).status("ACTIVE")
                .category("CHAT").sizeBytes(1024L).build();
        long thirtyGb = 30L * 1024L * 1024L * 1024L;
        when(media.activeBytes()).thenReturn(thirtyGb, thirtyGb - 1024L);
        when(media.findByStatusAndCategoryAndDeleteAfterIsNotNullOrderByDeleteAfterAsc("ACTIVE", "CHAT"))
                .thenReturn(List.of(scheduledChat));

        service.ensureCapacity(1024L);

        verify(media).findByStatusAndCategoryAndDeleteAfterIsNotNullOrderByDeleteAfterAsc("ACTIVE", "CHAT");
        org.junit.jupiter.api.Assertions.assertEquals("DELETED", scheduledChat.getStatus());
        org.junit.jupiter.api.Assertions.assertEquals("STORAGE_LIMIT_30_GB", scheduledChat.getDeletedReason());
    }
}
