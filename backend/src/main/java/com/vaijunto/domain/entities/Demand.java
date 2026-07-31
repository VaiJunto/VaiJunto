package com.vaijunto.domain.entities;

import com.vaijunto.domain.enums.DemandStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.locationtech.jts.geom.Point;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "demands")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Demand {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "passenger_id", nullable = false)
    private User passenger;

    @Column(name = "origin_name", nullable = false)
    private String originName;

    @Column(name = "origin_location", nullable = false, columnDefinition = "geography(Point,4326)")
    private Point originLocation;

    @Column(name = "destination_name", nullable = false)
    private String destinationName;

    @Column(name = "destination_location", nullable = false, columnDefinition = "geography(Point,4326)")
    private Point destinationLocation;

    @Column(name = "desired_time", nullable = false)
    private OffsetDateTime desiredTime;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private DemandStatus status = DemandStatus.OPEN;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;
}
