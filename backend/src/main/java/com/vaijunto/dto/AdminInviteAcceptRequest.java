package com.vaijunto.dto; import lombok.Data; @Data public class AdminInviteAcceptRequest { private String token; private String password; private String totpSecret; }
