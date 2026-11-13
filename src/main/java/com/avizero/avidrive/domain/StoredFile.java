package com.avizero.avidrive.domain;
import jakarta.persistence.*;
@Entity @Table(name="files") public class StoredFile { @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id; @Column(nullable=false) public String name; @Column(name="storage_path") public String storagePath; @Column(name="owner_id") public Long ownerId; @Column(name="folder_id") public Long folderId; @Column(name="size_bytes") public Long sizeBytes; @Column(name="mime_type") public String mimeType; @Column(name="updated_at") public String updatedAt; }
