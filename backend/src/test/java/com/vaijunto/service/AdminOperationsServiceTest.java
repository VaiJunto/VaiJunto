package com.vaijunto.service;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import com.vaijunto.domain.entities.AdminAccount;
import com.vaijunto.domain.entities.User;
import com.vaijunto.exception.ApiException;
import com.vaijunto.repository.*;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class AdminOperationsServiceTest {
  private UserRepository users = mock(UserRepository.class);
  private AdminAccountRepository admins = mock(AdminAccountRepository.class);
  private AdminAuditEventRepository audits = mock(AdminAuditEventRepository.class);
  private NotificationService notifications = mock(NotificationService.class);
  private AdminOperationsService service;
  private User user;

  @BeforeEach void setUp() {
    service = new AdminOperationsService(admins, audits, users, mock(MessageReportRepository.class), mock(ReportEvidenceSnapshotRepository.class), mock(ChatStickerRepository.class), notifications, mock(ConversationRepository.class), mock(ConversationMessageRepository.class), mock(VehicleRepository.class), mock(OfferRepository.class), mock(MediaStorageService.class), mock(AdminUserTagRepository.class), mock(AdminUserTagAssignmentRepository.class));
    user = User.builder().id(UUID.randomUUID()).name("Ana").fullName("Ana Fatec").email("ana@fatec.sp.gov.br").build();
    when(users.findById(user.getId())).thenReturn(Optional.of(user));
    when(admins.findByEmail("admin@vaijunto.app")).thenReturn(Optional.of(AdminAccount.builder().id(UUID.randomUUID()).email("admin@vaijunto.app").build()));
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
}
