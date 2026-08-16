package com.vaijunto.service;

import com.vaijunto.domain.entities.*;
import com.vaijunto.domain.enums.*;
import com.vaijunto.dto.*;
import com.vaijunto.exception.ApiException;
import com.vaijunto.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import org.springframework.scheduling.annotation.Scheduled;

@Service
@RequiredArgsConstructor
public class TripService {
    private static final List<PassengerStatus> PENDING = List.of(PassengerStatus.REQUESTED);
    private static final List<PassengerStatus> ACCEPTED = List.of(PassengerStatus.CONFIRMED, PassengerStatus.CHECKED_IN);
    private final TripInstanceRepository tripRepository;
    private final TripPassengerRepository passengerRepository;
    private final OfferRepository offerRepository;
    private final DemandRepository demandRepository;
    private final UserRepository userRepository;
    private final ConversationRepository conversationRepository;
    private final NotificationService notificationService;
    private final RideReviewFlagRepository reviewFlags;
    private final RideReviewRepository rideReviews;
    private final BlockService blockService;

    @Transactional
    public TripInstanceDto createTripFromOffer(UUID offerId) {
        Offer offer = offerRepository.findById(offerId).orElseThrow(() -> missing("Oferta não encontrada"));
        TripInstance trip = TripInstance.builder().offer(offer).route(offer.getRoute()).driver(offer.getDriver())
                .scheduledDeparture(offer.getDepartureAt()).status(TripStatus.SCHEDULED).build();
        return tripDto(tripRepository.save(trip));
    }

    /** Compatibilidade para o fluxo antigo; os endpoints públicos usam a sessão. */
    @Transactional
    public TripPassengerDto requestSeat(UUID tripId, UUID passengerId) {
        TripInstance trip = tripRepository.findById(tripId).orElseThrow(() -> missing("Viagem não encontrada"));
        User passenger = userRepository.findById(passengerId).orElseThrow(() -> missing("Passageiro não encontrado"));
        return requestSeat(trip, passenger);
    }

    @Transactional
    public TripPassengerDto requestSeatForOffer(UUID offerId, String email) {
        User passenger = current(email);
        Offer offer = offerRepository.findByIdForUpdate(offerId).orElseThrow(() -> missing("Oferta não encontrada"));
        if (offer.getDriver().getId().equals(passenger.getId())) throw forbidden("Você não pode solicitar sua própria carona.");
        if (offer.getStatus() != OfferStatus.ACTIVE || offer.getAvailableSeats() < 1 || !offer.getDepartureAt().isAfter(OffsetDateTime.now())) throw conflict("Esta carona não está mais disponível.");
        TripInstance trip = tripRepository.findByDriverId(offer.getDriver().getId()).stream()
                .filter(t -> offerId.equals(t.getOffer() == null ? null : t.getOffer().getId())).findFirst()
                .orElseGet(() -> tripRepository.save(TripInstance.builder().offer(offer).route(offer.getRoute()).driver(offer.getDriver()).scheduledDeparture(offer.getDepartureAt()).status(TripStatus.SCHEDULED).build()));
        return requestSeat(trip, passenger);
    }

    private TripPassengerDto requestSeat(TripInstance trip, User passenger) {
        if (blockService.blocked(trip.getDriver().getId(), passenger.getId())) throw forbidden("Esta carona não está disponível.");
        if (trip.getDriver().getId().equals(passenger.getId())) throw forbidden("Você não pode solicitar sua própria carona.");
        var existing = passengerRepository.findByTripInstanceIdAndPassengerId(trip.getId(), passenger.getId());
        if (existing.isPresent()) {
            if (existing.get().getStatus() == PassengerStatus.REQUESTED) return passengerDto(existing.get()); // idempotência
            throw conflict("Você já teve uma decisão para esta carona.");
        }
        TripPassenger saved = passengerRepository.save(TripPassenger.builder().tripInstance(trip).passenger(passenger).status(PassengerStatus.REQUESTED).build());
        ensureConversation(trip, passenger);
        notificationService.createAndSendNotification(trip.getDriver().getId(), "Novo pedido de vaga", passenger.getName() + " pediu uma vaga na sua carona.", "RIDE_REQUEST", json(trip.getId()), null);
        return passengerDto(saved);
    }

