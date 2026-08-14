package com.vaijunto.service;

import com.vaijunto.dto.GeocodingResultDto;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

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

    private static final double FATEC_LATITUDE = -23.1623356;
    private static final double FATEC_LONGITUDE = -45.7954102;

    // Retângulo que cobre o Vale do Paraíba paulista e cidades próximas.
    // O Nominatim espera: longitude oeste, latitude norte, longitude leste,
    // latitude sul.
    private static final String VALE_DO_PARAIBA_VIEWBOX =
            "-46.35,-22.35,-44.25,-24.05";

    private final RestClient restClient;

    public GeocodingService(RestClient.Builder restClientBuilder) {
        this.restClient = restClientBuilder
            .baseUrl("https://nominatim.openstreetmap.org")
            .defaultHeader("User-Agent", "VaiJunto/1.0 (app de caronas universitario)")
            .build();
    }

    @SuppressWarnings("unchecked")
    public List<GeocodingResultDto> search(String query) {
        return search(query, false);
    }

    public List<GeocodingResultDto> search(String query, boolean outsideRegion) {
        List<Map<String, Object>> results = restClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/search")
                        .queryParam("format", "jsonv2")
                        .queryParam("q", query)
                        .queryParam("countrycodes", "br")
                        .queryParam("accept-language", "pt-BR")
                        .queryParam("addressdetails", 1)
                        .queryParam("layer", "address,poi")
                        .queryParam("viewbox", VALE_DO_PARAIBA_VIEWBOX)
                        .queryParam("bounded", outsideRegion ? 0 : 1)
                        .queryParam("dedupe", 1)
                        .queryParam("limit", 10)
                        .build())
                .retrieve()
                .body(List.class);

        if (results == null) {
            return List.of();
        }

        Set<String> uniqueAddresses = new HashSet<>();
        return results.stream()
                .map(this::mapToDto)
                .sorted(Comparator.comparingDouble(GeocodingResultDto::getDistanceKm))
                .filter(result -> uniqueAddresses.add(
                        (result.getPrimaryText() + "|" + result.getSecondaryText())
                                .toLowerCase(Locale.ROOT)))
                .limit(6)
                .toList();
    }

    @SuppressWarnings("unchecked")
    private GeocodingResultDto mapToDto(Map<String, Object> raw) {
        Map<String, Object> address = raw.get("address") instanceof Map<?, ?>
                ? (Map<String, Object>) raw.get("address")
                : Map.of();
        String displayName = text(raw.get("display_name"));
        double latitude = Double.parseDouble(text(raw.get("lat")));
        double longitude = Double.parseDouble(text(raw.get("lon")));

        return GeocodingResultDto.builder()
                .displayName(displayName)
                .primaryText(primaryText(raw, address, displayName))
                .secondaryText(secondaryText(address))
                .latitude(latitude)
                .longitude(longitude)
                .distanceKm(distanceKm(latitude, longitude))
                .build();
    }

    private String primaryText(
            Map<String, Object> raw,
            Map<String, Object> address,
            String displayName) {
        String road = firstPresent(address, "road", "pedestrian", "footway");
        String houseNumber = text(address.get("house_number"));
        String name = text(raw.get("name"));

        // Em pontos de referência, o nome do local é mais útil que a rua.
        // Para ruas, Nominatim costuma repetir o mesmo valor em name e road.
        if (!name.isBlank() && !name.equalsIgnoreCase(road)) {
            return name;
        }
        if (!road.isBlank() && !houseNumber.isBlank()) {
            return road + ", " + houseNumber;
        }
        if (!name.isBlank()) {
            return name;
        }
        if (!road.isBlank()) {
            return road;
        }
        int comma = displayName.indexOf(',');
        return comma > 0 ? displayName.substring(0, comma) : displayName;
    }

    private String secondaryText(Map<String, Object> address) {
        Set<String> parts = new LinkedHashSet<>();
        addIfPresent(parts, firstPresent(
                address, "neighbourhood", "suburb", "city_district", "quarter"));
        addIfPresent(parts, firstPresent(
                address, "city", "town", "municipality", "village"));

        String stateCode = text(address.get("ISO3166-2-lvl4"));
        if (stateCode.startsWith("BR-") && stateCode.length() == 5) {
            stateCode = stateCode.substring(3);
        } else {
            stateCode = text(address.get("state"));
        }
        addIfPresent(parts, stateCode);

        return String.join(" • ", parts);
    }

    private String firstPresent(Map<String, Object> values, String... keys) {
        for (String key : keys) {
            String value = text(values.get(key));
            if (!value.isBlank()) {
                return value;
            }
        }
        return "";
    }

    private void addIfPresent(Set<String> values, String value) {
        if (!value.isBlank()) {
            values.add(value);
        }
    }

    private String text(Object value) {
        return value == null ? "" : value.toString().trim();
    }

    private double distanceKm(double latitude, double longitude) {
        double earthRadiusKm = 6371.0088;
        double latitudeDelta = Math.toRadians(latitude - FATEC_LATITUDE);
        double longitudeDelta = Math.toRadians(longitude - FATEC_LONGITUDE);
        double originLatitude = Math.toRadians(FATEC_LATITUDE);
        double destinationLatitude = Math.toRadians(latitude);
        double a = Math.sin(latitudeDelta / 2) * Math.sin(latitudeDelta / 2)
                + Math.cos(originLatitude) * Math.cos(destinationLatitude)
                * Math.sin(longitudeDelta / 2) * Math.sin(longitudeDelta / 2);
        return earthRadiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
