package com.vaijunto.dto;

import com.vaijunto.domain.entities.User;
import lombok.Builder;
import lombok.Value;

import java.util.UUID;

/** Safe representation for other riders: it deliberately never exposes e-mail or full name. */
@Value
@Builder
public class PublicProfileDto {
    UUID id;
    String firstName;
    String photoUrl;
    String course;
    boolean verified;

    public static PublicProfileDto fromEntity(User user) {
        String fullName = user.getFullName() == null ? user.getName() : user.getFullName();
        String firstName = fullName == null || fullName.isBlank() ? "Usuário" : fullName.trim().split("\\s+")[0];
        return PublicProfileDto.builder().id(user.getId()).firstName(firstName)
                .photoUrl(user.getPhotoUrl()).course(user.getCourse())
                .verified(Boolean.TRUE.equals(user.getVerificationBadgeActive())).build();
    }
}