    @Transactional
    public TripPassengerDto accept(UUID passengerLinkId, String email) {
        TripPassenger link = passengerRepository.findById(passengerLinkId).orElseThrow(() -> missing("Solicitação não encontrada"));
        User actor = current(email);
        if (!link.getTripInstance().getDriver().getId().equals(actor.getId())) throw forbidden("Somente o motorista pode aceitar.");
        if (link.getStatus() == PassengerStatus.CONFIRMED) return passengerDto(link); // idempotência
        if (link.getStatus() != PassengerStatus.REQUESTED) throw conflict("Esta solicitação não está pendente.");
        Offer offer = link.getTripInstance().getOffer();
        if (offer != null) {
            offer = offerRepository.findByIdForUpdate(offer.getId()).orElseThrow(() -> missing("Oferta não encontrada"));
            if (offer.getAvailableSeats() < 1 || offer.getStatus() != OfferStatus.ACTIVE) throw conflict("As vagas foram preenchidas.");
        }
        OffsetDateTime at = link.getTripInstance().getScheduledDeparture();
        if (passengerRepository.existsAcceptedOverlap(link.getPassenger().getId(), at.minusMinutes(90), at.plusMinutes(90), link.getId())) throw conflict("A pessoa já possui uma carona aceita neste horário.");
        link.setStatus(PassengerStatus.CONFIRMED);
        if (offer != null) {
            offer.setAvailableSeats(offer.getAvailableSeats() - 1);
            offer.setStatus(offer.getAvailableSeats() == 0 ? OfferStatus.FULL : OfferStatus.ACTIVE);
            if (offer.getStatus() == OfferStatus.FULL) closePendingForFull(link.getTripInstance(), link.getId());
        }
        if (link.getDemand() != null) {
            link.getDemand().setStatus(DemandStatus.MATCHED);
            closeOtherProposals(link.getDemand(), link.getId());
        }
        closePassengerConflicts(link.getPassenger(), link.getId(), at);
        notificationService.createAndSendNotification(link.getPassenger().getId(), "Vaga confirmada", "Sua participação foi aceita.", "RIDE_ACCEPTED", json(link.getTripInstance().getId()), null);
        return passengerDto(link);
    }

    @Transactional
    public TripPassengerDto decline(UUID passengerLinkId, String email) {
        TripPassenger link = passengerRepository.findById(passengerLinkId).orElseThrow(() -> missing("Solicitação não encontrada"));
        if (!link.getTripInstance().getDriver().getId().equals(current(email).getId())) throw forbidden("Somente o motorista pode recusar.");
        if (link.getStatus() == PassengerStatus.DECLINED) return passengerDto(link);
        if (link.getStatus() != PassengerStatus.REQUESTED) throw conflict("Esta solicitação não está pendente.");
        link.setStatus(PassengerStatus.DECLINED);
        notificationService.createAndSendNotification(link.getPassenger().getId(), "Solicitação recusada", "Esta carona não poderá seguir com você.", "RIDE_DECLINED", json(link.getTripInstance().getId()), null);
        return passengerDto(link);
    }

    /** Retirar proposta não é uma recusa e não cria histórico negativo para o passageiro. */
    @Transactional
    public TripPassengerDto withdrawProposal(UUID passengerLinkId, String email) {
        TripPassenger link = passengerRepository.findById(passengerLinkId).orElseThrow(() -> missing("Proposta não encontrada"));
        if (link.getDemand() == null || !link.getTripInstance().getDriver().getId().equals(current(email).getId())) throw forbidden("Somente o motorista da proposta pode retirá-la.");
        if (link.getStatus() == PassengerStatus.WITHDRAWN) return passengerDto(link);
        if (link.getStatus() != PassengerStatus.REQUESTED) throw conflict("Esta proposta não está pendente.");
        link.setStatus(PassengerStatus.WITHDRAWN);
        notificationService.createAndSendNotification(link.getPassenger().getId(), "Proposta retirada", "O motorista retirou a proposta de carona.", "RIDE_PROPOSAL_WITHDRAWN", json(link.getTripInstance().getId()), null);
        return passengerDto(link);
    }

