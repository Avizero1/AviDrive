package com.avizero.avidrive.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "settings")
@Getter @Setter @NoArgsConstructor
public class Setting {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(nullable = false, unique = true, length = 100) private String key;
    @Column(nullable = false, columnDefinition = "TEXT") private String value;
}
