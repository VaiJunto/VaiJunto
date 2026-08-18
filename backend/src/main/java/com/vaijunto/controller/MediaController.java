package com.vaijunto.controller;

import com.vaijunto.dto.*;
import com.vaijunto.service.MediaStorageService;
import jakarta.validation.Valid;
import java.io.IOException;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/media")
@RequiredArgsConstructor
public class MediaController {
    private final MediaStorageService service;

    @PostMapping("/upload-intents")
    public MediaUploadIntentDto intent(@Valid @RequestBody MediaUploadIntentRequest request, Authentication auth) {
        return service.intent(request, auth.getName());
    }

    @PostMapping("/upload")
    public Map<String, UUID> upload(@RequestParam UUID conversationId,
                                    @RequestParam String contentType,
                                    @RequestParam(required = false) Integer durationSeconds,
                                    @RequestParam("file") MultipartFile file,
                                    Authentication auth) throws IOException {
        UUID id = service.uploadChatMedia(auth.getName(), conversationId, contentType,
                file.getSize(), durationSeconds, file.getBytes());
        return Map.of("mediaId", id);
    }

    @PostMapping("/{id}/complete")
    public void complete(@PathVariable UUID id, Authentication auth) {
        service.complete(id, auth.getName());
    }

    @GetMapping("/{id}/download-url")
    public MediaDownloadUrlDto url(@PathVariable UUID id, Authentication auth) {
        return service.downloadUrl(id, auth.getName());
    }
}
