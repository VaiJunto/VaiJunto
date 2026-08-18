package com.vaijunto.service;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.vaijunto.domain.entities.User;
import com.vaijunto.domain.entities.Vehicle;
import com.vaijunto.dto.CreateOfferRequest;
import com.vaijunto.dto.LocationDto;
import com.vaijunto.repository.OfferRepository;
import com.vaijunto.repository.RouteRepository;
import com.vaijunto.repository.TripInstanceRepository;
import com.vaijunto.repository.TripPassengerRepository;
import com.vaijunto.repository.UserRepository;
import com.vaijunto.repository.VehicleRepository;
import java.math.BigDecimal;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class OfferServiceOwnershipTest {
    @Test
    void vehicleFromAnotherUserIsRejected() {
        var offers = mock(OfferRepository.class);
        var routes = mock(RouteRepository.class);
        var users = mock(UserRepository.class);
        var vehicles = mock(VehicleRepository.class);
        var driver = User.builder().id(UUID.randomUUID()).email("driver@fatec.sp.gov.br").build();
        var other = User.builder().id(UUID.randomUUID()).email("other@fatec.sp.gov.br").build();
        var vehicleId = UUID.randomUUID();
        when(users.findByEmail(driver.getEmail())).thenReturn(Optional.of(driver));
        when(vehicles.findById(vehicleId)).thenReturn(Optional.of(
                Vehicle.builder().id(vehicleId).driver(other).capacity(4).build()));
        var service = new OfferService(offers, routes, users, vehicles,
                mock(TripPassengerRepository.class), mock(TripInstanceRepository.class),
                mock(NotificationService.class), mock(BlockService.class),
                mock(RealtimeEventPublisher.class));
        var request = CreateOfferRequest.builder()
                .routeName("Centro para Fatec")
                .originName("Centro")
                .originLocation(new LocationDto(-23.1, -45.9))
                .destinationName("FATEC")
                .destinationLocation(new LocationDto(-23.2, -45.8))
                .departureTime(LocalTime.now().plusHours(2))
                .departureAt(OffsetDateTime.now().plusHours(2))
                .isRecurrent(false)
                .vehicleId(vehicleId)
                .availableSeats(2)
                .price(BigDecimal.ZERO)
                .build();

        assertThrows(IllegalArgumentException.class,
                () -> service.createOffer(request, driver.getEmail()));
    }
}
