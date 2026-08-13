package com.vaijunto.service;

import com.vaijunto.dto.GeocodingResultDto;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Busca de endereço via Nominatim (OpenStreetMap) — gratuito, sem chave de
 * API. Proxiado pelo backend por dois motivos: o Nominatim não devolve
 * cabeçalho CORS (uma chamada direta do Flutter web seria bloqueada pelo
 * navegador) e a política de uso deles exige um User-Agent identificando a
 * aplicação, mais rate limit de ~1 req/s por cliente — mais fácil de
 * garantir num único lugar do que em cada app instalado.
 *
 * Para produção com volume real, trocar por um provedor com SLA (Google
 * Places, Mapbox etc.) — o Nominatim público não é pensado para isso.
 */
@Service
public class GeocodingService {

    private final RestClient restClient = RestClient.builder()
            .baseUrl("https://nominatim.openstreetmap.org")
            .defaultHeader("User-Agent", "VaiJunto/1.0 (app de caronas universitario)")
            .build();

    @SuppressWarnings("unchecked")
    public List<GeocodingResultDto> search(String query) {
        List<Map<String, Object>> results = restClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/search")
                        .queryParam("format", "json")
                        .queryParam("q", query)
                        .queryParam("countrycodes", "br")
                        .queryParam("limit", 5)
                        .build())
                .retrieve()
                .body(List.class);

        if (results == null) {
            return List.of();
        }

        return results.stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    private GeocodingResultDto mapToDto(Map<String, Object> raw) {
        return GeocodingResultDto.builder()
                .displayName((String) raw.get("display_name"))
                .latitude(Double.parseDouble((String) raw.get("lat")))
                .longitude(Double.parseDouble((String) raw.get("lon")))
                .build();
    }
}
