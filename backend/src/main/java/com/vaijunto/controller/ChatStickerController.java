package com.vaijunto.controller;
import com.vaijunto.domain.entities.ChatSticker;
import com.vaijunto.repository.ChatStickerRepository;
import java.time.OffsetDateTime;
import java.util.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController @RequiredArgsConstructor
public class ChatStickerController {
 private final ChatStickerRepository stickers;
 @GetMapping("/api/v1/stickers") public List<Map<String,String>> list(){return stickers.findByActiveTrueOrderByLabelAsc().stream().map(s->Map.of("id",s.getId().toString(),"code",s.getCode(),"label",s.getLabel())).toList();}
 @PostMapping("/api/v1/admin/stickers") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public void create(@RequestBody Map<String,String> body){stickers.save(ChatSticker.builder().code(body.get("code")).label(body.get("label")).active(true).createdAt(OffsetDateTime.now()).build());}
 @PatchMapping("/api/v1/admin/stickers/{id}") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public void active(@PathVariable UUID id,@RequestBody Map<String,Boolean> body){var sticker=stickers.findById(id).orElseThrow();sticker.setActive(Boolean.TRUE.equals(body.get("active")));}
}
