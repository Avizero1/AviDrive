package com.avizero.avidrive;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class AviDriveApplication {
    public static void main(String[] args) { SpringApplication.run(AviDriveApplication.class, args); }
}
