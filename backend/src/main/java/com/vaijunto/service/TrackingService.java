package com.vaijunto.service;

import com.vaijunto.domain.entities.GpsPing;
import com.vaijunto.domain.entities.TripInstance;
import com.vaijunto.dto.GpsLocationMessage;
import com.vaijunto.repository.GpsPingRepository;
import com.vaijunto.repository.TripInstanceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class TrackingService {

    private final SimpMessagingTemplate messagingTemplate;
    private final GpsPingRepository gpsPingRepository;
    private final TripInstanceRepository tripInstanceRepository;
    
    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    @Transactional
    public void processAndBroadcastLocation(GpsLocationMessage message) {
        TripInstance trip = tripInstanceRepository.findById(message.getTripInstanceId())
                .orElse(null);

        if (trip == null) {
            log.warn("Tentativa de envio de GPS para viagem inexistente: {}", message.getTripInstanceId());
            return;
        }

        Point location = geometryFactory.createPoint(new Coordinate(message.getLongitude(), message.getLatitude()));
        
        GpsPing ping = GpsPing.builder()
                .tripInstance(trip)
                .location(location)
                .speed(message.getSpeed())
                .heading(message.getHeading())
                .recordedAt(OffsetDateTime.now())
                .build();

        gpsPingRepository.save(ping);

        // Broadcast to specific trip topic
        String destination = "/topic/trips/" + trip.getId() + "/tracking";
        messagingTemplate.convertAndSend(destination, message);
    }
}
