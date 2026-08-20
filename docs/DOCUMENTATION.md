# Documentação do Projeto: VaiJunto (MVP)

> Plataforma de mobilidade universitária e caronas (modelo School-Bus tracker + BlaBlaCar).

## 1. Visão Geral e Arquitetura

O **VaiJunto** é um ecossistema projetado para unificar motoristas de van, caroneiros e passageiros universitários. 

### Arquitetura de Alto Nível
- **Frontend Mobile**: Aplicativo Híbrido (Flutter) arquitetado sob o padrão Feature-First + Injeção de dependências (Riverpod).
- **Backend API**: Monolito construído em Java 17 + Spring Boot 3, servindo Endpoints REST, conexões de socket seguras e conectores para Push Notification.
- **Persistência de Dados**: PostgreSQL 16 Relacional + Extensão **PostGIS** para mapeamento e matching inteligente geoespacial de rotas/ofertas.
- **Rastreamento em Tempo Real**: Canal bidirecional sobre STOMP (WebSocket) gerido diretamente pela engine do Spring Boot.

---

## 2. Tecnologias e Ferramentas

### 2.1 Backend (Spring Boot)
- **Framework Core**: Spring Boot 3.2.x (Web, Data JPA, Security).
- **Linguagem**: Java 17.
- **Autenticação**: Spring Security 6 (Stateless) + JWT Tokens (io.jsonwebtoken).
- **Geolocalização**: Hibernate Spatial + PostgisDialect (uso de geometrias da API JTS `org.locationtech.jts`).
- **Comunicação Tempo Real**: Spring WebSocket MessageBroker (STOMP).
- **Banco de Dados**: PostgreSQL 16.3 + Migrations de Schema via **Flyway**.
- **Notificações**: Firebase Admin SDK 9.2 (Firebase Cloud Messaging).

### 2.2 Frontend (Flutter)
- **Gerência de Estado**: `flutter_riverpod` (Providers, FutureProviders, StateNotifiers).
- **Comunicação HTTP**: `dio` (com Interceptors globais de Auth/Token).
- **Rastreamento de Background**: `geolocator` com filtro inteligente de distância de deslocamento (economia de bateria).
- **Sockets**: `stomp_dart_client`.
- **Armazenamento Seguro**: `flutter_secure_storage` (criptografia por hardware nativo para o token).
- **Mapas (Integração Futura UI)**: `google_maps_flutter`.

---

## 3. Modelo de Dados (PostgreSQL / PostGIS)

As migrações gerenciadas pelo Flyway (`V1__initial_schema.sql`) criam 10 tabelas fundamentais:

1. **`universities`**: Universidades base cadastradas.
2. **`users`**: Entidade principal de conta. Possui arrays de perfis `VARCHAR[]` mapeados para EnumSet via conversores (`PASSENGER`, `VAN_DRIVER`, `CARPOOL_DRIVER`).
3. **`vehicles`**: Veículos atrelados a um motorista (`VAN` ou `CAR`).
4. **`routes`**: Definições geográficas das rotas diárias/avulsas. Utiliza `geography(Point,4326)` para Origem/Destino.
5. **`offers`**: Vagas publicadas por motoristas associadas a uma `Route`.
6. **`demands`**: Demanda (pedido de carona) publicado por um passageiro (também usa tipos espaciais para origin/destination).
7. **`trip_instances`**: Uma viagem instanciada e física baseada em uma Offer (possui estado físico: `SCHEDULED`, `IN_PROGRESS`, `COMPLETED`).
8. **`trip_passengers`**: Tabela associativa com chaves únicas unindo a Trip e o Passenger. Gerencia o fluxo da chamada diária (Status: `CONFIRMED`, `CHECKED_IN`, `ABSENT`).
9. **`gps_pings`**: Tabela volátil, anexa ao `trip_instance_id`, armazenando os pings de rastreamento do GPS em tempo real.
10. **`notifications`**: Histórico de inbox (in-app notifications) despachados pelo Firebase FCM.

---

## 4. Endpoints e Rotas Base (API)

A API roda porta padrão `8080`. Todas as chamadas, com exceção do login/cadastro, requerem header `Authorization: Bearer <token>`.

### 4.1 Módulo Auth (`/api/v1/auth`)
- `POST /register`: Recebe `name`, `email`, `password`, `profileTypes[]`. Retorna JWT e UserDTO.
- `POST /login`: Retorna Payload JWT autenticado.

### 4.2 Módulo de Publicações Geoespaciais
- `GET /api/v1/offers/nearby`: Busca instâncias de carona/vans disponíveis com base em um ponto PostGIS central (`lat`/`lon`) e raio metrificado (`distanceMeters`).
- `GET /api/v1/demands/nearby`: Busca passageiros procurando vaga próximos à uma rota de motorista.

