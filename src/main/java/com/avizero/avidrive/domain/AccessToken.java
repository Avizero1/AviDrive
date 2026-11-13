package com.avizero.avidrive.domain;
import jakarta.persistence.*;
@Entity @Table(name="access_tokens") public class AccessToken { @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id; @Column(name="link_id") public Long linkId; @Column(name="token_hash", unique=true) public String tokenHash; @Column(name="expires_at") public String expiresAt; }
