package com.avizero.avidrive.controller;

import com.avizero.avidrive.entity.*;
import com.avizero.avidrive.repository.*;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.*;

@RestController
@RequestMapping("/api/share")
public class ShareController {
    private final ShareLinkRepository links; private final FileEntryRepository files; private final UserRepository users;
    public ShareController(ShareLinkRepository links, FileEntryRepository files, UserRepository users) { this.links=links; this.files=files; this.users=users; }
    @PostMapping("/link") public ShareLink create(Authentication auth, @RequestBody Request r) { ShareLink l=new ShareLink(); l.setToken(UUID.randomUUID().toString()); l.setFile(files.findById(r.fileId()).orElseThrow()); l.setCreatedBy(users.findByUsername(auth.getName()).orElseThrow()); l.setPermissions(r.permissions()); l.setExpiresAt(r.expiresAt()); l.setPasswordHash(r.passwordHash()); return links.save(l); }
    @GetMapping("/link/{fileId}") public List<ShareLink> list(@PathVariable Long fileId) { return links.findByFileId(fileId); }
    @DeleteMapping("/link/{id}") public ResponseEntity<Void> delete(@PathVariable Long id) { links.deleteById(id); return ResponseEntity.noContent().build(); }
    @GetMapping("/../public/{token}") public ResponseEntity<?> publicInfo(@PathVariable String token) { return links.findByToken(token).map(l -> ResponseEntity.ok(Map.of("fileId", l.getFile().getId(), "permissions", l.getPermissions(), "expiresAt", Optional.ofNullable(l.getExpiresAt()).orElse(LocalDateTime.MAX)))).orElseGet(() -> ResponseEntity.notFound().build()); }
    public record Request(Long fileId, String permissions, String passwordHash, LocalDateTime expiresAt) {}
}
