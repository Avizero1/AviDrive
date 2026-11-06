package com.avizero.avidrive.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "file_permissions", uniqueConstraints = @UniqueConstraint(columnNames = {"file_id", "user_id"}))
@Getter @Setter @NoArgsConstructor
public class FilePermission {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "file_id", nullable = false)
    private FileEntry file;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "user_id", nullable = false)
    private User user;
    @Column(nullable = false, columnDefinition = "TEXT")
    private String permissions;
    @Column(name = "granted_at", nullable = false)
    private LocalDateTime grantedAt = LocalDateTime.now();
    public void setFile(FileEntry file) { this.file = file; }
    public void setUser(User user) { this.user = user; }
    public void setPermissions(String permissions) { this.permissions = permissions; }
    public void setGrantedAt(LocalDateTime grantedAt) { this.grantedAt = grantedAt; }
}
