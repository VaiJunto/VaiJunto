package com.vaijunto.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.util.List;
import org.springframework.data.domain.Page;

@Getter @AllArgsConstructor
public class PageResponse<T> {
    private final List<T> content;
    private final int page;
    private final int size;
    private final long totalElements;
    private final int totalPages;
    private final boolean hasNext;
    public static <T> PageResponse<T> from(Page<T> page) { return new PageResponse<>(page.getContent(), page.getNumber(), page.getSize(), page.getTotalElements(), page.getTotalPages(), page.hasNext()); }
}
