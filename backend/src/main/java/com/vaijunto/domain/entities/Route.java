package com.vaijunto.domain.entities;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import org.locationtech.jts.geom.LineString;
import org.locationtech.jts.geom.Point;

import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "routes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Route {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vehicle_id")
    private Vehicle vehicle;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "driver_id", nullable = false)
    private User driver;

    @Column
    private String name;

    @Column(name = "origin_name", nullable = false)
    private String originName;

    @Column(name = "origin_location", nullable = false, columnDefinition = "geography(Point,4326)")
    private Point originLocation;

    @Column(name = "destination_name", nullable = false)
    private String destinationName;

    @Column(name = "destination_location", nullable = false, columnDefinition = "geography(Point,4326)")
    private Point destinationLocation;

    @Column(columnDefinition = "geography(LineString,4326)")
    private LineString waypoints;

    @Column(name = "departure_time", nullable = false)
    private LocalTime departureTime;

    @Column(name = "days_of_week", columnDefinition = "integer[]")
    private Integer[] daysOfWeek;

    @Column(name = "is_recurrent", nullable = false)
    @Builder.Default
    private Boolean isRecurrent = true;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;
}
