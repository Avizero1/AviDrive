package com.avizero.avidrive.api;

import com.avizero.avidrive.domain.AuditLog;
import com.avizero.avidrive.repository.AuditLogRepository;
import com.avizero.avidrive.repository.UserRepository;
import com.avizero.avidrive.security.AuthUser;
import java.util.*;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/admin/audit")
public class AdminAuditController {
    private final AuditLogRepository audit; private final UserRepository users;
    public AdminAuditController(AuditLogRepository a, UserRepository u){audit=a;users=u;}
    @GetMapping public ResponseEntity<?> list(@RequestParam(defaultValue="1") int page,@RequestParam(defaultValue="20") int size,@RequestParam(required=false) String action,@RequestParam(required=false) String date_from,@RequestParam(required=false) String date_to,Authentication authentication){
        AuthUser actor=(AuthUser)authentication.getPrincipal(); if(!"ADMIN".equals(actor.role())&&!"MODER".equals(actor.role()))return forbidden();
        List<Map<String,Object>> all=audit.findAll().stream().filter(x->visible(x,actor)).filter(x->action==null||action.isBlank()||action.equals(x.action)).filter(x->date_from==null||date_from.isBlank()||x.createdAt==null||x.createdAt.compareTo(date_from)>=0).filter(x->date_to==null||date_to.isBlank()||x.createdAt==null||x.createdAt.compareTo(date_to+"T23:59:59")<=0).sorted(Comparator.comparing(x->x.createdAt==null?"":x.createdAt,Comparator.reverseOrder())).map(this::view).toList();
        int s=Math.max(1,Math.min(size,100)),p=Math.max(1,page),from=Math.min((p-1)*s,all.size());return ResponseEntity.ok(Map.of("items",all.subList(from,Math.min(from+s,all.size())),"total",all.size(),"page",p,"pages",(all.size()+s-1)/s));
    }
    @DeleteMapping public ResponseEntity<?> clear(Authentication authentication){if(!"ADMIN".equals(((AuthUser)authentication.getPrincipal()).role()))return forbidden();audit.deleteAll();return ResponseEntity.noContent().build();}
    private boolean visible(AuditLog x,AuthUser a){return "ADMIN".equals(a.role())||Objects.equals(x.actorId,a.id())||"USER".equals(x.targetType);}
    private Map<String,Object> view(AuditLog x){Map<String,Object> m=new LinkedHashMap<>();m.put("created_at",x.createdAt);m.put("actor_username",x.actorId==null?"system":users.findById(x.actorId).map(u->u.username).orElse("unknown"));m.put("action",x.action);m.put("target_type",x.targetType);m.put("target_id",x.targetId);m.put("details",x.details);m.put("ip",x.ip);return m;}
    private ResponseEntity<Map<String,String>> forbidden(){return ResponseEntity.status(403).body(Map.of("message","Недостаточно прав"));}
}
