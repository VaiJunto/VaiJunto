package com.vaijunto.service;
import com.vaijunto.domain.enums.*;
import com.vaijunto.exception.ApiException;
import com.vaijunto.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.OffsetDateTime;
import java.util.*;
@Service @RequiredArgsConstructor public class AccountLifecycleService {
 private final UserRepository users; private final OfferRepository offers; private final DemandRepository demands; private final TripPassengerRepository passengers;
 public void requestDeletion(UUID id) { if (hasPending(id)) throw new ApiException(org.springframework.http.HttpStatus.CONFLICT,"ACCOUNT_HAS_PENDING_ITEMS","Resolva suas caronas, propostas ou solicitações pendentes antes de excluir a conta."); var u=users.findById(id).orElseThrow(ApiException::userNotFound); u.setDeletionRequestedAt(OffsetDateTime.now()); users.save(u); }
 private boolean hasPending(UUID id) { return offers.countByDriverIdAndStatusIn(id,List.of(OfferStatus.ACTIVE,OfferStatus.FULL))>0 || demands.countByPassengerIdAndStatusIn(id,List.of(DemandStatus.OPEN,DemandStatus.MATCHED))>0 || passengers.countByPassengerIdAndStatusIn(id,List.of(PassengerStatus.REQUESTED,PassengerStatus.CONFIRMED,PassengerStatus.CHECKED_IN))>0; }
 @Transactional @Scheduled(cron = "${app.accounts.anonymize-cron:0 15 3 * * *}") public void anonymizeExpiredRequests() { for (var u: users.findByDeletionRequestedAtBeforeAndAnonymizedAtIsNull(OffsetDateTime.now().minusDays(7))) { if (hasPending(u.getId())) continue; String token=u.getId().toString(); u.setName("Usuário removido"); u.setFullName("Usuário removido"); u.setEmail("deleted+"+token+"@invalid.vaijunto"); u.setPhone(null); u.setPhotoUrl(null); u.setCourse(null); u.setIsActive(false); u.setAnonymizedAt(OffsetDateTime.now()); } }
}
