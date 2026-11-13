package com.avizero.avidrive.domain;
import java.io.Serializable; import java.util.Objects; import jakarta.persistence.*;
@Embeddable public class SharedFolderMemberId implements Serializable { @Column(name="folder_id") public Long folderId; @Column(name="user_id") public Long userId; @Override public boolean equals(Object o){if(this==o)return true;if(!(o instanceof SharedFolderMemberId x))return false;return Objects.equals(folderId,x.folderId)&&Objects.equals(userId,x.userId);}@Override public int hashCode(){return Objects.hash(folderId,userId);} }
