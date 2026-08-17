package com.vaijunto.repository;
import com.vaijunto.domain.entities.ChatSticker;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;
public interface ChatStickerRepository extends JpaRepository<ChatSticker, UUID> { List<ChatSticker> findByActiveTrueOrderByLabelAsc(); List<ChatSticker> findAllByOrderByLabelAsc(); boolean existsByCode(String code); }
