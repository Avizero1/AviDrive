package com.avizero.avidrive.controller;

import com.avizero.avidrive.entity.*;
import com.avizero.avidrive.repository.*;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/permissions")
public class PermissionController {
    private final FilePermissionRepository permissions; private final FileEntryRepository files; private final UserRepository users;
    public PermissionController(FilePermissionRepository permissions, FileEntryRepository files, UserRepository users) { this.permissions=permissions; this.files=files; this.users=users; }
    @GetMapping("/{fileId}") public List<FilePermission> list(@PathVariable Long fileId) { return permissions.findByFileId(fileId); }
    @PostMapping public ResponseEntity<FilePermission> create(Authentication auth, @RequestBody Request request) { FilePermission p=new FilePermission(); p.setFile(files.findById(request.fileId()).orElseThrow()); p.setUser(users.findByUsername(request.username()).orElseThrow()); p.setPermissions(request.permissions()); p.setGrantedAt(LocalDateTime.now()); return ResponseEntity.ok(permissions.save(p)); }
    @DeleteMapping("/{id}") public ResponseEntity<Void> delete(@PathVariable Long id) { permissions.deleteById(id); return ResponseEntity.noContent().build(); }
    public record Request(Long fileId, String username, String permissions) {}
}
