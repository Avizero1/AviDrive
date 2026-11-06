package com.avizero.avidrive.service;

import com.avizero.avidrive.entity.User;
import com.avizero.avidrive.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class QuotaService {
    private final UserRepository users;
    @Value("${app.global-quota-mb:0}") private long globalQuotaMb;
    public QuotaService(UserRepository users) { this.users=users; }
    @Transactional(readOnly=true)
    public boolean canUse(User user, long bytes) { long mb=(bytes+1048575L)/1048576L; return (user.getQuotaMb()==0 || user.getUsedSpaceMb()+mb<=user.getQuotaMb()) && (globalQuotaMb==0 || totalUsed()+mb<=globalQuotaMb); }
    public long totalUsed() { return users.findAll().stream().mapToLong(User::getUsedSpaceMb).sum(); }
}
