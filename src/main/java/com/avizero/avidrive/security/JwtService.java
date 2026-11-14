package com.avizero.avidrive.security;

import com.avizero.avidrive.domain.Setting;
import com.avizero.avidrive.repository.SettingRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;
import java.util.Base64;
import java.security.SecureRandom;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Service;

@Service
public class JwtService {
    private final SettingRepository settings;
    private final SecureRandom random = new SecureRandom();
    public JwtService(SettingRepository settings) { this.settings = settings; }
    @jakarta.annotation.PostConstruct
    void ensureSecret(){Setting s=settings.findById(1L).orElseThrow();if(s.jwtSecret==null||s.jwtSecret.length()<32||s.jwtSecret.startsWith("change-me")){byte[] bytes=new byte[32];random.nextBytes(bytes);s.jwtSecret=Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);settings.save(s);}}
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
