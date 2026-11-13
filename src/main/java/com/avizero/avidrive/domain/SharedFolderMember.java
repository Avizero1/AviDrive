package com.avizero.avidrive.domain;
import jakarta.persistence.*;
@Entity @Table(name="shared_folder_members") public class SharedFolderMember { @EmbeddedId public SharedFolderMemberId id; @Column(name="can_view") public boolean canView=true; @Column(name="can_download") public boolean canDownload; @Column(name="can_upload") public boolean canUpload; @Column(name="can_delete") public boolean canDelete; @Column(name="can_rename") public boolean canRename; @Column(name="max_file_size_mb") public Long maxFileSizeMb; @Column(name="max_user_space_mb") public Long maxUserSpaceMb; }
