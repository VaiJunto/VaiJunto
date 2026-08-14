package com.vaijunto.dto;
import lombok.Builder;
import lombok.Value;
@Value @Builder public class AdminLoginResponse { String token; String role; }