    @Transactional
    public TripPassengerDto propose(UUID demandId, String email) {
        User driver = current(email);
        Demand demand = demandRepository.findById(demandId).orElseThrow(() -> missing("Pedido não encontrado"));
        if (demand.getPassenger().getId().equals(driver.getId())) throw forbidden("Você não pode propor para seu próprio pedido.");
        if (demand.getStatus() != DemandStatus.OPEN || !demand.getDesiredTime().isAfter(OffsetDateTime.now())) throw conflict("Este pedido não está disponível.");
        TripInstance trip = tripRepository.save(TripInstance.builder().driver(driver).scheduledDeparture(demand.getDesiredTime()).status(TripStatus.SCHEDULED).build());
        TripPassenger link = passengerRepository.save(TripPassenger.builder().tripInstance(trip).passenger(demand.getPassenger()).demand(demand).status(PassengerStatus.REQUESTED).build());
        ensureConversation(trip, demand.getPassenger());
        notificationService.createAndSendNotification(demand.getPassenger().getId(), "Nova proposta de carona", driver.getName() + " enviou uma proposta para seu pedido.", "RIDE_PROPOSAL", json(trip.getId()), null);
        return passengerDto(link);
    }

    @Transactional
    public TripPassengerDto cancel(UUID passengerLinkId, CancelParticipationRequest request, String email) {
        TripPassenger link = passengerRepository.findById(passengerLinkId).orElseThrow(() -> missing("Participação não encontrada"));
        if (!link.getPassenger().getId().equals(current(email).getId())) throw forbidden("Somente o passageiro pode cancelar.");
        if (link.getStatus() == PassengerStatus.CANCELLED || link.getStatus() == PassengerStatus.WITHDRAWN) return passengerDto(link);
        if (!List.of(PassengerStatus.REQUESTED, PassengerStatus.CONFIRMED).contains(link.getStatus())) throw conflict("Esta participação não pode mais ser cancelada.");
        List<String> reasons = List.of("MUDANÇA DE PLANOS", "ENCONTREI OUTRA CARONA", "NÃO POSSO ESPERAR", "PEDIDO FEITO POR ENGANO", "QUESTÃO DE SEGURANÇA", "OUTRO");
        if (request.reason() != null && !reasons.contains(request.reason())) throw conflict("Motivo de cancelamento inválido.");
        if ("OUTRO".equals(request.reason()) && (request.note() == null || request.note().isBlank())) throw conflict("Explique o motivo selecionado como OUTRO.");
        boolean accepted = link.getStatus() == PassengerStatus.CONFIRMED;
        link.setStatus(accepted ? PassengerStatus.CANCELLED : PassengerStatus.WITHDRAWN);
        link.setCancellationReason(request.reason()); link.setCancellationNote(request.note());
        Offer offer = link.getTripInstance().getOffer();
        if (accepted && offer != null) { offer.setAvailableSeats(offer.getAvailableSeats() + 1); offer.setStatus(OfferStatus.ACTIVE); }
        if (accepted && link.getDemand() != null) link.getDemand().setStatus(DemandStatus.OPEN);
        flagForManualReviewIfNeeded(link.getPassenger());
        notificationService.createAndSendNotification(link.getTripInstance().getDriver().getId(), "Participação cancelada", "O passageiro cancelou a participação" + (request.reason() == null ? "." : ": " + request.reason() + "."), "RIDE_CANCELLED", json(link.getTripInstance().getId()), null);
        return passengerDto(link);
    }

