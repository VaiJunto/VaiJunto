package com.vaijunto.dto;

import com.vaijunto.domain.entities.User;
import com.vaijunto.domain.enums.ProfileType;
import lombok.*;

import java.util.Set;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserDto {

    private UUID id;
    private String name;
    private String fullName;
    private String email;
    private String phone;
    private String course;
    private String photoUrl;
    private Boolean verificationBadgeActive;
    private Set<ProfileType> profileTypes;
    private UUID universityId;
    private String universityName;

    public static UserDto fromEntity(User user) {
        return UserDto.builder()
                .id(user.getId())
                .name(user.getName())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .course(user.getCourse())
                .photoUrl(user.getPhotoUrl())
                .verificationBadgeActive(user.getVerificationBadgeActive())
                .profileTypes(user.getProfileTypes())
                .universityId(user.getUniversity() != null ? user.getUniversity().getId() : null)
                .universityName(user.getUniversity() != null ? user.getUniversity().getName() : null)
                .build();
    }
}
