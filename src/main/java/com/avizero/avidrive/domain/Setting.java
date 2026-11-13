package com.avizero.avidrive.domain;
import jakarta.persistence.*;
@Entity @Table(name="settings") public class Setting { @Id public Long id; @Column(name="global_quota_mb") public Long globalQuotaMb; @Column(name="jwt_secret") public String jwtSecret; @Column(name="schema_version") public Integer schemaVersion; }