### 4.3 Módulo de Viagens & Check-in (`/api/v1/trips`)
- `POST /from-offer/{offerId}`: Converte uma publicação agendada em uma instância de Viagem Ativa.
- `POST /{tripId}/request-seat`: Passageiro manifestando interesse na viagem.
- `POST /{tripId}/checkin`: Motor central do sistema diário. Recebe boolean `isAttending` e altera o estado do passageiro para `CHECKED_IN` ou `ABSENT`.
- `GET /{tripId}/passengers`: Devolve o diário/lista de presença para a UI do Motorista.

### 4.4 Módulo de Rastreamento & Notificações
- **REST Notificações**: `GET /api/v1/notifications/unread` e `PUT /{id}/read`.
- **WebSocket (STOMP)**: Endpoint de Handshake `/ws-tracking`.
  - Inscrição via Cliente: Ouve o tópico privado `/topic/trips/{tripId}/tracking`.
  - Publicação via Motorista: Envia coordenadas para `/app/tracking/update`.

---

## 5. Estrutura de Diretórios (Repositório)

```text
r:\Dev\VaiJunto\
├── docker-compose.yml              # Container local (PostGIS/PostgreSQL 16)
│
├── backend/                        # Monolito Spring Boot 3 / Java 17
│   ├── pom.xml                     # Maven config (Flyway, Spatial, FCM, JWT, STOMP)
│   └── src/main/
│       ├── resources/
│       │   ├── application.yml                 # Props de BD, Dialect Postgis, JWT secrets
│       │   └── db/migration/V1__initial_schema.sql  # Database Schema & Triggers
│       │
│       └── java/com/vaijunto/
│           ├── config/             # Configurações de STOMP WS, Segurança JWT, FirebaseApp
│           ├── controller/         # Mapeamento REST (Auth, Offer, Demand, Trip, Tracking)
│           ├── domain/             
│           │   ├── entities/       # Modelos persistidos JPA (User, Route, GpsPing, etc)
│           │   ├── enums/          # Tipos fortes restritos
│           │   └── converters/     # AttributeConverters customizados (ex: String[] para List)
│           ├── dto/                # Classes imutáveis de transição Client <-> API
│           ├── repository/         # Interfaces Data JPA. Contém Queries ST_DWithin (PostGIS)
│           ├── security/           # Contexto Filter, Token Validation e UserDetails
│           └── service/            # Regras de Negócios e integrações transacionais
│
└── mobile/                         # Aplicativo Híbrido Flutter
    ├── pubspec.yaml                # Riverpod, Dio, Geolocator, Google Maps, Stomp Client
    └── lib/
        ├── main.dart               # Entrypoint (Riverpod Scope, Theme)
        ├── core/
        │   ├── models/             # Objetos genéricos (ex: LocationModel)
        │   ├── network/            # ApiClient com Dio e JWT Interceptor automático
        │   └── storage/            # SecureStorage Service
        │
        └── features/               # Arquitetura Feature-First
            ├── auth/               # Camadas data/presentation (Login/Cadastro)
            ├── demands/            # Consumo de DTOs Geoespaciais (Passageiro)
            ├── offers/             # Consumo de DTOs Geoespaciais (Motorista/Vans)
            ├── notifications/      # Firebase Messaging Integration
            ├── tracking/           # LocationTrackerService e StompClient WebSocket
            └── trips/              # Gestão do "Diário de Bordo" e Checkin
```

---

## 6. Decisões Críticas de Arquitetura

1. **Separação de Instâncias VS Ofertas**: 
   - *Motivo:* Um motorista possui uma *Offer* (ex: "Vou para a universidade 5x na semana"). No entanto, o sistema precisa monitorar quem efetivamente entrou no carro na *quarta-feira específica*. Por isso, converte-se a *Offer* numa *TripInstance* diária.
2. **LGPD e Privacidade Geoespacial**:
   - *Decisão:* Os sockets de rastreio de GPS *nunca* são globais. Eles foram segmentados rigidamente por `{tripId}`. A camada backend verifica o token JWT no ato do handhshake do Socket garantindo que dados de geolocalização não são públicos.
   - Os `gps_pings` são tabelas voláteis e podem ser apagadas periodicamente.
3. **Escala via PostGIS nativo**:
   - Evitou-se colocar um Redis ou Mongo prematuramente. O PostgreSQL 16 com extensão PostGIS resolve muito bem a busca por raio (`ST_DWithin`) mantendo a coerência e relacionamentos ACID na fase de MVP. 
4. **Baixo impacto de Bateria**:
   - O aplicativo monitora a localização nativa através de `distanceFilter`. O motorista não realiza flooding de pacote de 1 em 1 segundo quando parado no farol; só envia sinal via STOMP quando há deslocamento prático real.
