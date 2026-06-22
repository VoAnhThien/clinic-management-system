package com.clinic.dto.response;

import com.clinic.enums.UserRole;
import lombok.*;
import java.util.UUID;

@Getter @Setter @Builder @AllArgsConstructor @NoArgsConstructor
public class AuthResponse {
    private String accessToken;
    private String refreshToken;
    private String tokenType;
    private long expiresIn;
    private UUID userId;
    private String fullName;
    private UserRole role;
}