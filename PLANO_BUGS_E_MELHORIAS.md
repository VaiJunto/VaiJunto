# Plano de correções e melhorias

## Objetivo

Corrigir os bugs levantados e melhorar os fluxos de publicação, mensagens,
notificações e atualização de dados sem redesenhar o aplicativo inteiro.

## Fora do escopo

- Novo design geral do aplicativo.
- Troca da identidade visual ou reconstrução de todas as telas.
- Mudança de tecnologia apenas por preferência; a infraestrutura existente deve
  ser reaproveitada quando for segura e suficiente.

## Diagnóstico do estado atual

- O backend e o app já possuem WebSocket com STOMP, mas no chat ele transmite
  apenas o estado de digitação e a localização ao vivo. Mensagens novas ainda
  dependem de recarregar o histórico por REST.
- As listas de caronas, pedidos, conversas e notificações usam `FutureProvider`
  e, em geral, só atualizam após uma ação local ou toque manual em atualizar.
- A central de notificações só navega para newsletters. O backend já inclui IDs
  de conversa, viagem ou pedido em vários eventos, mas não existe um roteador
  único para interpretar esses destinos.
- O backend já expõe `DELETE /api/v1/demands/{id}` e faz cancelamento lógico do
  pedido, porém o app não possui método no repositório nem ação na tela.
- A tela de oferta apenas informa que é necessário cadastrar um veículo; ela
  não abre o cadastro e não retoma o fluxo automaticamente.
- O sucesso usa hoje o padrão lima com texto escuro. Não atende ao pedido de
  confirmação verde com texto branco.
- A mídia usa URLs assinadas do R2 com validade de dois minutos. O provider do
  app pode manter uma URL expirada em cache. Além disso, o `S3Client` força URL
  em formato de caminho, mas o `S3Presigner` não configura explicitamente o
  mesmo formato. No Flutter Web, upload e download direto também dependem do
  CORS do bucket, que não está documentado no deploy.
- A API de criação de oferta não possui restrição de papel específica: qualquer
  usuário autenticado deveria poder acessá-la. Portanto, o “Acesso negado” deve
  ser reproduzido e rastreado antes de alterar autorização.
- O controle “Carona fixa” muda data para somente horário e mantém a oferta
  recorrente visível, mas não coleta dias da semana nem explica claramente o
  comportamento. Se o horário escolhido já passou no dia, a publicação também
  pode falhar na validação de horário futuro.

## Estratégia de entrega

Implementar em cinco etapas. Cada etapa deve chegar ao ambiente de homologação
separadamente, com telemetria suficiente para identificar regressões.

### Etapa 1 — Desbloquear publicação e mídia (prioridade P0)

#### 1.1 Corrigir “Acesso negado” ao oferecer carona

Implementação:

1. Reproduzir com um usuário comum autenticado e registrar método, URL, status,
   corpo da resposta e `code`, sem registrar o token.
2. Adicionar um teste de integração para `POST /api/v1/offers` com JWT de usuário
   comum e veículo pertencente ao usuário.
3. Conferir se o ambiente publicado executa a mesma versão de `SecurityConfig`
   do repositório e se o preflight CORS aceita `POST` e `Authorization`.
4. Diferenciar no app os casos `401` (sessão inválida), `403` (autorização),
   `400` (regra de negócio) e falha de rede. Mostrar a mensagem e o código
   retornados pelo backend e incluir um identificador de correlação nos logs.
5. Corrigir apenas a causa confirmada: configuração de deploy/CORS, token ou
   regra de autorização. Não liberar o endpoint anonimamente.

Critérios de aceite:

- Usuário autenticado com veículo ativo publica uma oferta e recebe `201`.
- Usuário sem veículo recebe orientação de cadastro, não “Acesso negado”.
- Token ausente ou inválido continua bloqueado.
- O teste cobre usuário comum, token inválido e veículo de outro usuário.

#### 1.2 Corrigir imagens e anexos do bucket R2

Implementação:

1. Inventariar os casos com falha: imagem de chat, avatar, veículo, newsletter e
   evidência administrativa, em Android e PWA.
2. Padronizar `S3Client` e `S3Presigner` para o mesmo modo de endereçamento do
   bucket e validar host, caminho, assinatura e `Content-Type` gerados.
3. Alterar a resposta de download para retornar `url` e `expiresAt`. Aumentar a
   validade para um período compatível com visualização de imagem, áudio e vídeo
   e renovar a URL quando estiver perto de expirar ou quando o R2 responder
   `401/403`.
4. Tornar o provider de URL descartável por tela/anexo, evitando reutilizar URL
   assinada vencida. Exibir carregamento, retry e placeholder de erro.
5. Configurar e documentar o CORS do R2 para a origem do PWA, incluindo `GET`,
   `HEAD`, `PUT` e os headers usados no upload. Android deve continuar coberto.
6. No upload, validar o status do `PUT`, tratar expiração da intenção e só chamar
   `/complete` depois de o objeto estar disponível no R2.

