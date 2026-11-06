package com.avizero.avidrive.repository;

import com.avizero.avidrive.entity.SharedFolderMember;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SharedFolderMemberRepository extends JpaRepository<SharedFolderMember, Long> {
    List<SharedFolderMember> findByFolderId(Long folderId);
}
