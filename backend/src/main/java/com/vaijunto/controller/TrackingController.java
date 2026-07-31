package com.vaijunto.controller;

import com.vaijunto.dto.GpsLocationMessage;
import com.vaijunto.service.TrackingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Controller;

@Slf4j
@Controller
@RequiredArgsConstructor
public class TrackingController {

    private final TrackingService trackingService;

    @MessageMapping("/tracking/update")
    public void receiveLocationUpdate(@Payload GpsLocationMessage message) {
        log.debug("Recebido ping GPS para viagem {}: lat={}, lon={}", 
                message.getTripInstanceId(), message.getLatitude(), message.getLongitude());
        trackingService.processAndBroadcastLocation(message);
    }
}
