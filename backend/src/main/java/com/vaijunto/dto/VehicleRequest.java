package com.vaijunto.dto;
import com.vaijunto.domain.enums.VehicleType; import lombok.*;
@Getter @Setter public class VehicleRequest { private String licensePlate, model, make, trim, color, fuel, photoUrl; private Integer year, capacity; private Double averageConsumption; private VehicleType vehicleType; }
