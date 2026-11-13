package com.avizero.avidrive.api;

import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class HealthController {
    @Value("${project.version:0.1.0-SNAPSHOT}") private String version;
    private final JdbcTemplate jdbc;
    public HealthController(JdbcTemplate jdbc) { this.jdbc = jdbc; }
    @GetMapping("/health") public Map<String, Object> health() {
        Integer schemaVersion = jdbc.queryForObject("SELECT schema_version FROM settings WHERE id=1", Integer.class);
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("status", "OK"); result.put("version", version); result.put("db", "OK"); result.put("schema_version", schemaVersion);
        return result;
    }
}
