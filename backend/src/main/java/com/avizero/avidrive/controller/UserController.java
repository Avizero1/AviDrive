package com.avizero.avidrive.controller;

import com.avizero.avidrive.entity.User;
import com.avizero.avidrive.repository.UserRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/users")
@PreAuthorize("hasAnyRole('ADMIN','MODERATOR')")
public class UserController {
    private final UserRepository users; private final PasswordEncoder encoder;
    public UserController(UserRepository users, PasswordEncoder encoder) { this.users=users; this.encoder=encoder; }
    @GetMapping public List<User> list() { return users.findAll(); }
    @PostMapping public User create(@Valid @RequestBody Request r) { User u=new User(); u.setUsername(r.username()); u.setPasswordHash(encoder.encode(r.password())); u.setRole(r.role()); u.setQuotaMb(r.quotaMb()==null?0:r.quotaMb()); return users.save(u); }
    @PutMapping("/{id}") public User update(@PathVariable Long id, @RequestBody UpdateRequest r) { User u=users.findById(id).orElseThrow(); if(r.role()!=null)u.setRole(r.role()); if(r.quotaMb()!=null)u.setQuotaMb(r.quotaMb()); return users.save(u); }
    @PutMapping("/{id}/password") public ResponseEntity<Void> password(@PathVariable Long id, @Valid @RequestBody PasswordRequest r) { User u=users.findById(id).orElseThrow(); u.setPasswordHash(encoder.encode(r.password())); users.save(u); return ResponseEntity.noContent().build(); }
    @DeleteMapping("/{id}") public ResponseEntity<Void> delete(@PathVariable Long id) { users.deleteById(id); return ResponseEntity.noContent().build(); }
    public record Request(@NotBlank @Pattern(regexp="^[a-zA-Z_][a-zA-Z0-9_]{2,19}$") String username, @Size(min=8) String password, @NotBlank String role, Long quotaMb) {}
    public record UpdateRequest(String role, Long quotaMb) {}
    public record PasswordRequest(@Size(min=8) String password) {}
}
