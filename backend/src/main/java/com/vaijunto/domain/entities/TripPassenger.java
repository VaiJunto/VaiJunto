package com.vaijunto.domain.entities;

import com.vaijunto.domain.enums.PassengerStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "trip_passengers", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"trip_instance_id", "passenger_id"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TripPassenger {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "trip_instance_id", nullable = false)
    private TripInstance tripInstance;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "passenger_id", nullable = false)
    private User passenger;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private PassengerStatus status = PassengerStatus.REQUESTED;

    @Column(name = "checked_in_at")
    private OffsetDateTime checkedInAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;
}
