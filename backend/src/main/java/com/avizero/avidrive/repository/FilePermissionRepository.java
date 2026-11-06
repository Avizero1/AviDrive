package com.avizero.avidrive.repository;

import com.avizero.avidrive.entity.FilePermission;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface FilePermissionRepository extends JpaRepository<FilePermission, Long> {
    List<FilePermission> findByFileId(Long fileId);
}
