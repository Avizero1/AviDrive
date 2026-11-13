package com.avizero.avidrive.domain;
import jakarta.persistence.*;
@Entity @Table(name="users") public class User { @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id; @Column(unique=true, nullable=false) public String username; @Column(name="password_hash", nullable=false) public String passwordHash; public String role="USER"; @Column(name="quota_mb") public Long quotaMb=0L; @Column(name="used_bytes") public Long usedBytes=0L; @Column(name="is_blocked") public boolean blocked; }
