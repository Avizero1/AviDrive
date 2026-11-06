package com.avizero.avidrive.controller;

import com.avizero.avidrive.entity.User;
import com.avizero.avidrive.repository.UserRepository;
import com.avizero.avidrive.security.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.http.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final LoginRateLimiter rateLimiter;

    public AuthController(UserRepository users, PasswordEncoder passwordEncoder, JwtService jwtService, LoginRateLimiter rateLimiter) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.rateLimiter = rateLimiter;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        if (!rateLimiter.allowed(request.username())) return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(Map.of("error", "Слишком много попыток входа"));
        return users.findByUsername(request.username())
                .filter(user -> !user.isBlocked() && passwordEncoder.matches(request.password(), user.getPasswordHash()))
                .<ResponseEntity<?>>map(user -> ResponseEntity.ok(Map.of("token", jwtService.generateToken(user.getUsername(), user.getRole()), "username", user.getUsername(), "role", user.getRole())))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "Неверный логин или пароль")));
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout() { return ResponseEntity.noContent().build(); }

    @GetMapping("/me")
    public ResponseEntity<?> me(Authentication authentication) {
        return users.findByUsername(authentication.getName()).map(user -> ResponseEntity.ok(Map.of("id", user.getId(), "username", user.getUsername(), "role", user.getRole(), "quotaMb", user.getQuotaMb(), "usedSpaceMb", user.getUsedSpaceMb(), "blocked", user.isBlocked()))).orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PutMapping("/password")
    public ResponseEntity<Void> changePassword(Authentication authentication, @Valid @RequestBody PasswordRequest request) {
        User user = users.findByUsername(authentication.getName()).orElseThrow();
        if (!passwordEncoder.matches(request.currentPassword(), user.getPasswordHash())) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        users.save(user);
        return ResponseEntity.noContent().build();
    }

    public record LoginRequest(@NotBlank @Pattern(regexp = "^[a-zA-Z_][a-zA-Z0-9_]{2,19}$") String username, @NotBlank String password) {}
    public record PasswordRequest(@NotBlank String currentPassword, @NotBlank @Size(min = 8) String newPassword) {}
}
