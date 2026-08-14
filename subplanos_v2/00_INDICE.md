# VaiJunto 2.0.0.0 — Índice operacional dos subplanos

Este diretório é a fonte de execução diária da versão 2.0.0.0. O plano geral
permanece como registro histórico e não deve ser aberto durante uma implementação
normal. Cada tarefa deve ler somente este índice e o próximo arquivo `PENDENTE`.

## Estado geral

Progresso dos subplanos: **38%**  
Próximo subplano executável: **04**  
Última atualização: **2026-08-14**

## Ordem por dependência

| Ordem | Subplano | Depende de | Progresso | Estado |
|---:|---|---|---:|---|
| 01 | `01_CONCLUIDO_fundacoes_e_seguranca.md` | Nenhum subplano | 100% | Concluído |
| 02 | `02_CONCLUIDO_cadastros_reutilizaveis.md` | 01 | 100% | Concluído |
| 03 | `03_CONCLUIDO_publicacao_e_descoberta.md` | 01, 02 | 100% | Concluído |
| 04 | `04_PENDENTE_chat_notificacoes_offline.md` | 01, 02, 03 | 0% | Aguardando 01–03 |
| 05 | `05_PENDENTE_solicitacoes_e_aceites.md` | 03, 04 | 0% | Aguardando 03–04 |
| 06 | `06_PENDENTE_ciclo_da_carona_e_bloqueios.md` | 03, 04, 05 | 0% | Aguardando 03–05 |
| 07 | `07_PENDENTE_administracao_e_moderacao.md` | 01, 04, 05, 06 | 0% | Aguardando 01, 04–06 |
| 08 | `08_PENDENTE_integracao_qualidade_e_entrega.md` | 01–07 | 0% | Aguardando 01–07 |

Fluxo principal: `01 → 02 → 03 → 04 → 05 → 06 → 07 → 08`.

## Protocolo para economizar contexto

1. Abra este índice.
2. Localize o primeiro arquivo cujo nome contenha `PENDENTE` e cujas dependências
   estejam concluídas.
3. Leia somente esse subplano, `CLAUDE.md` e os arquivos de código diretamente
   relacionados à etapa em execução.
4. Não abra arquivos `CONCLUIDO` durante o trabalho normal. O contrato necessário
   para a próxima etapa já está resumido no próprio subplano.
5. Não abra nem altere `PLANO_V2.md`, salvo se o subplano contiver uma contradição
   impossível de resolver. Nesse caso, marque o item como `Bloqueado` e explique a
   lacuna antes de ampliar o contexto.
6. Ao terminar uma sessão, atualize porcentagens, estado, evidências e próximo passo
   no subplano atual. Atualize neste índice somente a linha correspondente.

## Como interpretar pedidos futuros

- `Implemente o plano N`: execute somente o arquivo `NN_PENDENTE_...md` até o
  limite seguro da tarefa, atualizando progresso e evidências durante o trabalho.
- Não avance automaticamente para `N+1`; o usuário inicia cada subplano.
- Se uma dependência de `N` ainda estiver pendente, não pule a ordem nem improvise
  contratos: informe qual subplano precisa ser concluído primeiro.
- `Continue o plano N`: retome a partir do primeiro item abaixo de `100%`, sem
  reauditar itens já comprovados, salvo sinal de regressão.
- Se o arquivo já estiver `CONCLUIDO`, informe isso sem relê-lo por completo. Só o
  reabra quando o usuário pedir correção/regressão daquela entrega.

## Escala obrigatória de progresso

| Percentual | Significado verificável |
|---:|---|
| 0% | Não iniciado |
| 25% | Contratos, modelos ou estrutura criados |
| 50% | Fluxo principal funciona parcialmente |
| 75% | Fluxo completo; faltam testes, integração ou acabamento |
| 100% | Critérios atendidos, testes passando e evidências registradas |

O progresso do subplano é a média simples dos itens de sua tabela. Nunca arredonde
um item para `100%` se testes obrigatórios, migração, segurança ou UX ainda faltarem.

## Regra de renomeação

Quando todos os itens de um subplano estiverem em `100%`:

1. confirme os critérios de saída e os testes do arquivo;
2. troque `PENDENTE` por `CONCLUIDO` no nome, preservando número e restante do nome;
3. atualize a linha correspondente neste índice para `100%` e `Concluído`;
4. indique o próximo subplano liberado;
5. em tarefas futuras, não reabra o arquivo concluído, exceto para investigar uma
   regressão diretamente relacionada.

Exemplo: `01_PENDENTE_fundacoes_e_seguranca.md` passa a se chamar
`01_CONCLUIDO_fundacoes_e_seguranca.md`.

## Regras globais de execução

- Preserve alterações existentes do usuário e nunca faça limpeza destrutiva do repositório.
- Backend: Java 17, Spring Boot, PostgreSQL/PostGIS e migrações Flyway incrementais.
- Aplicativo: Flutter/Riverpod; antes de UI, leia `mobile/DESIGN.md` e reutilize os
  componentes visuais existentes.
- Qualquer alteração que exija novo build deve atualizar juntos
  `mobile/lib/core/app_version.dart` e `mobile/pubspec.yaml`, conforme `CLAUDE.md`.
- Não use `2.0.0.0` antes de o subplano 08 concluir todos os portões.
- Mantenha contratos de API explícitos, autorização no servidor, auditoria para
  operações sensíveis e transações para vagas/aceites concorrentes.
- Teste proporcionalmente ao risco. Como base, execute testes backend, análise e
  testes Flutter afetados; registre comandos e resultados como evidência.
- Uma implementação não está completa apenas por existir na interface: persistência,
  API, autorização, estados de erro, acessibilidade e testes também contam.

## Cobertura

Os subplanos 01–07 distribuem as **34 user stories** da versão. O subplano 08 cobre
os **5 portões de entrega**: jurídico, UX mobile, desempenho, QA e publicação.
