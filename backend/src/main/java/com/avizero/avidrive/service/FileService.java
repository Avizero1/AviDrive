package com.avizero.avidrive.service;

import com.avizero.avidrive.entity.FileEntry;
import com.avizero.avidrive.entity.User;
import com.avizero.avidrive.repository.FileEntryRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.zip.*;

@Service
public class FileService {
    private final FileEntryRepository files;
    @Value("${app.storage-path:./storage}") private String storagePath;

    public FileService(FileEntryRepository files) { this.files = files; }

    private Path userRoot(User user) { return Paths.get(storagePath).toAbsolutePath().normalize().resolve("user_" + user.getId()).normalize(); }
    private Path safePath(User user, String relative) {
        Path root = userRoot(user);
        Path result = root.resolve(relative == null ? "" : relative).normalize();
        if (!result.startsWith(root)) throw new IllegalArgumentException("Недопустимый путь");
        return result;
    }

    public List<FileEntry> list(User user, Long parentId) {
        FileEntry parent = parentId == null ? null : files.findById(parentId).orElseThrow();
        return files.findByOwnerAndParent(user, parent);
    }

    @Transactional
    public FileEntry upload(User user, MultipartFile multipart, String relativePath, Long parentId) throws IOException {
        if (multipart.isEmpty()) throw new IllegalArgumentException("Пустой файл");
        FileEntry parent = parentId == null ? null : files.findById(parentId).orElseThrow();
        Path target = safePath(user, relativePath);
        Files.createDirectories(target.getParent());
        Files.copy(multipart.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
        FileEntry entry = new FileEntry(); entry.setName(target.getFileName().toString()); entry.setPath(userRoot(user).relativize(target).toString()); entry.setSizeBytes(Files.size(target)); entry.setOwner(user); entry.setParent(parent); entry.setDirectory(false); return files.save(entry);
    }

    @Transactional
    public FileEntry createFolder(User user, String relativePath, Long parentId) throws IOException {
        FileEntry parent = parentId == null ? null : files.findById(parentId).orElseThrow();
        Path target = safePath(user, relativePath); Files.createDirectories(target);
        FileEntry entry = new FileEntry(); entry.setName(target.getFileName().toString()); entry.setPath(userRoot(user).relativize(target).toString()); entry.setOwner(user); entry.setParent(parent); entry.setDirectory(true); return files.save(entry);
    }

    @Transactional
    public void delete(User user, Long id) throws IOException { FileEntry entry = owned(user, id); Files.deleteIfExists(safePath(user, entry.getPath())); files.delete(entry); }
    @Transactional
    public FileEntry rename(User user, Long id, String name) throws IOException { FileEntry entry = owned(user, id); if (!name.matches("^[^\\\\/:*?\"<>|]+$")) throw new IllegalArgumentException("Недопустимое имя"); Path old = safePath(user, entry.getPath()); Path target = old.resolveSibling(name).normalize(); if (!target.startsWith(userRoot(user))) throw new IllegalArgumentException("Недопустимый путь"); Files.move(old, target); entry.setName(name); entry.setPath(userRoot(user).relativize(target).toString()); return files.save(entry); }
    public ResponseEntity<InputStreamResource> download(User user, Long id) throws IOException { FileEntry entry = owned(user, id); Path path = safePath(user, entry.getPath()); if (entry.isDirectory()) return zip(user, entry); HttpHeaders h = headers(entry.getName()); return new ResponseEntity<>(new InputStreamResource(Files.newInputStream(path)), h, HttpStatus.OK); }
    private ResponseEntity<InputStreamResource> zip(User user, FileEntry entry) throws IOException { Path source = safePath(user, entry.getPath()); ByteArrayOutputStream output = new ByteArrayOutputStream(); try (ZipOutputStream zip = new ZipOutputStream(output)) { Files.walk(source).filter(Files::isRegularFile).forEach(path -> { try { String name = source.relativize(path).toString().replace('\\','/'); if (name.contains("..")) throw new IllegalArgumentException("Zip Slip"); zip.putNextEntry(new ZipEntry(name)); Files.copy(path, zip); zip.closeEntry(); } catch (IOException e) { throw new UncheckedIOException(e); } }); } HttpHeaders h = headers(entry.getName() + ".zip"); h.setContentType(MediaType.APPLICATION_OCTET_STREAM); return new ResponseEntity<>(new InputStreamResource(new ByteArrayInputStream(output.toByteArray())), h, HttpStatus.OK); }
    private HttpHeaders headers(String name) { HttpHeaders h = new HttpHeaders(); h.setContentType(MediaType.APPLICATION_OCTET_STREAM); h.set("X-Content-Type-Options", "nosniff"); h.setContentDisposition(ContentDisposition.attachment().filename(name).build()); return h; }
    private FileEntry owned(User user, Long id) { FileEntry entry = files.findById(id).orElseThrow(); if (!Objects.equals(entry.getOwner().getId(), user.getId())) throw new AccessDeniedException("Нет доступа"); return entry; }
    public static class AccessDeniedException extends RuntimeException { public AccessDeniedException(String message) { super(message); } }
}
