package com.avizero.avidrive.domain;
import jakarta.persistence.*;
@Entity @Table(name="login_attempts") public class LoginAttempt { @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id; public String username; public String ip; @Column(name="attempted_at") public String attemptedAt; }
