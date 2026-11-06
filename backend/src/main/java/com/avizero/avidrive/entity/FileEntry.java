package com.avizero.avidrive.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "files")
@Getter @Setter @NoArgsConstructor
public class FileEntry {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(nullable = false, length = 255)
    private String name;
    @Column(nullable = false, length = 1000)
    private String path;
    @Column(name = "is_directory", nullable = false)
    private boolean directory;
    @Column(name = "size_bytes", nullable = false)
    private Long sizeBytes = 0L;
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "parent_id")
    private FileEntry parent;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt = LocalDateTime.now();

    public Long getId() { return id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getPath() { return path; }
    public void setPath(String path) { this.path = path; }
    public void setDirectory(boolean directory) { this.directory = directory; }
    public boolean isDirectory() { return directory; }
    public void setSizeBytes(Long sizeBytes) { this.sizeBytes = sizeBytes; }
    public FileEntry getParent() { return parent; }
    public void setParent(FileEntry parent) { this.parent = parent; }
    public User getOwner() { return owner; }
    public void setOwner(User owner) { this.owner = owner; }
}
