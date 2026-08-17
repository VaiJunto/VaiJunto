package com.vaijunto.service;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.vaijunto.domain.entities.Conversation;
import com.vaijunto.domain.entities.TripInstance;
import com.vaijunto.domain.entities.TripPassenger;
import com.vaijunto.domain.entities.User;
import com.vaijunto.repository.ConversationRepository;
import com.vaijunto.repository.OfferRepository;
import com.vaijunto.repository.TripInstanceRepository;
import com.vaijunto.repository.TripPassengerRepository;
import com.vaijunto.repository.UserRepository;
import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class TripServiceTest {
    @Mock TripInstanceRepository trips;
    @Mock TripPassengerRepository passengers;
    @Mock OfferRepository offers;
    @Mock UserRepository users;
    @Mock ConversationRepository conversations;
    @Mock NotificationService notifications;
    @Mock BlockService blocks;
    @InjectMocks TripService service;

    @Test
    void requestSeatCreatesOnlyDriverPassengerConversation() {
        UUID tripId = UUID.randomUUID(); UUID driverId = UUID.randomUUID(); UUID passengerId = UUID.randomUUID();
        User driver = User.builder().id(driverId).name("Motorista").build();
        User passenger = User.builder().id(passengerId).name("Passageiro").build();
        TripInstance trip = TripInstance.builder().id(tripId).driver(driver).scheduledDeparture(OffsetDateTime.now()).build();
        when(trips.findById(tripId)).thenReturn(Optional.of(trip));
        when(users.findById(passengerId)).thenReturn(Optional.of(passenger));
        when(passengers.save(any(TripPassenger.class))).thenAnswer(call -> call.getArgument(0));
        when(conversations.existsByRideIdAndParticipantAIdAndParticipantBId(tripId, driverId, passengerId)).thenReturn(false);
        when(blocks.blocked(driverId, passengerId)).thenReturn(false);

        service.requestSeat(tripId, passengerId);

        ArgumentCaptor<Conversation> created = ArgumentCaptor.forClass(Conversation.class);
        verify(conversations).save(created.capture());
        org.junit.jupiter.api.Assertions.assertSame(driver, created.getValue().getParticipantA());
        org.junit.jupiter.api.Assertions.assertSame(passenger, created.getValue().getParticipantB());
        org.junit.jupiter.api.Assertions.assertSame(trip, created.getValue().getRide());
        verify(conversations).existsByRideIdAndParticipantAIdAndParticipantBId(eq(tripId), eq(driverId), eq(passengerId));
    }
}
