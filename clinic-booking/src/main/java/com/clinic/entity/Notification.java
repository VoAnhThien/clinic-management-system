package com.clinic.entity;

import com.clinic.enums.NotificationType;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "notifications")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class Notification {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30) @Builder.Default
    private NotificationType type = NotificationType.GENERAL;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String body;

    @Column(name = "ref_id")
    private UUID refId;

    @Column(name = "is_read", nullable = false) @Builder.Default
    private Boolean isRead = false;

    @Column(name = "sent_at", nullable = false, updatable = false) @Builder.Default
    private LocalDateTime sentAt = LocalDateTime.now();
}