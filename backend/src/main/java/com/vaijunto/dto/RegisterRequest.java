package com.vaijunto.dto;

import com.vaijunto.domain.enums.ProfileType;
import lombok.*;

import java.util.Set;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RegisterRequest {

    private String name;
    private String email;
    private String password;
    private String phone;
    private Set<ProfileType> profileTypes;
    private UUID universityId;
}
