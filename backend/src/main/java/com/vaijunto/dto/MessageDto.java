package com.vaijunto.dto;
import com.vaijunto.domain.entities.ConversationMessage;
import java.time.OffsetDateTime;
import java.util.UUID;
public record MessageDto(UUID id, UUID clientId, UUID senderId, String adminSenderName, String kind, String body, String locationJson, UUID replyToId, java.util.List<UUID> mediaIds, java.util.List<MessageMediaDto> media, OffsetDateTime sentAt, OffsetDateTime deliveredAt, OffsetDateTime readAt, OffsetDateTime editedAt, boolean deleted) {
 public static MessageDto from(ConversationMessage m) { var media=m.getMedia().stream().toList(); String adminName=m.getAdminSender()==null?null:m.getAdminSender().getEmail().substring(0,m.getAdminSender().getEmail().indexOf('@')); return new MessageDto(m.getId(),m.getClientId(),m.getSender()==null?null:m.getSender().getId(),adminName,m.getKind(),m.getDeletedAt()==null?m.getBody():null,m.getLocationJson(),m.getReplyTo()==null?null:m.getReplyTo().getId(),media.stream().map(x->x.getId()).toList(),media.stream().map(MessageMediaDto::from).toList(),m.getSentAt(),m.getDeliveredAt(),m.getReadAt(),m.getEditedAt(),m.getDeletedAt()!=null); }
}
