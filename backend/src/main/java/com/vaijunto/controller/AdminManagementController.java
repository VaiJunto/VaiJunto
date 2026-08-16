package com.vaijunto.controller;

import com.vaijunto.domain.entities.AdminAuditEvent;
import com.vaijunto.exception.ApiException;
import com.vaijunto.repository.AdminAccountRepository;
import com.vaijunto.repository.AdminAuditEventRepository;
import com.vaijunto.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.*;

/** Admin-only operations; roles originate only from the separate admin_accounts store. */
@RestController @RequestMapping("/api/v1/admin") @RequiredArgsConstructor
@PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN','MODERATOR')")
public class AdminManagementController {
 private final UserRepository users; private final AdminAccountRepository admins; private final AdminAuditEventRepository audits;
 private final com.vaijunto.service.AdminProvisioningService provisioning;
 private final com.vaijunto.service.AdminOperationsService operations;
 @PostMapping("/invites") @PreAuthorize("hasRole('SUPER_ADMIN')") public void invite(@RequestBody com.vaijunto.dto.AdminInviteRequest request, Authentication auth) { provisioning.invite(auth.getName(), request); }
 @GetMapping("/name-changes") public List<Map<String,Object>> nameChanges() { return users.findByNameChangeStatus("PENDING").stream().map(u -> Map.<String,Object>of("id",u.getId(),"currentName",u.getFullName(),"requestedName",u.getRequestedFullName())).toList(); }
 @PostMapping("/name-changes/{id}/approve") public void approveName(@PathVariable UUID id, Authentication auth) { var u=users.findById(id).orElseThrow(ApiException::userNotFound); if (!"PENDING".equals(u.getNameChangeStatus())) throw new IllegalArgumentException("Não há alteração pendente."); u.setFullName(u.getRequestedFullName()); u.setName(u.getRequestedFullName()); u.setRequestedFullName(null); u.setNameChangeStatus("APPROVED"); audit(auth,"NAME_CHANGE_APPROVED","USER",id.toString()); }
 @PostMapping("/name-changes/{id}/reject") public void rejectName(@PathVariable UUID id, Authentication auth) { var u=users.findById(id).orElseThrow(ApiException::userNotFound); u.setRequestedFullName(null); u.setNameChangeStatus("REJECTED"); audit(auth,"NAME_CHANGE_REJECTED","USER",id.toString()); }
 @PatchMapping("/accounts/{id}/role") @PreAuthorize("hasRole('SUPER_ADMIN')") public void changeRole(@PathVariable UUID id,@RequestBody Map<String,String> body,Authentication auth) { String role=body.getOrDefault("role",""); if (!Set.of("SUPER_ADMIN","ADMIN","MODERATOR").contains(role)) throw new IllegalArgumentException("Papel administrativo inválido."); var account=admins.findById(id).orElseThrow(()->new IllegalArgumentException("Administrador não encontrado.")); account.setRole(role); admins.save(account); audit(auth,"ADMIN_ROLE_CHANGED","ADMIN",id.toString()); }
 @GetMapping("/search") public List<Map<String,Object>> search(@RequestParam String q){return operations.search(q);}
 @GetMapping("/vehicles/search") public List<Map<String,Object>> searchVehicles(@RequestParam String q){return operations.searchVehicles(q);}
 @GetMapping("/offers") public List<Map<String,Object>> offers(){return operations.recentOffers();}
 @PostMapping("/users/{id}/verification") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public Map<String,Object> verification(@PathVariable UUID id,@RequestBody Map<String,String> body,Authentication auth){return operations.verify(auth.getName(),id,body.get("action"),body.get("reason"));}
 @PostMapping("/users/{id}/moderation") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN','MODERATOR')") public Map<String,Object> moderation(@PathVariable UUID id,@RequestBody Map<String,String> body,Authentication auth){return operations.moderate(auth.getName(),id,body.get("action"),body.get("reason"));}
 @GetMapping("/reports") public List<Map<String,Object>> reports(@RequestParam(required=false) String status){return operations.reportQueue(status);}
 @GetMapping("/reports/{id}/evidence") public List<Map<String,Object>> evidence(@PathVariable UUID id,Authentication auth){return operations.reportEvidence(auth.getName(),id);}
 @PatchMapping("/reports/{id}") public void updateReport(@PathVariable UUID id,@RequestBody Map<String,String> body,Authentication auth){operations.updateReport(auth.getName(),id,body.get("status"),body.get("reason"));}
 @DeleteMapping("/reports/{reportId}/media/{mediaId}") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public void removeEvidenceMedia(@PathVariable UUID reportId,@PathVariable UUID mediaId,@RequestBody Map<String,String> body,Authentication auth){operations.removeEvidenceMedia(auth.getName(),reportId,mediaId,body.get("reason"));}
 @GetMapping("/stickers") public List<Map<String,Object>> stickers(){return operations.stickers();}
 @PatchMapping("/stickers/{id}/state") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public void sticker(@PathVariable UUID id,@RequestBody Map<String,Object> body,Authentication auth){operations.setSticker(auth.getName(),id,Boolean.TRUE.equals(body.get("active")),(String)body.get("reason"));}
 @PostMapping("/conversations") public Map<String,UUID> contact(@RequestBody Map<String,String> body,Authentication auth){return Map.of("conversationId",operations.contact(auth.getName(),UUID.fromString(body.get("userId")),body.get("body")));}
 private void audit(Authentication auth,String event,String type,String target) { var actor=admins.findByEmail(auth.getName()).orElseThrow(()->new IllegalStateException("Administrador não encontrado.")); audits.save(AdminAuditEvent.builder().admin(actor).eventType(event).targetType(type).targetId(target).build()); }
}