    @Transactional public void performCheckIn(UUID tripId, UUID passengerId, boolean attending) {
        TripPassenger tp = passengerRepository.findByTripInstanceIdAndPassengerId(tripId, passengerId).orElseThrow(() -> missing("Vínculo de passageiro não encontrado"));
        if (!tp.getTripInstance().getScheduledDeparture().isBefore(OffsetDateTime.now())) throw conflict("A ausência só pode ser registrada após o horário esperado.");
        if (!List.of(PassengerStatus.CONFIRMED,PassengerStatus.CHECKED_IN).contains(tp.getStatus())) throw conflict("Participação não elegível para presença.");
        tp.setStatus(attending ? PassengerStatus.CHECKED_IN : PassengerStatus.ABSENT); if (attending) tp.setCheckedInAt(OffsetDateTime.now()); else notificationService.createAndSendNotification(tp.getPassenger().getId(),"Ausência registrada","Você tem 48 horas para contestar esta ocorrência.","RIDE_ABSENCE",json(tripId),null);
    }
    @Transactional public TripInstanceDto start(UUID tripId, StartTripRequest request, String email) { TripInstance trip=tripRepository.findById(tripId).orElseThrow(()->missing("Viagem não encontrada"));if(!trip.getDriver().getId().equals(current(email).getId()))throw forbidden("Somente o motorista pode iniciar.");if(trip.getStatus()==TripStatus.IN_PROGRESS)return tripDto(trip);if(trip.getStatus()!=TripStatus.SCHEDULED)throw conflict("A carona não pode ser iniciada.");OffsetDateTime now=OffsetDateTime.now();boolean all=passengerRepository.findByTripInstanceId(tripId).stream().filter(p->p.getStatus()==PassengerStatus.CONFIRMED).allMatch(p->p.getCheckedInAt()!=null);if(now.isBefore(trip.getScheduledDeparture().minusMinutes(15))&&!all)throw conflict("Sem todas as confirmações, a saída só pode antecipar 15 minutos.");if(now.isAfter(trip.getScheduledDeparture().plusMinutes(15))&&(request==null||request.expectedDeparture()==null))throw conflict("Informe a nova previsão de saída para atrasos acima de 15 minutos.");trip.setActualStart(now);trip.setStatus(TripStatus.IN_PROGRESS);passengerRepository.findByTripInstanceId(tripId).stream().filter(p->p.getStatus()==PassengerStatus.CONFIRMED).forEach(p->notificationService.createAndSendNotification(p.getPassenger().getId(),"Carona iniciada","O motorista confirmou o início real da carona.","RIDE_STARTED",json(tripId),null));return tripDto(trip); }
    @Transactional public TripInstanceDto finish(UUID tripId, FinishTripRequest request, String email) {TripInstance trip=tripRepository.findById(tripId).orElseThrow(()->missing("Viagem não encontrada"));if(!trip.getDriver().getId().equals(current(email).getId()))throw forbidden("Somente o motorista pode finalizar.");if(trip.getStatus()==TripStatus.COMPLETED)return tripDto(trip);if(trip.getStatus()!=TripStatus.IN_PROGRESS)throw conflict("Inicie a carona antes de finalizar.");boolean near=request!=null&&request.latitude()!=null&&request.longitude()!=null&&withinDestination(trip,request.latitude(),request.longitude());if(!near&&(request==null||request.reason()==null||request.reason().isBlank()))throw conflict("Fora do destino, informe uma justificativa.");trip.setActualEnd(OffsetDateTime.now());trip.setFinishReason(near?"DESTINATION_RADIUS":request.reason());trip.setFinishNote(request==null?null:request.note());trip.setStatus(TripStatus.COMPLETED);if(trip.getOffer()!=null)trip.getOffer().setStatus(OfferStatus.FINISHED);passengerRepository.findByTripInstanceId(tripId).stream().filter(p->p.getStatus()==PassengerStatus.CONFIRMED||p.getStatus()==PassengerStatus.CHECKED_IN).forEach(p->notificationService.createAndSendNotification(p.getPassenger().getId(),"Carona concluída","Sua avaliação privada fica disponível por 7 dias.","RIDE_COMPLETED",json(tripId),null));return tripDto(trip);}
    @Transactional public void destinationPresence(UUID tripId,double latitude,double longitude,String email){TripInstance trip=tripRepository.findById(tripId).orElseThrow(()->missing("Viagem não encontrada"));if(!trip.getDriver().getId().equals(current(email).getId()))throw forbidden("Somente o motorista pode enviar localização.");if(trip.getStatus()==TripStatus.IN_PROGRESS)trip.setFinalRadiusSince(withinDestination(trip,latitude,longitude)?(trip.getFinalRadiusSince()==null?OffsetDateTime.now():trip.getFinalRadiusSince()):null);}
    @Transactional public TripPassengerDto contestAbsence(UUID id,String explanation,String email){TripPassenger p=passengerRepository.findById(id).orElseThrow(()->missing("Participação não encontrada"));if(!p.getPassenger().getId().equals(current(email).getId()))throw forbidden("Somente a pessoa marcada pode contestar.");if(p.getStatus()!=PassengerStatus.ABSENT||p.getUpdatedAt().plusHours(48).isBefore(OffsetDateTime.now()))throw conflict("O prazo de contestação expirou.");if(explanation==null||explanation.isBlank())throw conflict("Explique sua contestação.");p.setAbsenceContestedAt(OffsetDateTime.now());p.setAbsenceContestation(explanation.trim());return passengerDto(p);}
    @Transactional public void review(UUID tripId,ReviewRideRequest request,String email){User reviewer=current(email);TripInstance trip=tripRepository.findById(tripId).orElseThrow(()->missing("Viagem não encontrada"));if(trip.getStatus()!=TripStatus.COMPLETED||trip.getActualEnd().plusDays(7).isBefore(OffsetDateTime.now()))throw conflict("A avaliação não está disponível.");User reviewee=userRepository.findById(request.revieweeId()).orElseThrow(()->missing("Usuário não encontrado"));boolean participant=trip.getDriver().getId().equals(reviewer.getId())?passengerRepository.findByTripInstanceId(tripId).stream().anyMatch(p->p.getPassenger().getId().equals(reviewee.getId())):trip.getDriver().getId().equals(reviewee.getId())&&passengerRepository.findByTripInstanceIdAndPassengerId(tripId,reviewer.getId()).isPresent();if(!participant)throw forbidden("Avaliação inválida.");if(!rideReviews.existsByTripIdAndReviewerIdAndRevieweeId(tripId,reviewer.getId(),reviewee.getId()))rideReviews.save(RideReview.builder().trip(trip).reviewer(reviewer).reviewee(reviewee).rating(request.rating()).build());}
    @Scheduled(fixedDelay = 60000) @Transactional public void completeEligibleTrips(){OffsetDateTime now=OffsetDateTime.now();tripRepository.findByStatusAndScheduledDepartureBefore(TripStatus.IN_PROGRESS,now.minusMinutes(15)).forEach(t->{if(t.getFinalRadiusSince()!=null&&t.getFinalRadiusSince().plusMinutes(15).isBefore(now)){t.setActualEnd(now);t.setFinishReason("DESTINATION_RADIUS_AUTO");t.setStatus(TripStatus.COMPLETED);if(t.getOffer()!=null)t.getOffer().setStatus(OfferStatus.FINISHED);}});}
    private boolean withinDestination(TripInstance t,double lat,double lon){if(t.getRoute()==null||t.getRoute().getDestinationLocation()==null)return false;double dy=(t.getRoute().getDestinationLocation().getY()-lat)*111000d,dx=(t.getRoute().getDestinationLocation().getX()-lon)*111000d*Math.cos(Math.toRadians(lat));return Math.hypot(dx,dy)<=500d;}
    @Transactional(readOnly = true) public List<TripPassengerDto> getTripPassengers(UUID tripId, String email) {
        User actor=current(email); TripInstance trip=tripRepository.findById(tripId).orElseThrow(() -> missing("Viagem não encontrada"));
        if (!trip.getDriver().getId().equals(actor.getId()) && passengerRepository.findByTripInstanceIdAndPassengerId(tripId, actor.getId()).isEmpty()) throw forbidden("Você não tem acesso a esta carona.");
        return passengerRepository.findByTripInstanceId(tripId).stream().map(this::passengerDto).toList();
    }
    @Transactional(readOnly = true) public List<TripInstanceDto> mine(String email) { User actor=current(email); java.util.LinkedHashMap<UUID,TripInstance> own=new java.util.LinkedHashMap<>();tripRepository.findByDriverId(actor.getId()).forEach(t->own.put(t.getId(),t));passengerRepository.findAll().stream().filter(p->p.getPassenger().getId().equals(actor.getId())).forEach(p->own.put(p.getTripInstance().getId(),p.getTripInstance()));return own.values().stream().sorted(java.util.Comparator.comparing(TripInstance::getScheduledDeparture)).map(this::tripDto).toList(); }
    public List<TripPassengerDto> getTripPassengers(UUID tripId) { return passengerRepository.findByTripInstanceId(tripId).stream().map(this::passengerDto).toList(); }

