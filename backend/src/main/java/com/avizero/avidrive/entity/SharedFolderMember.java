package com.avizero.avidrive.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "shared_folder_members", uniqueConstraints = @UniqueConstraint(columnNames = {"folder_id", "user_id"}))
@Getter @Setter @NoArgsConstructor
public class SharedFolderMember {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "folder_id", nullable = false) private SharedFolder folder;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "user_id", nullable = false) private User user;
    @Column(nullable = false, columnDefinition = "TEXT") private String permissions;
    @Column(name = "max_file_size_mb", nullable = false) private Long maxFileSizeMb = 0L;
    @Column(name = "max_user_space_mb", nullable = false) private Long maxUserSpaceMb = 0L;
    @Column(name = "used_space_mb", nullable = false) private Long usedSpaceMb = 0L;
    @Column(name = "joined_at", nullable = false) private LocalDateTime joinedAt = LocalDateTime.now();
}
