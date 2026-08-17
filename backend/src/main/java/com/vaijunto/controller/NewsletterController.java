package com.vaijunto.controller;

import com.vaijunto.service.AdminNewsletterService;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

/** Leitura da newsletter pelo destinatário. Marca como lida no primeiro acesso. */
@RestController
@RequestMapping("/api/v1/newsletters")
@RequiredArgsConstructor
public class NewsletterController {
    private final AdminNewsletterService newsletters;

    @GetMapping("/{id}")
    public Map<String, Object> read(@PathVariable UUID id, Authentication auth) {
        return newsletters.read(id, auth.getName());
    }
}
