package com.avizero.avidrive.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "share_links")
@Getter @Setter @NoArgsConstructor
public class ShareLink {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, length = 255) private String token;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "file_id", nullable = false) private FileEntry file;
    @Column(name = "password_hash") private String passwordHash;
    @Column(nullable = false, columnDefinition = "TEXT") private String permissions;
    @Column(name = "expires_at") private LocalDateTime expiresAt;
    @Column(name = "max_file_size_mb", nullable = false) private Long maxFileSizeMb = 0L;
    @Column(name = "max_total_size_mb", nullable = false) private Long maxTotalSizeMb = 0L;
    @Column(name = "view_count", nullable = false) private Long viewCount = 0L;
    @Column(name = "download_count", nullable = false) private Long downloadCount = 0L;
    @Column(name = "upload_count", nullable = false) private Long uploadCount = 0L;
    @Column(name = "last_accessed_at") private LocalDateTime lastAccessedAt;
    @Column(name = "created_at", nullable = false) private LocalDateTime createdAt = LocalDateTime.now();
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "created_by", nullable = false) private User createdBy;
}
