# Subplano 04 — Chat, notificações e internet instável

Progresso do subplano: **0%**  
Estado: **Aguardando subplanos 01–03**  
Depende de: **01, 02 e 03 concluídos**

## Instrução de contexto

Leia somente o índice, este arquivo, regras do projeto e código afetado. Os
contratos anteriores devem ser verificados no código, não nos planos concluídos.

## Objetivo

Entregar comunicação exclusivamente vinculada à carona, mensagens oficiais,
notificações coerentes e comportamento honesto sob conexão ruim.

## Controle de progresso

| Item | Entrega | Progresso | Estado | Evidência |
|---|---|---:|---|---|
| US-CHA-02 | Chat e anexos da carona | 0% | Aguardando 02–03 | — |
| US-CHA-03 | Chat oficial VAIJUNTO | 0% | Aguardando chat/eventos | — |
| US-NOT-01 | Central e notificações | 0% | Aguardando eventos | — |
| US-OFF-01 | Operação com internet instável | 0% | Aguardando listas/chat | — |

## US-CHA-02 — Chat da carona

- Somente motorista–passageiro; nunca passageiro–passageiro e nunca chat livre.
- Envio exige participação aceita ou proposta pendente prevista no fluxo reverso.
- Barra: `+`, texto, câmera, figurinhas e botão contextual áudio/enviar.
- `+`: até 5 fotos/vídeos da galeria ou localização; câmera captura nova mídia.
- Vídeo máximo 20 s, com contador e corte obrigatório para arquivo maior.
- Áudio máximo 2 min; segurar grava, arrastar cancela e deslizar para cima trava.
- Texto vazio mostra áudio; texto preenchido mostra enviar.
- Localização fixa ou ao vivo por 15/30/60 min, encerrável; abrir em Google Maps/Waze.
- Figurinhas são administradas; usuário não cria/importa. Sem chamadas ou encaminhamento.
- Arrastar mensagem responde com referência. `digitando...` é exibido.
- Editar/apagar própria mensagem por 1 min; mostrar `EDITADA` ou `MENSAGEM APAGADA`.
- Sem temporárias/visualização única. Leitura é obrigatória.
- Indicador único: círculo com ponteiro (saindo), vazio (serviço recebeu), com check
  (dispositivo recebeu), preenchido (visualizada). Não substituir por dois checks.
- Criptografia e autorização devem proteger texto e mídia.
- Denúncia seleciona várias mensagens; admin recebe só cópia imutável das escolhidas.
- Estados da denúncia: `ENVIADA`, `EM ANÁLISE`, `RESOLVIDA`.

## US-CHA-03 — Persona oficial

- Conversa `VAIJUNTO`, imagem própria e selo `OFICIAL`, distinta de admin humano.
- Canal informativo sem texto livre; respostas apenas por ações como `JUSTIFICAR`,
  `VER CARONA` e `AINDA NÃO CHEGUEI`.
- Novidades podem ser silenciadas; avisos operacionais/administrativos importantes não.
- Tom curto, acolhedor, direto e não punitivo antes de decisão.

## US-NOT-01 — Notificações

- Cobrir pedido/proposta, aceite/recusa, mensagem, edição/reconfirmação, cancelamento,
  atraso, início, encerramento, ausência/contestação e contato admin.
- Sempre registrar no centro interno; enviar externa quando o aparelho permitir.
- Prévia mostra remetente/conteúdo por padrão; usuário pode ocultar conteúdo.
- Configuração mais restritiva do aparelho prevalece.
- Silenciar chat comum não oculta eventos críticos da carona.
- Evitar duplicar visualmente o mesmo evento em cápsulas empilhadas.

## US-OFF-01 — Internet instável

- Offline mostra último conteúdo carregado com indicação discreta de desatualizado.
- Mensagem offline permanece local e sincroniza ao voltar conexão.
- Enquanto aguarda, mostrar somente círculo com ponteiro; nunca texto `ENVIANDO`.
- Falha definitiva permite tentar novamente ou apagar localmente.
- Publicar, aceitar, recusar, cancelar, editar e bloquear exigem confirmação online.
- Falha não produz sucesso falso; mostrar `TENTAR NOVAMENTE` e preservar contexto.

## Critérios de saída

- Testar autorização por conversa, inclusive tentativa de acesso direto a mídia.
- Testar ordem/idempotência, reconexão, duplicação e entrega WebSocket/push.
- Uploads são limitados, comprimidos e carregados gradualmente.
- Denúncia nunca entrega contexto não selecionado.
- Chat permanece leve em histórico longo e conexão limitada.
- Testes backend/Flutter e versão conforme `CLAUDE.md` estão concluídos.

## Ao chegar a 100%

Renomeie para `04_CONCLUIDO_chat_notificacoes_offline.md`, atualize o índice e
libere o subplano 05. Não releia este arquivo depois, salvo regressão direta.

