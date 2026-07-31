package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import org.locationtech.jts.geom.Point;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "gps_pings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GpsPing {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_instance_id", nullable = false)
    private TripInstance tripInstance;

    @Column(nullable = false, columnDefinition = "geography(Point,4326)")
    private Point location;

    @Column
    private Double speed;

    @Column
    private Double heading;

    @Column(name = "recorded_at", nullable = false, updatable = false)
    @Builder.Default
    private OffsetDateTime recordedAt = OffsetDateTime.now();
}
