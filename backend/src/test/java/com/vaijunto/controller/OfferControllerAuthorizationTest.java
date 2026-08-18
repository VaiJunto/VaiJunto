package com.vaijunto.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.vaijunto.dto.OfferDto;
import com.vaijunto.service.OfferService;
import com.vaijunto.security.JwtTokenProvider;
import com.vaijunto.security.UserDetailsServiceImpl;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(OfferController.class)
class OfferControllerAuthorizationTest {
    @Autowired MockMvc mvc;
    @MockBean OfferService offers;
    @MockBean JwtTokenProvider tokenProvider;
    @MockBean UserDetailsServiceImpl userDetailsService;

    @Test
    void commonAuthenticatedUserCanCreateOffer() throws Exception {
        when(offers.createOffer(any(), eq("user@fatec.sp.gov.br")))
                .thenReturn(OfferDto.builder().build());
        mvc.perform(post("/api/v1/offers")
                        .with(user("user@fatec.sp.gov.br").roles("USER"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isCreated());
    }

    @Test
    void missingTokenRemainsBlocked() throws Exception {
        mvc.perform(post("/api/v1/offers")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void invalidTokenRemainsBlocked() throws Exception {
        when(tokenProvider.validateToken("invalid")).thenReturn(false);
        mvc.perform(post("/api/v1/offers")
                        .header("Authorization", "Bearer invalid")
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isUnauthorized());
    }
}
