package com.avizero.avidrive.domain;
import jakarta.persistence.*;
@Entity @Table(name="uploads") public class Upload { @Id @GeneratedValue(strategy=GenerationType.IDENTITY) public Long id; @Column(name="session_uuid", unique=true) public String sessionUuid; @Column(name="file_name") public String fileName; @Column(name="total_size") public Long totalSize; public String status; }