Critérios de aceite:

- Imagens recém-enviadas aparecem sem reabrir a conversa.
- Uma conversa aberta por mais tempo que a validade inicial continua carregando
  os anexos por renovação automática.
- Upload e leitura funcionam em Android e PWA.
- Pessoa fora da conversa continua sem acesso ao anexo.
- Há teste unitário do formato da URL e teste de integração `put/head/get/delete`
  com R2, executado por flag no ambiente seguro.

### Etapa 2 — Completar os fluxos principais (prioridade P0/P1)

#### 2.1 Cadastrar veículo dentro de “Oferecer carona”

Implementação:

1. Extrair o formulário usado em “Meus veículos” para um componente reutilizável.
2. Quando não houver veículo ativo, substituir o dropdown vazio por um estado
   explicativo com o botão `CADASTRAR VEÍCULO`.
3. Abrir o formulário como nova rota ou bottom sheet, preservando rota, horário,
   vagas, preço e tipo da oferta já preenchidos.
4. Após salvar, invalidar `vehiclesProvider`, selecionar o novo veículo e voltar
   ao segundo passo da oferta.
5. Se o cadastro for cancelado, manter a oferta preenchida e impedir somente a
   publicação.

Critérios de aceite:

- Uma pessoa sem veículo conclui cadastro e oferta sem voltar à tela inicial.
- Os dados já informados não são perdidos.
- Veículo novo fica selecionado e a capacidade limita corretamente as vagas.
- Falha no cadastro não duplica veículos nem apaga o rascunho da oferta.

#### 2.2 Remover pedido de carona

Implementação:

1. Adicionar `cancelDemand(id)` ao repositório mobile e um notifier de ação.
2. Manter o `DemandModel` na entrada de “Minhas caronas” para disponibilizar ID
   e status, em vez de reduzir tudo a campos visuais genéricos.
3. Mostrar `REMOVER PEDIDO` apenas para pedido próprio com status `OPEN`.
4. Pedir confirmação explicando que motoristas deixarão de ver o pedido.
5. Após `204`, invalidar `myDemandsProvider` e `nearbyDemandsProvider`, remover o
   item imediatamente da lista e mostrar confirmação.
6. Preservar no histórico pedidos cancelados com status claro, sem oferecer ação
   de remoção novamente.

Critérios de aceite:

- Pedido aberto desaparece do feed público logo após o cancelamento.
- Outra pessoa não consegue cancelar o pedido.
- Pedido já aceito direciona para o fluxo próprio de cancelamento da carona.
- Toques repetidos são idempotentes na interface.

### Etapa 3 — Atualização automática e mensagens (prioridade P1)

#### Decisão arquitetural

Usar WebSocket/STOMP como canal primário para eventos enquanto o app estiver em
primeiro plano. Usar REST para carga inicial e reconciliação. Usar polling leve
somente como fallback quando o socket estiver desconectado. Jobs no backend
continuam apropriados para tarefas agendadas, como expiração e limpeza, mas não
substituem um canal de entrega para atualizar a tela.

#### 3.1 Evoluir o canal em tempo real

Implementação:

1. Criar um envelope versionado, por exemplo:
   `eventId`, `type`, `occurredAt`, `resourceType`, `resourceId` e `payload`.
2. Publicar evento após commit para mensagem criada/editada/apagada, notificação
   criada e mudanças relevantes em oferta, pedido e participação.
3. Entregar eventos privados em `/user/queue/events`; evitar tópicos públicos
   com IDs previsíveis para dados pessoais.
4. Trocar callbacks únicos do `StompClientService` por streams broadcast ou um
   barramento tipado, para uma tela não sobrescrever o listener de outra.
5. Implementar reconexão com backoff, reautenticação, deduplicação por `eventId`
   e reconciliação REST ao reconectar.
6. Ao receber eventos, atualizar ou invalidar somente os providers afetados.

#### 3.2 Fallback e ciclo de vida

- Atualizar imediatamente ao abrir ou retomar o app.
- Enquanto o socket estiver indisponível e o app estiver em primeiro plano:
  consultar chat ativo em intervalo curto e listas/notificações em intervalo
  maior, com jitter e pausa em segundo plano.
- Cancelar timers no `dispose` e impedir requisições simultâneas.
- Manter pull-to-refresh ou botão manual como recuperação explícita.

Critérios de aceite:

- Mensagem recebida aparece no chat aberto sem ação manual.
- Contadores, conversas, caronas e notificações mudam em poucos segundos.
- Reconexão não duplica mensagem nem perde evento confirmado.
- App em segundo plano não mantém polling agressivo.
- Se WebSocket falhar, os dados ainda convergem pelo fallback REST.

### Etapa 4 — Notificações acionáveis (prioridade P1)

Implementação:

1. Padronizar o payload do backend com `targetType` e os IDs necessários:
   `conversationId`, `tripId`, `offerId`, `demandId` ou `newsletterId`.
