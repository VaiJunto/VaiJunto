package com.vaijunto.service;

import com.vaijunto.config.R2Config.R2Properties;
import com.vaijunto.domain.entities.ChatSticker;
import com.vaijunto.exception.ApiException;
import com.vaijunto.repository.ChatStickerRepository;
import java.net.URI;
import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;

@Service @RequiredArgsConstructor
public class ChatStickerAssetService {
 private static final long MAX_SIZE = 2L * 1024 * 1024;
 private static final Set<String> TYPES = Set.of("image/png", "image/jpeg", "image/webp", "image/gif");
 private final R2Properties r2; private final ObjectProvider<S3Client> clients; private final ObjectProvider<S3Presigner> presigners; private final ChatStickerRepository stickers;
 @Transactional public ChatSticker create(String code,String label,MultipartFile asset){String c=code==null?"":code.trim(),l=label==null?"":label.trim();if(!c.matches("[a-z0-9_-]{2,80}"))throw bad("STICKER_CODE_INVALID","Use de 2 a 80 letras minúsculas, números, _ ou - no código.");if(l.isBlank()||l.length()>120)throw bad("STICKER_LABEL_INVALID","Informe um nome de até 120 caracteres.");if(asset==null||asset.isEmpty())throw bad("STICKER_FILE_REQUIRED","Escolha uma imagem ou GIF para a figurinha.");if(asset.getSize()>MAX_SIZE)throw bad("STICKER_FILE_TOO_LARGE","A figurinha pode ter no máximo 2 MB.");String type=asset.getContentType()==null?"":asset.getContentType().toLowerCase(Locale.ROOT);if(!TYPES.contains(type))throw bad("STICKER_TYPE_INVALID","Use PNG, JPG, WEBP ou GIF.");if(stickers.existsByCode(c))throw new ApiException(HttpStatus.CONFLICT,"STICKER_EXISTS","Já existe uma figurinha com esse código.");requireR2();String key="stickers/"+UUID.randomUUID();try{clients.getObject().putObject(PutObjectRequest.builder().bucket(r2.bucket()).key(key).contentType(type).contentLength(asset.getSize()).build(),RequestBody.fromInputStream(asset.getInputStream(),asset.getSize()));}catch(Exception error){throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,"STICKER_UPLOAD_FAILED","Não foi possível enviar a figurinha agora.");}return stickers.save(ChatSticker.builder().code(c).label(l).storageKey(key).contentType(type).active(true).createdAt(OffsetDateTime.now()).build());}
 @Transactional(readOnly=true) public URI assetUrl(UUID id){var sticker=stickers.findById(id).filter(ChatSticker::isActive).orElseThrow(()->bad("STICKER_NOT_FOUND","Figurinha não encontrada."));requireR2();return URI.create(presigners.getObject().presignGetObject(GetObjectPresignRequest.builder().getObjectRequest(GetObjectRequest.builder().bucket(r2.bucket()).key(sticker.getStorageKey()).build()).signatureDuration(Duration.ofMinutes(10)).build()).url().toString());}
 private void requireR2(){if(!r2.configured()||!r2.isCloudflareR2()||clients.getIfAvailable()==null||presigners.getIfAvailable()==null)throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,"MEDIA_NOT_CONFIGURED","O armazenamento Cloudflare R2 ainda não está configurado.");} private ApiException bad(String code,String message){return new ApiException(HttpStatus.BAD_REQUEST,code,message);}
}
