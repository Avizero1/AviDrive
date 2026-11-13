package com.avizero.avidrive.security;

import com.avizero.avidrive.domain.User;
import com.avizero.avidrive.repository.UserRepository;
import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    private final JwtService jwt; private final UserRepository users;
    public JwtAuthenticationFilter(JwtService jwt, UserRepository users) { this.jwt=jwt; this.users=users; }
    @Override protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain) throws ServletException, IOException {
        String path=request.getRequestURI();
        if (path.equals("/api/health") || path.equals("/api/auth/login") || path.startsWith("/api/public/")) { chain.doFilter(request,response); return; }
        String header=request.getHeader("Authorization");
        if (header==null || !header.startsWith("Bearer ")) { send(response,401,"Требуется авторизация"); return; }
        try {
            Claims claims=jwt.parse(header.substring(7));
            User user=users.findById(claims.get("uid",Long.class)).orElseThrow();
            if (user.blocked) { send(response,423,"Учётная запись заблокирована"); return; }
            if (path.startsWith("/api/admin/") && "USER".equals(user.role)) { send(response,403,"Недостаточно прав"); return; }
            var auth=new UsernamePasswordAuthenticationToken(new AuthUser(user.id,user.username,user.role),null,
                    java.util.List.of(new SimpleGrantedAuthority("ROLE_"+user.role)));
            SecurityContextHolder.getContext().setAuthentication(auth); chain.doFilter(request,response);
        } catch (Exception ex) { send(response,401,"Недействительный токен"); }
    }
    private void send(HttpServletResponse response,int status,String message) throws IOException { response.setStatus(status); response.setContentType("application/json"); response.getWriter().write("{\"status\":"+status+",\"message\":\""+message+"\"}"); }
}
