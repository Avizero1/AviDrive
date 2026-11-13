package com.avizero.avidrive.domain;
import jakarta.persistence.*;
import java.time.Instant;
@Entity @Table(name="audit_log") public class AuditLog { @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id; public String action; @Column(name="actor_id") public Long actorId; @Column(name="target_type") public String targetType; @Column(name="target_id") public Long targetId; public String details; public String ip; @Column(name="created_at", nullable=false) public String createdAt; @PrePersist void onCreate(){if(createdAt==null)createdAt=Instant.now().toString();} }
