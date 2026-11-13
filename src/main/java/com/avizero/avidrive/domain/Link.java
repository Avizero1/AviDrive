package com.avizero.avidrive.domain;
import jakarta.persistence.*;
@Entity @Table(name="links") public class Link { @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id; @Column(unique=true, nullable=false) public String token; @Column(name="owner_id") public Long ownerId; @Column(name="file_id") public Long fileId; @Column(name="folder_id") public Long folderId; }
