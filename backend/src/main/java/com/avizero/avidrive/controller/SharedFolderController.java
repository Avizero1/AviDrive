package com.avizero.avidrive.controller;

import com.avizero.avidrive.entity.*;
import com.avizero.avidrive.repository.*;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/shared/folders")
public class SharedFolderController {
    private final SharedFolderRepository folders; private final SharedFolderMemberRepository members; private final UserRepository users;
    public SharedFolderController(SharedFolderRepository folders, SharedFolderMemberRepository members, UserRepository users) { this.folders=folders; this.members=members; this.users=users; }
    @PostMapping public SharedFolder create(Authentication auth, @RequestBody Request r) { SharedFolder f=new SharedFolder(); f.setName(r.name()); f.setOwner(current(auth)); f.setQuotaMb(r.quotaMb()==null?0:r.quotaMb()); return folders.save(f); }
    @GetMapping public List<SharedFolder> list(Authentication auth) { return folders.findByOwner(current(auth)); }
    @GetMapping("/{id}") public SharedFolder get(@PathVariable Long id) { return folders.findById(id).orElseThrow(); }
    @PostMapping("/{id}/members") public SharedFolderMember add(@PathVariable Long id, @RequestBody MemberRequest r) { SharedFolderMember m=new SharedFolderMember(); m.setFolder(folders.findById(id).orElseThrow()); m.setUser(users.findByUsername(r.username()).orElseThrow()); m.setPermissions(r.permissions()); m.setMaxFileSizeMb(r.maxFileSizeMb()==null?0:r.maxFileSizeMb()); m.setMaxUserSpaceMb(r.maxUserSpaceMb()==null?0:r.maxUserSpaceMb()); return members.save(m); }
    @DeleteMapping("/{id}/members/{userId}") public ResponseEntity<Void> remove(@PathVariable Long id, @PathVariable Long userId) { members.findByFolderId(id).stream().filter(m -> m.getUser().getId().equals(userId)).findFirst().ifPresent(members::delete); return ResponseEntity.noContent().build(); }
    private User current(Authentication auth) { return users.findByUsername(auth.getName()).orElseThrow(); }
    public record Request(String name, Long quotaMb) {}
    public record MemberRequest(String username, String permissions, Long maxFileSizeMb, Long maxUserSpaceMb) {}
}