    private void ensureConversation(TripInstance trip, User passenger) { if (!blockService.blocked(trip.getDriver().getId(), passenger.getId()) && !conversationRepository.existsByRideIdAndParticipantAIdAndParticipantBId(trip.getId(), trip.getDriver().getId(), passenger.getId())) conversationRepository.save(Conversation.builder().type("RIDE").ride(trip).participantA(trip.getDriver()).participantB(passenger).lastActivityAt(OffsetDateTime.now()).build()); }
    private void closePendingForFull(TripInstance trip, UUID acceptedId) { passengerRepository.findByTripInstanceId(trip.getId()).stream().filter(p -> !p.getId().equals(acceptedId) && p.getStatus()==PassengerStatus.REQUESTED).forEach(p -> { p.setStatus(PassengerStatus.EXPIRED); notificationService.createAndSendNotification(p.getPassenger().getId(), "Vagas preenchidas", "As vagas desta carona foram preenchidas.", "RIDE_FULL", json(trip.getId()), null); }); }
    private void closeOtherProposals(Demand demand, UUID acceptedId) { passengerRepository.findAll().stream().filter(p -> p.getDemand()!=null && p.getDemand().getId().equals(demand.getId()) && !p.getId().equals(acceptedId) && p.getStatus()==PassengerStatus.REQUESTED).forEach(p -> p.setStatus(PassengerStatus.EXPIRED)); }
    private void closePassengerConflicts(User passenger, UUID acceptedId, OffsetDateTime at) { passengerRepository.findAll().stream().filter(p -> p.getPassenger().getId().equals(passenger.getId()) && !p.getId().equals(acceptedId) && p.getStatus()==PassengerStatus.REQUESTED && !p.getTripInstance().getScheduledDeparture().isBefore(at.minusMinutes(90)) && !p.getTripInstance().getScheduledDeparture().isAfter(at.plusMinutes(90))).forEach(p -> p.setStatus(PassengerStatus.EXPIRED)); }
    private User current(String email) { return userRepository.findByEmail(email).orElseThrow(ApiException::userNotFound); }
    private void flagForManualReviewIfNeeded(User passenger) {
        long inThirtyDays = passengerRepository.countByPassengerIdAndStatusInAndUpdatedAtAfter(passenger.getId(), List.of(PassengerStatus.CANCELLED), OffsetDateTime.now().minusDays(30));
        long inLastHour = passengerRepository.countByPassengerIdAndStatusInAndUpdatedAtAfter(passenger.getId(), List.of(PassengerStatus.CANCELLED), OffsetDateTime.now().minusHours(1));
        if ((inThirtyDays >= 3 || inLastHour >= 2) && !reviewFlags.existsByUserIdAndStatus(passenger.getId(), "PENDING")) reviewFlags.save(RideReviewFlag.builder().user(passenger).reason(inLastHour >= 2 ? "TWO_CANCELLATIONS_IN_ONE_HOUR" : "THREE_CANCELLATIONS_IN_THIRTY_DAYS").build());
    }
    private ApiException missing(String m) { return new ApiException(HttpStatus.NOT_FOUND,"RIDE_NOT_FOUND",m); } private ApiException forbidden(String m) { return new ApiException(HttpStatus.FORBIDDEN,"RIDE_FORBIDDEN",m); } private ApiException conflict(String m) { return new ApiException(HttpStatus.CONFLICT,"RIDE_STATE_CONFLICT",m); }
    private String json(UUID id) { return "{\"tripId\":\""+id+"\"}"; }
    private TripInstanceDto tripDto(TripInstance t) { return TripInstanceDto.builder().id(t.getId()).offerId(t.getOffer()==null?null:t.getOffer().getId()).routeId(t.getRoute()==null?null:t.getRoute().getId()).driverId(t.getDriver().getId()).scheduledDeparture(t.getScheduledDeparture()).actualStart(t.getActualStart()).actualEnd(t.getActualEnd()).finishReason(t.getFinishReason()).status(t.getStatus()).build(); }
    private TripPassengerDto passengerDto(TripPassenger p) { return TripPassengerDto.builder().id(p.getId()).tripInstanceId(p.getTripInstance().getId()).passengerId(p.getPassenger().getId()).passengerName(p.getPassenger().getName()).status(p.getStatus()).checkedInAt(p.getCheckedInAt()).demandId(p.getDemand()==null?null:p.getDemand().getId()).cancellationReason(p.getCancellationReason()).build(); }
}
