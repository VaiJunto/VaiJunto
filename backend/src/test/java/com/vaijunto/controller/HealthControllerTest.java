package com.vaijunto.controller;

import com.vaijunto.security.JwtAuthenticationFilter;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.notNullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// Slice de teste (sem datasource/JPA) com os filtros de segurança desligados:
// o que se verifica aqui é o contrato do endpoint, não a config de segurança
// em si (isso é responsabilidade de um teste de SecurityConfig, se um dia existir).
// JwtAuthenticationFilter precisa ser excluído do scan porque @WebMvcTest inclui
// qualquer bean Filter por padrão — e ele exige JwtTokenProvider/UserDetailsService,
// que não existem nesta slice.
@WebMvcTest(
        controllers = HealthController.class,
        excludeFilters = @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = JwtAuthenticationFilter.class)
)
@AutoConfigureMockMvc(addFilters = false)
class HealthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void healthEndpointIsPublicAndReturnsUp() throws Exception {
        mockMvc.perform(get("/api/v1/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"))
                .andExpect(jsonPath("$.service").value("vaijunto-backend"))
                .andExpect(jsonPath("$.version").value(notNullValue()))
                .andExpect(jsonPath("$.timestamp").value(notNullValue()));
    }
}
