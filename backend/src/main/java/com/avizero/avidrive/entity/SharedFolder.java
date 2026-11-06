package com.avizero.avidrive.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "shared_folders")
@Getter @Setter @NoArgsConstructor
public class SharedFolder {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(nullable = false, length = 255) private String name;
    @ManyToOne(fetch = FetchType.LAZY, optional = false) @JoinColumn(name = "owner_id", nullable = false) private User owner;
    @Column(name = "quota_mb", nullable = false) private Long quotaMb = 0L;
    @Column(name = "used_space_mb", nullable = false) private Long usedSpaceMb = 0L;
    @Column(name = "created_at", nullable = false) private LocalDateTime createdAt = LocalDateTime.now();
    public void setName(String name) { this.name = name; }
    public void setOwner(User owner) { this.owner = owner; }
    public void setQuotaMb(Long quotaMb) { this.quotaMb = quotaMb; }
}
