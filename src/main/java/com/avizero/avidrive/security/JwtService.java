package com.avizero.avidrive.security;

import com.avizero.avidrive.domain.Setting;
import com.avizero.avidrive.repository.SettingRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Service;

@Service
public class JwtService {
    private final SettingRepository settings;
    public JwtService(SettingRepository settings) { this.settings = settings; }
    private SecretKey key() {
        Setting setting = settings.findById(1L).orElseThrow();
        return Keys.hmacShaKeyFor(setting.jwtSecret.getBytes(StandardCharsets.UTF_8));
    }
    public String create(Long userId, String username, String role) {
        Instant now = Instant.now();
        return Jwts.builder().subject(username).claim("uid", userId).claim("role", role)
                .issuedAt(Date.from(now)).expiration(Date.from(now.plusSeconds(86400)))
                .signWith(key(), Jwts.SIG.HS256).compact();
    }
    public Claims parse(String token) { return Jwts.parser().verifyWith(key()).build().parseSignedClaims(token).getPayload(); }
}
