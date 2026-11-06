package com.avizero.avidrive.repository;

import com.avizero.avidrive.entity.SharedFolder;
import com.avizero.avidrive.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface SharedFolderRepository extends JpaRepository<SharedFolder, Long> {
    List<SharedFolder> findByOwner(User owner);
}
