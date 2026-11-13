package com.avizero.avidrive.domain;
import java.io.Serializable; import jakarta.persistence.*;
@Entity @Table(name="upload_chunks") public class UploadChunk { @EmbeddedId public UploadChunkId id; @Column(name="size_bytes") public Long sizeBytes; @Column(name="storage_path") public String storagePath; }
