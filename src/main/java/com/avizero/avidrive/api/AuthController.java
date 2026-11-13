package com.avizero.avidrive.api;

import com.avizero.avidrive.domain.LoginAttempt; import com.avizero.avidrive.domain.User;
import com.avizero.avidrive.repository.LoginAttemptRepository; import com.avizero.avidrive.repository.UserRepository;
import com.avizero.avidrive.security.AuthUser; import com.avizero.avidrive.security.JwtService;
import jakarta.servlet.http.HttpServletRequest; import java.time.Instant; import java.time.temporal.ChronoUnit; import java.util.Map;
import org.springframework.http.HttpStatus; import org.springframework.http.ResponseEntity; import org.springframework.security.core.Authentication; import org.springframework.security.crypto.password.PasswordEncoder; import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/auth") public class AuthController {
    private final UserRepository users; private final LoginAttemptRepository attempts; private final PasswordEncoder encoder; private final JwtService jwt;
    public AuthController(UserRepository u,LoginAttemptRepository a,PasswordEncoder e,JwtService j){users=u;attempts=a;encoder=e;jwt=j;}
    @PostMapping("/login") public ResponseEntity<?> login(@RequestBody LoginRequest body,HttpServletRequest request){
        long recent=attempts.findAll().stream().filter(a->body.username().equals(a.username)&&a.attemptedAt!=null&&a.attemptedAt.compareTo(Instant.now().minus(5,ChronoUnit.MINUTES).toString())>=0).count();
        if(recent>=10)return error(429,"Слишком много попыток, попробуйте позже");
        User user=users.findAll().stream().filter(u->body.username().equals(u.username)).findFirst().orElse(null);
        if(user==null||!encoder.matches(body.password(),user.passwordHash)){ LoginAttempt a=new LoginAttempt();a.username=body.username();a.ip=request.getRemoteAddr();a.attemptedAt=Instant.now().toString();attempts.save(a);return error(401,"Неверный логин или пароль"); }
        if(user.blocked)return error(423,"Учётная запись заблокирована. Обратитесь к администратору.");
        return ResponseEntity.ok(Map.of("token",jwt.create(user.id,user.username,user.role),"user",Map.of("id",user.id,"username",user.username,"role",user.role,"quota_mb",user.quotaMb,"used_bytes",user.usedBytes)));
    }
    @GetMapping("/me") public Map<String,Object> me(Authentication authentication){ AuthUser u=(AuthUser)authentication.getPrincipal(); User user=users.findById(u.id()).orElseThrow(); return Map.of("id",user.id,"username",user.username,"role",user.role,"quota_mb",user.quotaMb,"used_bytes",user.usedBytes); }
    private ResponseEntity<Map<String,String>> error(int status,String message){return ResponseEntity.status(status).body(Map.of("message",message));}
    public record LoginRequest(String username,String password){}
}
