package com.avizero.avidrive.repository;

import com.avizero.avidrive.entity.ShareLink;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface ShareLinkRepository extends JpaRepository<ShareLink, Long> {
    Optional<ShareLink> findByToken(String token);
    List<ShareLink> findByFileId(Long fileId);
}
