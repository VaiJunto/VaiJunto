package com.vaijunto.service;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.Instant;
import org.junit.jupiter.api.Test;

class TotpTest {
  private static final String SECRET = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ";
  private static final Instant RFC_TIME = Instant.ofEpochSecond(59);

  @Test
  void acceptsCodeFromAuthenticator() {
    assertTrue(Totp.verify(SECRET, "287082", RFC_TIME));
  }

  @Test
  void rejectsDifferentCode() {
    assertFalse(Totp.verify(SECRET, "287083", RFC_TIME));
  }
}
