package com.vaijunto.controller;
import com.vaijunto.repository.ChatStickerRepository;
import com.vaijunto.service.ChatStickerAssetService;
import java.util.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController @RequiredArgsConstructor
public class ChatStickerController {
 private final ChatStickerRepository stickers; private final ChatStickerAssetService assets;
 @GetMapping("/api/v1/stickers") public List<Map<String,String>> list(){return stickers.findByActiveTrueOrderByLabelAsc().stream().map(s->Map.of("id",s.getId().toString(),"code",s.getCode(),"label",s.getLabel(),"assetPath","/stickers/"+s.getId()+"/asset")).toList();}
 @GetMapping("/api/v1/stickers/{id}/asset") public ResponseEntity<Void> asset(@PathVariable UUID id){return ResponseEntity.status(302).location(assets.assetUrl(id)).build();}
 @PostMapping(value="/api/v1/admin/stickers", consumes=MediaType.MULTIPART_FORM_DATA_VALUE) @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public void create(@RequestParam String code,@RequestParam String label,@RequestPart("asset") MultipartFile asset){assets.create(code,label,asset);}
 @PatchMapping("/api/v1/admin/stickers/{id}") @PreAuthorize("hasAnyRole('SUPER_ADMIN','ADMIN')") public void active(@PathVariable UUID id,@RequestBody Map<String,Boolean> body){var sticker=stickers.findById(id).orElseThrow();sticker.setActive(Boolean.TRUE.equals(body.get("active")));}
}
