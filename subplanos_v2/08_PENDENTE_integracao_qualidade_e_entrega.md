# Subplano 08 — Integração, qualidade e entrega 2.0.0.0

Progresso do subplano: **0%**  
Estado: **Aguardando subplanos 01–07**  
Depende de: **todos os subplanos funcionais concluídos**

## Instrução de contexto

Leia `00_INDICE.md`, este arquivo, `CLAUDE.md`, os documentos operacionais e o
código/testes necessários. Não releia os sete planos concluídos; investigue o
código e as evidências registradas no índice.

## Objetivo

Integrar a jornada completa, corrigir regressões, validar privacidade/UX/desempenho
e somente então publicar a versão `2.0.0.0`.

## Controle de progresso

| Item | Entrega | Progresso | Estado | Evidência |
|---|---|---:|---|---|
| INT-01 | Auditoria final das 34 histórias | 0% | Aguardando 01–07 | — |
| PORTÃO-JURÍDICO | Jurídico e privacidade | 0% | Aguardando regras funcionais | — |
| PORTÃO-UX | UX mobile | 0% | Aguardando app completo | — |
| PORTÃO-PERF | Aparelhos modestos | 0% | Aguardando app completo | — |
| PORTÃO-QA | Jornada e regressão | 0% | Aguardando demais portões | — |
| PORTÃO-ENTREGA | Versão 2.0.0.0 | 0% | Aguardando todos os itens | — |

## INT-01 — Auditoria final

- Confirmar no índice que 01–07 estão `CONCLUIDO` e em 100%.
- Cruzar as 34 histórias com código, migrações, endpoints, telas e testes.
- Resolver TODOs, flags temporárias, mocks indevidos e estados sem tratamento.
- Validar atualização de base existente e instalação limpa sem perda de dados.
- Revisar concorrência de vagas, idempotência de jobs, autorização e auditoria.

## PORTÃO-JURÍDICO

- Revisar texto e modelo da ajuda financeira como teto de rateio, nunca tarifa/lucro.
- Revisar política de privacidade, retenção, anonimização, geolocalização, mídia,
  mensagens criptografadas, denúncia e acesso administrativo.
- Garantir termos claros para aviso, observação, suspensão e contestação.
- Registrar aprovação e pendências resolvidas; sem aprovação, não publicar.

## PORTÃO-UX

- Testar jornadas em telas pequenas: cadastro, endereço, veículo, oferta/pedido,
  solicitação, aceite, chat, iniciar/finalizar, bloqueio e ajustes.
- Uma ação principal por etapa; teclado/mapa não escondem confirmação.
- Elementos tocáveis confortáveis, textos curtos e estados não dependem só de cor.
- Painel admin é excluído do requisito mobile e validado em desktop.

## PORTÃO-PERF

- Validar início, navegação, listas, mapa, chat e mídia em ao menos um aparelho modesto.
- Testar conexão lenta/intermitente, cache, reconexão e fila de mensagem.
- Listas/históricos paginados; imagens em miniatura; vídeos/áudios comprimidos.
- Animações simples; sem travamentos, consumo desnecessário ou downloads massivos.
- PWA continua funcional dentro das limitações declaradas do navegador.

## PORTÃO-QA

- Backend: suíte completa, segurança, migrações e testes de concorrência.
- Flutter: análise estática, testes unitários/widget e jornadas manuais em device/web.
- Testar notificações, WebSocket, background/foreground, permissões e falhas externas.
- Testar matriz antes/depois do aceite e usuário/admin/bloqueado/suspenso.
- Corrigir regressões e atualizar documentação operacional.

## PORTÃO-ENTREGA

- Somente após todos os itens em 100%, definir simultaneamente:
  - `mobile/lib/core/app_version.dart`: `2.0.0.0`;
  - `mobile/pubspec.yaml`: `2.0.0+0`.
- Gerar e validar PWA, APK comum e APK administrativo previstos.
- Confirmar ambiente de produção, migrações, observabilidade e plano de retorno.
- Não executar commit ou push; o usuário controla Git conforme `CLAUDE.md`.

## Critérios de saída

- Todos os itens desta tabela estão em 100% com evidências.
- As 34 histórias e 5 portões estão concluídos.
- Nenhum requisito crítico depende de dado fictício ou acesso administrativo indevido.
- Build final mostra `2.0.0.0` e foi validado nos destinos previstos.
- Documentação corresponde ao comportamento entregue.

## Ao chegar a 100%

Renomeie para `08_CONCLUIDO_integracao_qualidade_e_entrega.md`, atualize
`00_INDICE.md` para progresso geral `100%` e marque `Próximo subplano executável`
como `NENHUM — VERSÃO 2.0.0.0 CONCLUÍDA`. Arquivos concluídos permanecem apenas
como histórico e não precisam ser reabertos em tarefas normais.

