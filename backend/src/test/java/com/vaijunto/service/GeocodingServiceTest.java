package com.vaijunto.service;

import com.vaijunto.dto.GeocodingResultDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.web.client.RestClient;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.client.ExpectedCount.once;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.queryParam;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

class GeocodingServiceTest {

    private MockRestServiceServer server;
    private GeocodingService service;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder();
        server = MockRestServiceServer.bindTo(builder).build();
        service = new GeocodingService(builder);
    }

    @Test
    void restringeAoValeEDevolveRotuloLegivelOrdenadoPorProximidade() {
        server.expect(once(), method(HttpMethod.GET))
                .andExpect(queryParam("countrycodes", "br"))
                .andExpect(queryParam("viewbox", "-46.35,-22.35,-44.25,-24.05"))
                .andExpect(queryParam("bounded", "1"))
                .andExpect(queryParam("addressdetails", "1"))
                .andRespond(withSuccess("""
                        [
                          {
                            "display_name": "Rua Longe, Taubaté, São Paulo, Brasil",
                            "name": "Rua Longe",
                            "lat": "-23.0260",
                            "lon": "-45.5550",
                            "address": {
                              "road": "Rua Longe",
                              "city": "Taubaté",
                              "state": "São Paulo",
                              "ISO3166-2-lvl4": "BR-SP"
                            }
                          },
                          {
                            "display_name": "Outro trecho da Rua Longe, Taubaté, São Paulo, Brasil",
                            "name": "Rua Longe",
                            "lat": "-23.0270",
                            "lon": "-45.5560",
                            "address": {
                              "road": "Rua Longe",
                              "city": "Taubaté",
                              "state": "São Paulo",
                              "ISO3166-2-lvl4": "BR-SP"
                            }
                          },
                          {
                            "display_name": "1350, Avenida Cesare Lattes, São José dos Campos",
                            "lat": "-23.1624",
                            "lon": "-45.7955",
                            "address": {
                              "house_number": "1350",
                              "road": "Avenida Cesare Lattes",
                              "suburb": "Eugênio de Melo",
                              "city": "São José dos Campos",
                              "ISO3166-2-lvl4": "BR-SP"
                            }
                          },
                          {
                            "display_name": "Parque Tecnológico, Avenida Cesare Lattes, São José dos Campos",
                            "name": "Parque Tecnológico",
                            "lat": "-23.1700",
                            "lon": "-45.8000",
                            "address": {
                              "road": "Avenida Cesare Lattes",
                              "suburb": "Eugênio de Melo",
                              "city": "São José dos Campos",
                              "ISO3166-2-lvl4": "BR-SP"
                            }
                          }
                        ]
                        """, org.springframework.http.MediaType.APPLICATION_JSON));

        List<GeocodingResultDto> results = service.search("Cesare Lattes");

        assertThat(results).hasSize(3);
        assertThat(results.get(0).getPrimaryText())
                .isEqualTo("Avenida Cesare Lattes, 1350");
        assertThat(results.get(0).getSecondaryText())
                .isEqualTo("Eugênio de Melo • São José dos Campos • SP");
        assertThat(results.get(0).getDistanceKm()).isLessThan(0.1);
        assertThat(results.get(1).getPrimaryText()).isEqualTo("Parque Tecnológico");
        assertThat(results.get(2).getPrimaryText()).isEqualTo("Rua Longe");
        server.verify();
    }
}