2. Incluir esse payload também nos dados enviados pelo FCM; hoje o push envia
   somente título, corpo e tipo.
3. Criar um `NotificationDestinationResolver` no app para mapear tipo + payload
   para uma rota conhecida.
4. Suportar toque na central, `onMessageOpenedApp` e `getInitialMessage`, inclusive
   quando o app for aberto a partir de estado encerrado.
5. Para recursos removidos ou sem acesso, mostrar uma explicação e levar ao nível
   anterior adequado, sem deixar tela vazia.
6. Marcar como lida somente após reconhecer o toque; falha de navegação não deve
   bloquear a central.

Mapa inicial:

| Evento | Destino |
| --- | --- |
| `CHAT_MESSAGE`, `ADMIN_MESSAGE` | Conversa pelo `conversationId` |
| Eventos de pedido/aceite/reconfirmação/cancelamento | Detalhe da viagem pelo `tripId` |
| Eventos de pedido de carona | Pedido pelo `demandId` ou “Minhas caronas” |
| `ADMIN_NEWSLETTER` | Newsletter pelo `newsletterId` |
| Moderação/conta sem tela específica | Ajustes ou conversa administrativa |

Critérios de aceite:

- Todo alerta com destino válido abre diretamente o conteúdo relacionado.
- O comportamento é igual na central e no toque do push.
- Payload inválido não causa crash e gera log diagnóstico.
- Recursos inacessíveis exibem mensagem compreensível.

### Etapa 5 — Ajustes pontuais de interface (prioridade P2)

#### 5.1 Confirmação de pedido publicado

- Alterar o estilo semântico de sucesso para verde sólido, texto e ícone brancos,
  mantendo contraste acessível.
- Reutilizar o mesmo estilo em confirmações de publicação e remoção para evitar
  uma exceção visual específica de tela.
- Critério: `Pedido publicado!` aparece com fundo verde e conteúdo branco em
  temas e tamanhos de tela suportados.

#### 5.2 Valor por pessoa com `R$`

- Adicionar `prefixText: 'R$ '` no campo e manter no estado somente o número.
- Aceitar vírgula ou ponto na digitação, limitar a duas casas e formatar para o
  padrão brasileiro ao perder foco.
- Manter o backend com valor decimal, sem enviar a string `R$`.
- Exibir `R$ 0,00` de forma consistente nos cards, resumo e detalhes.

#### 5.3 Reformular “Carona fixa” sem redesenhar a tela

Decisão de produto recomendada: substituir o switch isolado por uma escolha
explícita entre `CARONA ÚNICA` e `CARONA RECORRENTE`. Ao escolher recorrente,
expandir os campos de dias da semana, data de início e horário. O padrão deve ser
carona única.

Antes de implementar, registrar uma decisão curta sobre:

- se “fixa” significa recorrência semanal ou transporte permanentemente aberto;
- quando a oferta deixa de aparecer;
- como editar, pausar e encerrar a recorrência;
- como filtros de data tratam uma série recorrente.

Se significar recorrência semanal, implementar dias da semana e próxima
ocorrência no backend, evitando manter eternamente uma única oferta com data
antiga. Se significar van/fretado sempre disponível, renomear para
`TRANSPORTE FIXO` e definir validade/renovação explícita.

Critérios de aceite:

- A pessoa entende a diferença antes de publicar.
- Não é possível publicar recorrência sem agenda válida.
- Horário passado no dia não gera uma oferta inválida.
- Feed e filtros exibem a próxima ocorrência correta.

## Ordem sugerida de pull requests

1. `fix: corrige acesso ao oferecer carona`
2. `fix: corrige imagens do armazenamento`
3. `feat: cadastra veiculo ao oferecer carona`
4. `feat: permite remover pedido de carona`
5. `feat: atualiza mensagens em tempo real`
6. `feat: atualiza listas automaticamente`
7. `feat: abre destino das notificacoes`
8. `fix: ajusta confirmacao e valor da carona`
9. `feat: melhora escolha de carona recorrente`

## Verificação transversal

- Backend: testes unitários e de integração de autorização, payloads, mídia e
  idempotência; executar a suíte Maven.
- Mobile: testes de provider/repositório e widgets dos estados vazio, sucesso,
  erro, remoção e navegação; executar análise e testes Flutter.
- Manual: matriz Android/PWA, rede normal/lenta/offline, app em primeiro plano,
  segundo plano e retomada.
- Observabilidade: logs estruturados sem token ou dados sensíveis, com ID de
  correlação para oferta, mídia e conexão STOMP.
- Homologação: validar cada etapa com dois usuários reais de teste, um como
  motorista e outro como passageiro.

## Definição de concluído

Um item só é concluído quando possui código, tratamento de erro, teste
automatizado proporcional ao risco, validação em Android e PWA quando aplicável,
e critério de aceite verificado em homologação. O novo design geral permanece
fora deste plano.
