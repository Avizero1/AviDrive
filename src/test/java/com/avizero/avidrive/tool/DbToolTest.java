package com.avizero.avidrive.tool;

import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.Test;

class DbToolTest {
    @Test void escapesSqlLiteralQuotes(){assertEquals("O''Reilly",DbTool.escapeSqlLiteral("O'Reilly"));}
    @Test void bcryptRoundTrip(){String hash=DbTool.hashPassword("correct horse battery");assertTrue(DbTool.verifyPassword("correct horse battery",hash));assertFalse(DbTool.verifyPassword("wrong",hash));}
}
