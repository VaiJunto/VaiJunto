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
 private final com.vaijunto.service.AdminNewsletterService newsletterService;
 private final com.vaijunto.service.MediaStorageService media;
 @GetMapping("/accounts") @PreAuthorize("hasRole('SUPER_ADMIN')") public List<Map<String,Object>> accounts(){return admins.findAll().stream().map(a->Map.<String,Object>of("id",a.getId(),"email",a.getEmail(),"role",a.getRole(),"active",a.getIsActive(),"createdAt",a.getCreatedAt())).toList();}
 @PostMapping("/accounts/preview") @PreAuthorize("hasRole('SUPER_ADMIN')") public Map<String,Object> previewAccount(@RequestBody Map<String,String> body) { return provisioning.preview(body.get("email"),body.get("role"),body.get("password")); }
 @PostMapping("/accounts") @PreAuthorize("hasRole('SUPER_ADMIN')") public Map<String,Object> createAccount(@RequestBody Map<String,String> body, Authentication auth) { return provisioning.create(auth.getName(),body.get("email"),body.get("role"),body.get("password"),body.get("totpSecret"),body.get("totpCode")); }
 @DeleteMapping("/accounts/{id}") @PreAuthorize("hasRole('SUPER_ADMIN')") public void softDeleteAccount(@PathVariable UUID id, Authentication auth) { provisioning.setAccountActive(auth.getName(),id,false); }
 @PostMapping("/accounts/{id}/restore") @PreAuthorize("hasRole('SUPER_ADMIN')") public void restoreAccount(@PathVariable UUID id, Authentication auth) { provisioning.setAccountActive(auth.getName(),id,true); }
 @PostMapping("/auth/password") public void changeOwnPassword(@RequestBody Map<String,String> body, Authentication auth) { provisioning.changePassword(auth.getName(),body.get("currentPassword"),body.get("newPassword"),body.get("totpCode")); }
 @PostMapping("/invites") @PreAuthorize("hasRole('SUPER_ADMIN')") public void invite(@RequestBody com.vaijunto.dto.AdminInviteRequest request, Authentication auth) { provisioning.invite(auth.getName(), request); }
 @GetMapping("/name-changes") public List<Map<String,Object>> nameChanges() { return users.findByNameChangeStatus("PENDING").stream().map(u -> Map.<String,Object>of("id",u.getId(),"currentName",u.getFullName(),"requestedName",u.getRequestedFullName())).toList(); }
 @PostMapping("/name-changes/{id}/approve") public void approveName(@PathVariable UUID id, Authentication auth) { var u=users.findById(id).orElseThrow(ApiException::userNotFound); if (!"PENDING".equals(u.getNameChangeStatus())) throw new IllegalArgumentException("Não há alteração pendente."); u.setFullName(u.getRequestedFullName()); u.setName(u.getRequestedFullName()); u.setRequestedFullName(null); u.setNameChangeStatus("APPROVED"); audit(auth,"NAME_CHANGE_APPROVED","USER",id.toString()); }
 @PostMapping("/name-changes/{id}/reject") public void rejectName(@PathVariable UUID id, Authentication auth) { var u=users.findById(id).orElseThrow(ApiException::userNotFound); u.setRequestedFullName(null); u.setNameChangeStatus("REJECTED"); audit(auth,"NAME_CHANGE_REJECTED","USER",id.toString()); }
 @PatchMapping("/accounts/{id}/role") @PreAuthorize("hasRole('SUPER_ADMIN')") public void changeRole(@PathVariable UUID id,@RequestBody Map<String,String> body,Authentication auth) { String role=body.getOrDefault("role",""); if (!Set.of("SUPER_ADMIN","ADMIN","MODERATOR").contains(role)) throw new IllegalArgumentException("Papel administrativo inválido."); var account=admins.findById(id).orElseThrow(()->new IllegalArgumentException("Administrador não encontrado.")); account.setRole(role); admins.save(account); audit(auth,"ADMIN_ROLE_CHANGED","ADMIN",id.toString()); }
 @GetMapping("/search") public List<Map<String,Object>> search(@RequestParam String q){return operations.search(q);}
 @GetMapping("/users") public List<Map<String,Object>> users(){return operations.recentUsers();}
 @GetMapping("/vehicles/search") public List<Map<String,Object>> searchVehicles(@RequestParam String q){return operations.searchVehicles(q);}
 @GetMapping("/offers") public List<Map<String,Object>> offers(){return operations.recentOffers();}
 @PostMapping("/users/{id}/verification") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public Map<String,Object> verification(@PathVariable UUID id,@RequestBody Map<String,String> body,Authentication auth){return operations.verify(auth.getName(),id,body.get("action"),body.get("reason"));}
 @PostMapping("/users/{id}/moderation") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN','MODERATOR')") public Map<String,Object> moderation(@PathVariable UUID id,@RequestBody Map<String,String> body,Authentication auth){return operations.moderate(auth.getName(),id,body.get("action"),body.get("reason"));}
 @PostMapping("/users/{id}/deletion") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public Map<String,Object> deletion(@PathVariable UUID id,@RequestBody Map<String,String> body,Authentication auth){return operations.setDeleted(auth.getName(),id,body.get("action"),body.get("reason"));}
 @GetMapping("/reports") public List<Map<String,Object>> reports(@RequestParam(required=false) String status){return operations.reportQueue(status);}
 @GetMapping("/reports/{id}/evidence") public List<Map<String,Object>> evidence(@PathVariable UUID id,Authentication auth){return operations.reportEvidence(auth.getName(),id);}
 @PatchMapping("/reports/{id}") public void updateReport(@PathVariable UUID id,@RequestBody Map<String,String> body,Authentication auth){operations.updateReport(auth.getName(),id,body.get("status"),body.get("reason"));}
 @DeleteMapping("/reports/{reportId}/media/{mediaId}") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public void removeEvidenceMedia(@PathVariable UUID reportId,@PathVariable UUID mediaId,@RequestBody Map<String,String> body,Authentication auth){operations.removeEvidenceMedia(auth.getName(),reportId,mediaId,body.get("reason"));}
 @GetMapping("/stickers") public List<Map<String,Object>> stickers(){return operations.stickers();}
 @PatchMapping("/stickers/{id}/state") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public void sticker(@PathVariable UUID id,@RequestBody Map<String,Object> body,Authentication auth){operations.setSticker(auth.getName(),id,Boolean.TRUE.equals(body.get("active")),(String)body.get("reason"));}
 @PostMapping("/conversations") public Map<String,UUID> contact(@RequestBody Map<String,Object> body,Authentication auth){return Map.of("conversationId",operations.contact(auth.getName(),UUID.fromString(String.valueOf(body.get("userId"))),(String)body.get("body"),ids(body.get("mediaIds"))));}
 @PostMapping("/users/{id}/conversation") public Map<String,UUID> openConversation(@PathVariable UUID id,Authentication auth){return Map.of("conversationId",operations.openAdminConversation(auth.getName(),id));}
 @GetMapping("/conversations/{id}/messages") public List<Map<String,Object>> adminConversation(@PathVariable UUID id,Authentication auth){return operations.adminConversation(auth.getName(),id);}
 @PostMapping("/conversations/{id}/messages") public Map<String,UUID> sendAdminMessage(@PathVariable UUID id,@RequestBody Map<String,Object> body,Authentication auth){return Map.of("conversationId",operations.sendAdminMessage(auth.getName(),id,(String)body.get("body"),ids(body.get("mediaIds"))));}
 @GetMapping("/newsletters") public List<Map<String,Object>> newsletters(){return newsletterService.list();}
 @PostMapping("/newsletters") public Map<String,Object> createNewsletter(@RequestBody Map<String,Object> body,Authentication auth){return newsletterService.create(auth.getName(),body);}
 @GetMapping("/newsletters/{id}") public Map<String,Object> newsletter(@PathVariable UUID id){return newsletterService.content(id);}
 @PostMapping("/newsletters/{id}/cancel") public Map<String,Object> cancelNewsletter(@PathVariable UUID id,Authentication auth){return newsletterService.cancel(auth.getName(),id);}
 @PostMapping("/newsletters/audience") public Map<String,Object> audience(@RequestBody Map<String,Object> body){return newsletterService.previewAudience(body);}
 @GetMapping("/courses") public List<Map<String,Object>> courses(@RequestParam(required=false) String q){return newsletterService.courses(q);}
 /** Upload de anexo do painel: os bytes passam pelo backend porque o painel é web e o R2 exigiria CORS. */
 @PostMapping("/media") public Map<String,Object> uploadMedia(@RequestParam("file") org.springframework.web.multipart.MultipartFile file,@RequestParam(defaultValue="NEWSLETTER") String category,@RequestParam(required=false) String contentType,@RequestParam(required=false) Integer durationSeconds,Authentication auth) throws java.io.IOException {var type=contentType==null||contentType.isBlank()?file.getContentType():contentType;var id=media.uploadAdminMedia(auth.getName(),category,type,file.getSize(),durationSeconds,file.getBytes());return Map.of("mediaId",id,"url",media.adminMediaUrl(id));}
 @GetMapping("/tags") public List<Map<String,Object>> tags(){return operations.tags();}
 @PostMapping("/tags") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public Map<String,Object> createTag(@RequestBody Map<String,String> body,Authentication auth){return operations.createTag(auth.getName(),body.get("name"),body.get("color"),body.get("iconSvg"));}
 @PostMapping("/users/{id}/tags/{tagId}") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public List<Map<String,Object>> assignTag(@PathVariable UUID id,@PathVariable UUID tagId,Authentication auth){return operations.assignTag(auth.getName(),id,tagId);}
 @DeleteMapping("/users/{id}/tags/{tagId}") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public List<Map<String,Object>> removeTag(@PathVariable UUID id,@PathVariable UUID tagId,Authentication auth){return operations.unassignTag(auth.getName(),id,tagId);}
 @SuppressWarnings("unchecked") private static List<UUID> ids(Object raw){if(!(raw instanceof List<?> list))return List.of();return ((List<Object>)list).stream().map(v->UUID.fromString(String.valueOf(v))).toList();}
 private void audit(Authentication auth,String event,String type,String target) { var actor=admins.findByEmail(auth.getName()).orElseThrow(()->new IllegalStateException("Administrador não encontrado.")); audits.save(AdminAuditEvent.builder().admin(actor).eventType(event).targetType(type).targetId(target).build()); }
}
