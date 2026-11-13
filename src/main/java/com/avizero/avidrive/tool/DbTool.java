package com.avizero.avidrive.tool;
import java.nio.file.*; import java.sql.*; import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
public final class DbTool { private DbTool(){} public static String escapeSqlLiteral(String v){return v==null?"":v.replace("'","''");} public static String hashPassword(String v){return new BCryptPasswordEncoder().encode(v);} public static boolean verifyPassword(String v,String h){return new BCryptPasswordEncoder().matches(v,h);}
 public static void main(String[] a)throws Exception{if(a.length<1)throw new IllegalArgumentException("command expected");switch(a[0]){case "hash-password"->System.out.println(hashPassword(a[1]));case "verify-password"->System.out.println(verifyPassword(a[1],a[2]));case "run-sql"->run(a[1]);default->throw new IllegalArgumentException("unknown command");}}
 private static void run(String sql)throws Exception{Path db=Path.of(System.getenv().getOrDefault("DB_PATH","data/filestorage.db"));Files.createDirectories(db.toAbsolutePath().getParent());try(Connection c=DriverManager.getConnection("jdbc:sqlite:"+db);Statement s=c.createStatement()){for(String q:sql.split(";"))if(!q.isBlank())s.execute(q);}}
}
