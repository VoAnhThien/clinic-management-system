package com.clinic.entity;

import com.clinic.enums.UserRole;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class User extends BaseEntity {
    @Column(length = 255, unique = true)
    private String email;

    @Column(length = 15, unique = true)
    private String phone;

    @Column(name = "national_id", length = 20, unique = true)
    private String nationalId;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(nullable = false, length = 20)
    @Builder.Default
    private UserRole role = UserRole.PATIENT;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private Boolean isActive = true;

    @Column(name = "last_login_at")
    private LocalDateTime lastLoginAt;

    @Column(name = "refresh_token_hash")
    private String refreshTokenHash;
}