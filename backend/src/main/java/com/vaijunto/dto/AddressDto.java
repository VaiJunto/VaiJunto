package com.vaijunto.dto;
import com.vaijunto.domain.entities.SavedAddress; import java.time.OffsetDateTime; import java.util.UUID;
public record AddressDto(UUID id, String label, String addressName, double latitude, double longitude, boolean recent, OffsetDateTime expiresAt) { public static AddressDto from(SavedAddress a) { return new AddressDto(a.getId(),a.getLabel(),a.getAddressName(),a.getLatitude(),a.getLongitude(),a.isRecent(),a.getExpiresAt()); } }
