package com.avizero.avidrive.repository;

import com.avizero.avidrive.entity.FileEntry;
import com.avizero.avidrive.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface FileEntryRepository extends JpaRepository<FileEntry, Long> {
    List<FileEntry> findByOwnerAndParent(User owner, FileEntry parent);
}
