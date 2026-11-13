package com.avizero.avidrive.domain;
import java.io.Serializable; import jakarta.persistence.*;
@Embeddable public class UploadChunkId implements Serializable { @Column(name="upload_id") public Long uploadId; @Column(name="chunk_index") public Integer chunkIndex; }
