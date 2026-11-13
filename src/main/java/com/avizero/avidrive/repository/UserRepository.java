package com.avizero.avidrive.repository;
import com.avizero.avidrive.domain.User;
import org.springframework.data.jpa.repository.JpaRepository;
public interface UserRepository extends JpaRepository<User,Long>{ boolean existsByUsername(String username); }
