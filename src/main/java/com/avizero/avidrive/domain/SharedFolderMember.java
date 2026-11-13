package com.avizero.avidrive.domain;
import jakarta.persistence.*;
@Entity @Table(name="shared_folder_members") public class SharedFolderMember { @EmbeddedId public SharedFolderMemberId id; @Column(name="can_view") public boolean canView; @Column(name="can_upload") public boolean canUpload; }
