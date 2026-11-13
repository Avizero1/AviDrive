package com.avizero.avidrive.domain;
import jakarta.persistence.*;
@Entity @Table(name="folders") public class Folder { @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id; @Column(nullable=false) public String name; @Column(name="owner_id") public Long ownerId; @Column(name="parent_id") public Long parentId; @Column(name="is_shared") public boolean shared; @Column(name="created_at") public String createdAt; }
