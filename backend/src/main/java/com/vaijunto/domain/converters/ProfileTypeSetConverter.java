package com.vaijunto.domain.converters;

import com.vaijunto.domain.enums.ProfileType;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.util.Arrays;
import java.util.EnumSet;
import java.util.Set;
import java.util.stream.Collectors;

@Converter
public class ProfileTypeSetConverter implements AttributeConverter<Set<ProfileType>, String> {

    @Override
    public String convertToDatabaseColumn(Set<ProfileType> attribute) {
        if (attribute == null || attribute.isEmpty()) {
            return "PASSENGER";
        }
        return attribute.stream()
                .map(Enum::name)
                .collect(Collectors.joining(","));
    }

    @Override
    public Set<ProfileType> convertToEntityAttribute(String dbData) {
        if (dbData == null || dbData.trim().isEmpty()) {
            return EnumSet.of(ProfileType.PASSENGER);
        }
        // Remove brackets if Postgres array string representation like {PASSENGER,VAN_DRIVER}
        String cleanData = dbData.replaceAll("[{}]", "");
        return Arrays.stream(cleanData.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(ProfileType::valueOf)
                .collect(Collectors.toCollection(() -> EnumSet.noneOf(ProfileType.class)));
    }
}
