package com.vaijunto.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import com.vaijunto.domain.entities.AdminAccount;
import com.vaijunto.domain.entities.Conversation;
import com.vaijunto.domain.entities.ConversationMessage;
import com.vaijunto.domain.entities.User;
import com.vaijunto.exception.ApiException;
import com.vaijunto.repository.*;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class AdminOperationsServiceTest {
  private UserRepository users = mock(UserRepository.class);
  private AdminAccountRepository admins = mock(AdminAccountRepository.class);
  private AdminAuditEventRepository audits = mock(AdminAuditEventRepository.class);
  private NotificationService notifications = mock(NotificationService.class);
  private ConversationRepository conversations = mock(ConversationRepository.class);
  private ConversationMessageRepository messages = mock(ConversationMessageRepository.class);
  private AdminOperationsService service;
  private User user;
  private AdminAccount admin;

  @BeforeEach void setUp() {
    service = new AdminOperationsService(admins, audits, users, mock(MessageReportRepository.class), mock(ReportEvidenceSnapshotRepository.class), mock(ChatStickerRepository.class), notifications, conversations, messages, mock(VehicleRepository.class), mock(OfferRepository.class), mock(MediaStorageService.class), mock(AdminUserTagRepository.class), mock(AdminUserTagAssignmentRepository.class), mock(MediaObjectRepository.class));
    user = User.builder().id(UUID.randomUUID()).name("Ana").fullName("Ana Fatec").email("ana@fatec.sp.gov.br").build();
    admin = AdminAccount.builder().id(UUID.randomUUID()).email("admin@vaijunto.app").role("ADMIN").build();
    when(users.findById(user.getId())).thenReturn(Optional.of(user));
    when(admins.findByEmail("admin@vaijunto.app")).thenReturn(Optional.of(admin));
  }

  @Test void verificationRequiresReasonAndNeverSuspendsUser() {
    assertThrows(ApiException.class, () -> service.verify("admin@vaijunto.app", user.getId(), "GRANT", ""));
    service.verify("admin@vaijunto.app", user.getId(), "GRANT", "vínculo conferido");
    assertTrue(user.getVerificationBadgeActive());
    assertEquals("VERIFIED", user.getVerificationStatus());
    assertTrue(user.getIsActive());
    verify(audits).save(any());
    verify(notifications).createAndSendNotification(eq(user.getId()), anyString(), anyString(), eq("VERIFICATION_UPDATED"), anyString(), isNull());
  }

  @Test void suspensionRequiresReasonAndIsAudited() {
    assertThrows(ApiException.class, () -> service.moderate("admin@vaijunto.app", user.getId(), "SUSPEND", null));
    service.moderate("admin@vaijunto.app", user.getId(), "SUSPEND", "ameaça confirmada");
    assertFalse(user.getIsActive());
    assertNotNull(user.getSuspendedAt());
    verify(audits).save(any());
  }

  @Test void administrativeChatCanBeOpenedLoadedAndRepliedTo() {
    UUID conversationId = UUID.randomUUID();
    Conversation conversation = Conversation.builder()
        .id(conversationId)
        .type("ADMINISTRATIVE")
        .participantA(user)
        .adminAccount(admin)
        .lastActivityAt(OffsetDateTime.now())
        .build();
    when(conversations.findAdministrative(user.getId(), admin.getId()))
        .thenReturn(Optional.of(conversation));

    assertEquals(conversationId,
        service.openAdminConversation("admin@vaijunto.app", user.getId()));

    ConversationMessage incoming = ConversationMessage.builder()
        .id(UUID.randomUUID())
        .conversation(conversation)
        .sender(user)
        .clientId(UUID.randomUUID())
        .kind("TEXT")
        .body("Preciso de ajuda")
        .sentAt(OffsetDateTime.now())
        .build();
    when(conversations.findById(conversationId)).thenReturn(Optional.of(conversation));
    when(messages.findByConversationIdOrderBySentAtAsc(conversationId))
        .thenReturn(List.of(incoming));

    var history = service.adminConversation("admin@vaijunto.app", conversationId);
    assertEquals(1, history.size());
    assertEquals("Preciso de ajuda", history.get(0).get("body"));
    assertEquals(false, history.get(0).get("fromAdmin"));

    assertEquals(conversationId,
        service.sendAdminMessage("admin@vaijunto.app", conversationId,
            "Vamos ajudar você.", List.of()));
    verify(messages).save(argThat(message ->
        "Vamos ajudar você.".equals(message.getBody()) &&
            admin.equals(message.getAdminSender()) &&
            conversation.equals(message.getConversation())));
    verify(notifications).createAndSendNotification(
        eq(user.getId()), eq("VaiJunto"), contains("mensagem de"),
        eq("ADMIN_MESSAGE"), contains(conversationId.toString()), isNull());
  }
}
