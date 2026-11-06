package com.avizero.avidrive.security;

import org.springframework.stereotype.Component;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class LoginRateLimiter {
    private static final int MAX_ATTEMPTS = 10;
    private static final Duration WINDOW = Duration.ofMinutes(5);
    private final Map<String, Attempts> attempts = new ConcurrentHashMap<>();

    public boolean allowed(String username) {
        Instant now = Instant.now();
        Attempts value = attempts.computeIfAbsent(username, ignored -> new Attempts(now, 0));
        synchronized (value) {
            if (Duration.between(value.startedAt, now).compareTo(WINDOW) >= 0) {
                value.startedAt = now;
                value.count = 0;
            }
            if (value.count >= MAX_ATTEMPTS) return false;
            value.count++;
            return true;
        }
    }

    private static final class Attempts {
        private Instant startedAt;
        private int count;
        private Attempts(Instant startedAt, int count) { this.startedAt = startedAt; this.count = count; }
    }
}
