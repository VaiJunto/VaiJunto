package com.vaijunto.service;
import com.vaijunto.domain.entities.*; import com.vaijunto.dto.*; import com.vaijunto.repository.*;
import com.vaijunto.exception.ApiException; import lombok.RequiredArgsConstructor; import org.springframework.stereotype.Service; import org.springframework.transaction.annotation.Transactional;
import java.time.*; import java.util.*;
@Service @RequiredArgsConstructor public class AddressService {
 private final SavedAddressRepository addresses; private final UserRepository users;
 private User user(String email){return users.findByEmail(email).orElseThrow(ApiException::userNotFound);}
 @Transactional(readOnly=true) public List<AddressDto> list(String email){return addresses.findVisible(user(email).getId(),OffsetDateTime.now()).stream().map(AddressDto::from).toList();}
 @Transactional public AddressDto create(AddressRequest r,String email){ User u=user(email); validate(r); if(addresses.countByUserIdAndRecentFalseAndDeletedAtIsNull(u.getId())>=10) throw new IllegalArgumentException("Você pode salvar no máximo 10 endereços."); return AddressDto.from(addresses.save(SavedAddress.builder().user(u).label(r.getLabel().trim().toUpperCase()).addressName(r.getAddressName().trim()).latitude(r.getLatitude()).longitude(r.getLongitude()).build()));}
 @Transactional public AddressDto update(UUID id,AddressRequest r,String email){var a=owned(id,email); validate(r); a.setLabel(r.getLabel().trim().toUpperCase());a.setAddressName(r.getAddressName().trim());a.setLatitude(r.getLatitude());a.setLongitude(r.getLongitude());return AddressDto.from(a);}
 @Transactional public void delete(UUID id,String email){owned(id,email).setDeletedAt(OffsetDateTime.now());}
 @Transactional public void clearRecents(String email){addresses.clearRecents(user(email).getId(),OffsetDateTime.now());}
 private SavedAddress owned(UUID id,String email){var a=addresses.findById(id).orElseThrow(()->new IllegalArgumentException("Endereço não encontrado."));if(!a.getUser().getEmail().equals(email)||a.getDeletedAt()!=null)throw new ApiException(org.springframework.http.HttpStatus.NOT_FOUND,"ADDRESS_NOT_FOUND","Endereço não encontrado.");return a;}
 private void validate(AddressRequest r){if(r.getLabel()==null||r.getLabel().trim().isBlank()||r.getLabel().trim().length()>80||r.getAddressName()==null||r.getAddressName().trim().isBlank()||r.getLatitude()==null||r.getLongitude()==null||Math.abs(r.getLatitude())>90||Math.abs(r.getLongitude())>180)throw new IllegalArgumentException("Informe nome e localização válidos.");}
}
