package com.avizero.avidrive.api;

import com.avizero.avidrive.domain.AuditLog;
import com.avizero.avidrive.domain.User;
import com.avizero.avidrive.repository.AuditLogRepository;
import com.avizero.avidrive.repository.UserRepository;
import com.avizero.avidrive.security.AuthUser;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/users")
public class AdminUserController {
    private static final Set<String> ROLES = Set.of("USER", "MODER", "ADMIN");
    private final UserRepository users;
    private final AuditLogRepository audit;
    private final PasswordEncoder encoder;

    public AdminUserController(UserRepository users, AuditLogRepository audit, PasswordEncoder encoder) {
        this.users = users; this.audit = audit; this.encoder = encoder;
    }

    @GetMapping public Map<String,Object> list(@RequestParam(defaultValue="") String search,
                                                @RequestParam(defaultValue="1") int page,
                                                @RequestParam(defaultValue="20") int size) {
        List<UserView> all = users.findAll().stream().filter(u -> u.username.toLowerCase().contains(search.toLowerCase()))
                .map(UserView::of).toList();
        int safeSize=Math.max(1,Math.min(size,100)), safePage=Math.max(1,page), from=Math.min((safePage-1)*safeSize,all.size());
        return Map.of("items",all.subList(from,Math.min(from+safeSize,all.size())),"total",all.size(),"page",safePage,"pages",(all.size()+safeSize-1)/safeSize);
    }

    @PostMapping public ResponseEntity<?> create(@RequestBody CreateRequest request, Authentication authentication) {
        AuthUser actor=actor(authentication);
        if (!validUsername(request.username()) || request.password()==null || request.password().length()<8 || !ROLES.contains(request.role())) return error(400,"Некорректные данные пользователя");
        if (users.existsByUsername(request.username())) return error(409,"Пользователь уже существует");
        if ("MODER".equals(actor.role()) && !"USER".equals(request.role())) return error(403,"Недостаточно прав");
        User user=new User(); user.username=request.username(); user.passwordHash=encoder.encode(request.password()); user.role=request.role(); user.quotaMb=nonNegative(request.quotaMb()); user.createdAt=java.time.Instant.now().toString(); users.save(user);
        record(actor,"USER_CREATED",user.id,"Создан пользователь "+user.username,null); return ResponseEntity.ok(UserView.of(user));
    }

    @GetMapping("/{id}") public ResponseEntity<?> get(@PathVariable Long id, Authentication authentication) {
        if (!allowedTarget(id,actor(authentication),false)) return error(403,"Недостаточно прав");
        return users.findById(id).<ResponseEntity<?>>map(u->ResponseEntity.ok(UserView.of(u))).orElseGet(()->error(404,"Пользователь не найден"));
    }

    @PatchMapping("/{id}") public ResponseEntity<?> update(@PathVariable Long id,@RequestBody UpdateRequest request,Authentication authentication) {
        AuthUser actor=actor(authentication); if (!allowedTarget(id,actor,false)) return error(403,"Недостаточно прав");
        User user=users.findById(id).orElse(null); if(user==null)return error(404,"Пользователь не найден");
        if(request.role()!=null && !request.role().equals(user.role)){if(!"ADMIN".equals(actor.role()))return error(403,"Только ADMIN может менять роль");if(!ROLES.contains(request.role()))return error(400,"Некорректная роль");user.role=request.role();record(actor,"ROLE_CHANGED",id,"Роль изменена",null);}
        if(request.quotaMb()!=null){if("ADMIN".equals(user.role)&&!"ADMIN".equals(actor.role()))return error(403,"Квоту ADMIN нельзя менять");if(request.quotaMb()<0)return error(400,"Квота не может быть отрицательной");user.quotaMb=request.quotaMb();record(actor,"QUOTA_CHANGED",id,"Квота изменена",null);}
        if(request.isBlocked()!=null && request.isBlocked()!=user.blocked){user.blocked=request.isBlocked();record(actor,"USER_BLOCKED",id,"Статус блокировки изменён",null);}
        users.save(user); return ResponseEntity.ok(UserView.of(user));
    }

    @DeleteMapping("/{id}") @Transactional public ResponseEntity<?> delete(@PathVariable Long id,Authentication authentication,HttpServletRequest request){
        AuthUser actor=actor(authentication); User user=users.findById(id).orElse(null); if(user==null)return error(404,"Пользователь не найден");
        if(!allowedTarget(id,actor,true)||"ADMIN".equals(user.role))return error(403,"Удаление запрещено");
        record(actor,"USER_DELETED",id,"Удалён пользователь "+user.username,request.getRemoteAddr()); users.delete(user); return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/password-reset") public ResponseEntity<?> reset(@PathVariable Long id,@RequestBody PasswordRequest request,Authentication authentication){
        AuthUser actor=actor(authentication); User user=users.findById(id).orElse(null); if(user==null)return error(404,"Пользователь не найден");
        if(!allowedTarget(id,actor,false)||request.newPassword()==null||request.newPassword().length()<8)return request.newPassword()==null||request.newPassword().length()<8?error(400,"Пароль должен содержать минимум 8 символов"):error(403,"Недостаточно прав");
        user.passwordHash=encoder.encode(request.newPassword());users.save(user);record(actor,"PASSWORD_RESET",id,"Пароль сброшен",null);return ResponseEntity.noContent().build();
    }
    private boolean allowedTarget(Long id,AuthUser actor,boolean deleting){User target=users.findById(id).orElse(null);if(target==null)return true;if("ADMIN".equals(actor.role()))return !deleting||(!id.equals(actor.id())&& !"ADMIN".equals(target.role));return "MODER".equals(actor.role())&&"USER".equals(target.role);}
    private AuthUser actor(Authentication a){return (AuthUser)a.getPrincipal();}
    private void record(AuthUser actor,String action,Long target,String details,String ip){AuditLog l=new AuditLog();l.actorId=actor.id();l.action=action;l.targetType="USER";l.targetId=target;l.details=details;l.ip=ip;audit.save(l);}
    private Long nonNegative(Long n){return n==null||n<0?0:n;}
    private boolean validUsername(String n){return n!=null&&n.matches("[A-Za-z0-9_.-]{3,64}");}
    private ResponseEntity<Map<String,String>> error(int status,String message){return ResponseEntity.status(status).body(Map.of("message",message));}
    public record CreateRequest(String username,String password,String role,Long quotaMb){}
    public record UpdateRequest(Long quotaMb,String role,Boolean isBlocked){}
    public record PasswordRequest(String newPassword){}
    public record UserView(Long id,String username,String role,Long quota_mb,Long used_bytes,boolean is_blocked,String created_at){static UserView of(User u){return new UserView(u.id,u.username,u.role,u.quotaMb,u.usedBytes,u.blocked,u.createdAt);}}
}

