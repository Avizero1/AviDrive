package com.avizero.avidrive.controller;

import com.avizero.avidrive.entity.FileEntry;
import com.avizero.avidrive.repository.FileEntryRepository;
import com.avizero.avidrive.repository.UserRepository;
import org.springframework.data.domain.*;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.Locale;

@RestController
@RequestMapping("/api/search")
public class SearchController {
    private final FileEntryRepository files; private final UserRepository users;
    public SearchController(FileEntryRepository files, UserRepository users) { this.files=files; this.users=users; }
    @GetMapping public Page<FileEntry> search(Authentication auth, @RequestParam String q, @RequestParam(required=false) String type, @RequestParam(required=false) String date, Pageable pageable) {
        var user=users.findByUsername(auth.getName()).orElseThrow();
        String query=q.toLowerCase(Locale.ROOT);
        return files.findAll((root, cq, cb) -> cb.and(cb.equal(root.get("owner"), user), cb.like(cb.lower(root.get("name")), "%"+query+"%")), PageRequest.of(pageable.getPageNumber(), Math.min(pageable.getPageSize(), 50), pageable.getSort()));
    }
}
