package com.avizero.avidrive.controller;

import com.avizero.avidrive.entity.User;
import com.avizero.avidrive.repository.UserRepository;
import com.avizero.avidrive.service.FileService;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/api/files")
public class FileController {
    private final FileService fileService;
    private final UserRepository users;

    public FileController(FileService fileService, UserRepository users) {
        this.fileService = fileService;
        this.users = users;
    }

    @GetMapping
    public Object list(Authentication auth, @RequestParam(required = false) Long parentId) { return fileService.list(current(auth), parentId); }
    @GetMapping("/{folderId}")
    public Object folder(Authentication auth, @PathVariable Long folderId) { return fileService.list(current(auth), folderId); }
    @PostMapping("/upload")
    public Object upload(Authentication auth, @RequestParam MultipartFile file, @RequestParam(required = false, defaultValue = "") String relativePath, @RequestParam(required = false) Long parentId) throws IOException { return fileService.upload(current(auth), file, relativePath.isBlank() ? file.getOriginalFilename() : relativePath, parentId); }
    @PostMapping("/folder")
    public Object folder(Authentication auth, @RequestParam String path, @RequestParam(required = false) Long parentId) throws IOException { return fileService.createFolder(current(auth), path, parentId); }
    @PutMapping("/{id}/rename")
    public Object rename(Authentication auth, @PathVariable Long id, @RequestBody Map<String, String> body) throws IOException { return fileService.rename(current(auth), id, body.getOrDefault("name", "")); }
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(Authentication auth, @PathVariable Long id) throws IOException { fileService.delete(current(auth), id); return ResponseEntity.noContent().build(); }
    @GetMapping("/{id}/download")
    public ResponseEntity<InputStreamResource> download(Authentication auth, @PathVariable Long id) throws IOException { return fileService.download(current(auth), id); }
    private User current(Authentication auth) { return users.findByUsername(auth.getName()).orElseThrow(); }
}
