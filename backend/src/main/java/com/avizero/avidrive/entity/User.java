package com.avizero.avidrive.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
@Getter @Setter @NoArgsConstructor
public class User {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, unique = true, length = 50)
    private String username;
    @Column(name = "password_hash", nullable = false)
    private String passwordHash;
    @Column(nullable = false, length = 50)
    private String role;
    @Column(name = "quota_mb", nullable = false)
    private Long quotaMb = 0L;
    @Column(name = "used_space_mb", nullable = false)
    private Long usedSpaceMb = 0L;
    @Column(name = "is_blocked", nullable = false)
    private boolean blocked;
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public Long getId() { return id; }
    public String getUsername() { return username; }
    public String getPasswordHash() { return passwordHash; }
    public String getRole() { return role; }
    public Long getQuotaMb() { return quotaMb; }
    public Long getUsedSpaceMb() { return usedSpaceMb; }
    public boolean isBlocked() { return blocked; }
    public void setPasswordHash(String passwordHash) { this.passwordHash = passwordHash; }
    public void setUsername(String username) { this.username = username; }
    public void setRole(String role) { this.role = role; }
    public void setQuotaMb(Long quotaMb) { this.quotaMb = quotaMb; }
}
