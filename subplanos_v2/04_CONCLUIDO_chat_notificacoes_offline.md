# Subplano 04 — Chat, notificações e internet instável

Progresso do subplano: **100%**  
Estado: **Concluído**  
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
| US-CHA-02 | Chat e anexos da carona | 100% | Concluído | Chat motorista–passageiro, anexos R2 com autorização, limites/compressão, localização, áudio, figurinhas, denúncia imutável, retenção de 24 h e limpeza segura por capacidade. |
| US-CHA-03 | Chat oficial VAIJUNTO | 100% | Concluído | Canal `OFFICIAL` somente leitura, selo visual e ações permitidas, com retorno interno registrado. |
| US-NOT-01 | Central e notificações | 100% | Concluído | Centro persistente, preferências, tokens FCM, push com privacidade, eventos de pedido/check-in/ausência/mensagem e credencial validada no servidor. |
| US-OFF-01 | Operação com internet instável | 100% | Concluído | Cache privado sinalizado como desatualizado, fila idempotente persistente, reenvio/remoção explícitos e nenhum sucesso falso. |

## US-CHA-02 — Chat da carona

- Somente motorista–passageiro; nunca passageiro–passageiro e nunca chat livre.
- Envio exige participação aceita ou proposta pendente prevista no fluxo reverso.
- Barra: `+`, texto, câmera, figurinhas e botão contextual áudio/enviar.
- `+`: até 5 fotos/vídeos da galeria ou localização; câmera captura nova mídia.
- Foto: até 5 MB, comprimida para JPEG/WebP antes do upload.
- Vídeo máximo 20 s, até 15 MB, convertido para MP4/H.264 em no máximo 720p;
  contador e corte obrigatórios para arquivo maior.
- Áudio: até 2 min e 3 MB, codificado em AAC/Opus.
- O cliente comprime antes do envio; o servidor valida tipo, tamanho e duração e
  remove/rejeita uploads fora do limite, inclusive de clientes modificados.
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
- Mídias de conversa comuns são apagadas 24 h após o encerramento da carona;
  textos permanecem por tempo indeterminado por enquanto. Foto de perfil não
  expira. Mídias selecionadas em denúncia ficam preservadas como cópia imutável
  para a análise administrativa e não entram na limpeza automática.
- O bucket Cloudflare R2 tem limite operacional de 30 GB (10 GB de franquia e
  até 20 GB excedentes). Um processo automático mede o uso total e, ao alcançar
  esse limite, antecipa a exclusão de todas as mídias comuns já marcadas para
  limpeza; nunca remove fotos de perfil ou evidências de denúncias.
- Cada limpeza registra arquivo, tamanho, motivo, data e resultado. A exclusão
  é transacional: primeiro marca a mídia como removível no banco, remove do R2,
  confirma a remoção no banco e permite reconciliação segura em caso de falha;
  nenhuma referência de mensagem/denúncia fica quebrada.
- Após a limpeza por limite, uploads comuns permanecem bloqueados ou limitados
  enquanto o bucket estiver acima de 30 GB. O app explica o motivo sem mostrar
  sucesso falso e permite nova tentativa quando houver espaço.
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
- Testar limite de 30 GB, limpeza antecipada, exceções de foto de perfil e
  denúncia, bloqueio posterior e reconciliação banco/R2 após falha parcial.
- Denúncia nunca entrega contexto não selecionado.
- Chat permanece leve em histórico longo e conexão limitada.
- Testes backend/Flutter e versão conforme `CLAUDE.md` estão concluídos.

## Evidências de conclusão

- Backend: `mvn test -q` passou, incluindo autorização direta de mídia, limpeza por limite, idempotência de carona, notificações e WebSocket de digitação/localização.
- App: `flutter test` passou integralmente; `flutter analyze --no-pub` não encontrou erros de compilação (restam somente avisos informativos já existentes de lint).
- Integrações protegidas: no servidor, os testes opt-in de R2 realizaram `put/head/delete` de objeto temporário e a credencial Firebase inicializou o Firebase Admin sem expor segredos.
- Operação R2: limite de 30 GB, exceções permanentes para `PROFILE` e `REPORT`, log de motivo/tamanho/chave, retenção de 24 h para `CHAT` e resposta `507 STORAGE_LIMIT_REACHED` após limpeza insuficiente.

## Ao chegar a 100%

Renomeie para `04_CONCLUIDO_chat_notificacoes_offline.md`, atualize o índice e
libere o subplano 05. Não releia este arquivo depois, salvo regressão direta.

