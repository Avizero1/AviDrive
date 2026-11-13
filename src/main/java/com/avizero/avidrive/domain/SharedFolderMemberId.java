package com.avizero.avidrive.domain;
import java.io.Serializable; import jakarta.persistence.*;
@Embeddable public class SharedFolderMemberId implements Serializable { @Column(name="folder_id") public Long folderId; @Column(name="user_id") public Long userId; }
