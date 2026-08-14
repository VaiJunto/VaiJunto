package com.vaijunto.dto;

import lombok.Data;

/** Email is intentionally absent: institutional identity is immutable. */
@Data
public class UpdateProfileRequest {
    private String course;
    private String photoUrl;
}
