package com.avizero.avidrive.api;

import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class HealthController {
    @Value("${project.version:0.1.0-SNAPSHOT}") private String version;
    @GetMapping("/health") public Map<String, String> health() {
        return Map.of("status", "OK", "version", version);
    }
}
