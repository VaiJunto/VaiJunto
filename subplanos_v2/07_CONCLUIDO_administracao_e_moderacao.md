# Subplano 07 — Administração e moderação

Progresso do subplano: **100%**  
Estado: **Concluído**  
Depende de: **01, 04, 05 e 06 concluídos**

## Instrução de contexto

Leia o índice, este arquivo e código afetado. A autenticação admin vem do plano 01;
use seu contrato no código. Não abra planos concluídos nem `PLANO_V2.md`.

## Objetivo

Entregar o painel desktop/PWA/APK para verificação, operação, auditoria,
moderação e contato administrativo sem violar a privacidade dos chats.

## Controle de progresso

| Item | Entrega | Progresso | Estado | Evidência |
|---|---|---:|---|---|
| US-ADM-03 | Selo de verificação | 100% | Concessão, pausa, recusa e remoção motivadas, auditadas e notificadas | `AdminOperationsService.verify`, V15, testes unitários |
| US-ADM-04 | Operação e moderação | 100% | Busca de pessoas/veículos/caronas, denúncias, mídia de evidência e figurinhas auditadas | `AdminManagementController`, V15 |
| US-ADM-05 | Conversa administrativa | 100% | Conversa isolada, identificada e permanente, sem acesso a chats privados | V16, `AdminOperationsService.contact` |
| ADMIN-QA | Auditoria, autorização e privacidade | 100% | Migrações, testes backend e testes/análise Flutter concluídos | `mvn test -q`; `flutter analyze`; `flutter test` |

## US-ADM-03 — Selo de verificação

- Concessão manual por desenvolvedor após conferir nome, foto, e-mail ativo e vínculo.
- Sem selo, pessoa usa o app e aparece `NÃO VERIFICADO`.
- `AJUSTES > COMO SER VERIFICADO` orienta falar com desenvolvedor.
- Guardar somente resultado, admin, data e observação; nunca cópia de documento.
- Futuro papel de professor/verificador deve ser permissão específica, não admin total.
- Conceder, recusar, pausar/remover exige motivo, auditoria e aviso no chat `VAIJUNTO`.
- Mudança de foto pausa selo até conferência; ação no selo não suspende conta sozinha.

## US-ADM-04 — Operar a comunidade

- Pesquisa global de pessoas, veículos e caronas.
- Perfil administrativo reúne histórico pertinente sem expor dados a admins sem permissão.
- Ver alterações de perfil/foto, veículo completo, vínculos, caronas e arquivamento.
- Resolver conflito/transferência de placa com justificativa e auditoria.
- Filas: verificações, denúncias, contestações, cancelamentos recorrentes,
  finalizações sem justificativa e avaliações privadas.
- Aplicar/remover `USUÁRIO ADVERTIDO`; tornar `EM OBSERVAÇÃO` público somente nas
  regras definidas, com início/fim e remoção antecipada justificada.
- Suspender conta/conteúdo é decisão separada, motivada e auditada.
- Administrar figurinhas: adicionar, ordenar, ativar e remover.
- Indicadores gerais não podem expor conversas privadas.
- Toda listagem possui paginação, filtros, estado vazio e trilha de auditoria.

## Privacidade das denúncias

- Admin vê somente mensagens explicitamente selecionadas pelo denunciante.
- Cópia é imutável mesmo se original for editado/apagado.
- Todo acesso à denúncia é auditado.
- Mídias vinculadas a denúncia não entram em limpeza automática. Somente um
  administrador autorizado pode excluí-las manualmente no painel, após
  confirmação explícita que informe a consequência para a evidência; a ação,
  motivo, administrador, arquivo e resultado são auditados. A exclusão mantém
  a referência histórica da denúncia como `MÍDIA REMOVIDA PELO ADMIN`, sem URL
  ou objeto órfão no R2.
- Estados: `ENVIADA`, `EM ANÁLISE`, `RESOLVIDA`; usuário recebe resumo sem medida
  privada tomada sobre terceiro.
- Admin não entra silenciosamente nem lê o restante de chat criptografado.

## US-ADM-05 — Conversa administrativa

- Admin pode iniciar conversa separada com qualquer pessoa sem vínculo de carona.
- Admin aparece com `VERIFICADO` e `ADMIN`; registrar autor/data de abertura.
- Não pode ser bloqueado; usuário pode silenciar/arquivar e não é obrigado a responder.
- Nova mensagem pode reexibir conversa.
- Ninguém apaga mensagens administrativas.
- Cada remetente edita a própria mensagem somente por 1 min; depois é permanente;
  mensagem alterada mostra `EDITADA`.
- Conversa admin nunca concede acesso ao chat privado da carona.

## Critérios de saída

- Matriz de permissões é aplicada no backend e testada por papel/ação.
- MFA, sessão, recuperação e auditoria resistem a acesso indevido.
- Nenhum endpoint administrativo vaza dados antes da autenticação.
- Painel desktop trata carregamento, falha, paginação e exportação segura quando houver.
- Denúncias provam por teste que somente seleção explícita é revelada.
- PWA e APK usam o mesmo backend, regras e experiência desktop-first.
- Testes backend/Flutter web/admin e versão conforme `CLAUDE.md` estão concluídos.

## Ao chegar a 100%

Renomeie para `07_CONCLUIDO_administracao_e_moderacao.md`, atualize o índice e
libere o subplano 08. Não reabra este arquivo depois, salvo regressão direta.

