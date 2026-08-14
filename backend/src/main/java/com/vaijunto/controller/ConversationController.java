package com.vaijunto.controller;
import com.vaijunto.dto.ConversationDto; import com.vaijunto.service.ConversationService; import lombok.RequiredArgsConstructor; import org.springframework.security.core.Authentication; import org.springframework.web.bind.annotation.*; import java.util.*;
@RestController @RequestMapping("/api/v1/conversations") @RequiredArgsConstructor public class ConversationController {private final ConversationService service; @GetMapping public List<ConversationDto> list(Authentication a){return service.list(a.getName());}}
