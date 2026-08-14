package com.vaijunto.dto; import lombok.Data; @Data public class AdminRecoveryConfirmRequest { private String token; private String totpCode; private String password; }
