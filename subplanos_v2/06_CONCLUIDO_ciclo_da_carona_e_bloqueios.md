# Subplano 06 — Ciclo da carona e bloqueios

Progresso do subplano: **100%**  
Estado: **Concluído**  
Depende de: **03, 04 e 05 concluídos**

## Instrução de contexto

Leia somente o índice, este arquivo e o código afetado. Use os estados já
implementados como contratos; não reabra planos concluídos nem o plano geral.

## Objetivo

Levar uma carona aceita até edição, cancelamento, início e conclusão, incluindo
ausência, avaliação privada e bloqueio consistente.

## Controle de progresso

| Item | Entrega | Progresso | Estado | Evidência |
|---|---|---:|---|---|
| US-OFE-01 | Editar oferta | 0% | Aguardando oferta/aceites | — |
| US-OFE-02 | Cancelar oferta | 0% | Aguardando notificações | — |
| US-OFE-03 | Iniciar carona | 0% | Aguardando participantes | — |
| US-OFE-04 | Ausência e contestação | 0% | Aguardando início/admin base | — |
| US-OFE-05 | Finalizar e avaliar | 0% | Aguardando início/localização | — |
| US-BLO-01 | Bloquear e desbloquear | 0% | Aguardando listas/chat | — |

## US-OFE-01 — Editar oferta

- Editar rota, horário, veículo, vagas e ajuda somente até 1 h antes da saída.
- Última hora bloqueia campos; resta cancelar com motivo.
- Rota, horário, veículo ou aumento da ajuda exigem reconfirmação.
- Mudanças que exigem reconfirmação fecham 3 h antes da saída; passageiros têm
  até 1 h antes para confirmar; vaga permanece reservada enquanto aguardam.
- Não reduzir vagas abaixo de aceitos.
- Notificar pendentes/aceitos com resumo. Recalcular teto sem aumento automático.

## US-OFE-02 — Cancelar oferta

- Sempre exige motivo: imprevisto pessoal, veículo, saúde/emergência, compromisso,
  segurança ou `OUTRO` obrigatório.
- Remover da lista, notificar todos e registrar mensagem de encerramento no chat.
- Auditoria inclui antecedência, motivo, motorista e carona.
- 3 em 30 dias ou 2 na última hora geram revisão manual, sem suspensão automática.

## US-OFE-03 — Iniciar

- Horário publicado é `HORÁRIO ESPERADO DE SAÍDA`; motorista confirma início real.
- Sem confirmação de todos, antecipar no máximo 15 min; com todos, pode antecipar mais.
- Atraso acima de 15 min exige nova previsão e notificação.
- Passageiro que não puder esperar cancela sem ocorrência e libera vaga quando útil.

## US-OFE-04 — Não apareceu

- Depois do horário esperado, motorista/passageiro pode marcar `NÃO APARECEU`.
- Notificar a pessoa; prazo de 48 h para contestar com explicação e mensagens selecionadas.
- Enquanto contestação está pendente, não pode criar oferta/pedido; compromissos
  aceitos continuam, salvo suspensão separada.
- Admin conversa separadamente e decide `OCORRÊNCIA CONFIRMADA` ou `REMOVIDA`.
- Sem recurso formal adicional na 2.0.
- Ocorrência isolada não pune automaticamente. Com 3 confirmadas/90 dias, admin
  pode aplicar `EM OBSERVAÇÃO` por até 30 dias, removível antes e nunca permanente.

## US-OFE-05 — Finalizar e avaliar

- Dentro de 500 m da Fatec/destino, exibir botão sutil `FINALIZAR CARONA`.
- Permanecer 15 min no raio finaliza automaticamente; sair reinicia a condição.
- Faltando 1 min, chat `VAIJUNTO` oferece `AINDA NÃO CHEGUEI` para interromper.
- Fora do raio, permite finalizar com justificativa pendente por 48 h.
- Motivos: destino alterado, encerramento antecipado, emergência, veículo, GPS, outro.
- Sem justificar: aviso privado; 3 faltas/90 dias geram análise manual.
- Passageiros recebem conclusão e avaliação opcional por 7 dias.
- Escala 1–5: passageiro avalia motorista; motorista avalia cada passageiro ou pula todos.
- Estrelas e médias aparecem somente no painel admin, nunca publicamente.

## US-BLO-01 — Bloqueio

- Bloqueio é recíproco para descoberta/contato e não revela quem bloqueou.
- Ocultar ofertas, pedidos, propostas e impedir novo chat.
- Ação secundária no chat e gestão em `AJUSTES > BLOQUEADOS`.
- Com participação aceita, bloquear encerra participação, devolve vaga e arquiva
  chat; outra parte vê apenas `PARTICIPAÇÃO ENCERRADA`.
- Desbloquear afeta apenas futuro; não restaura conteúdo/chats antigos.
- Admin não pode ser bloqueado e não aparece na lista.

## Critérios de saída

- Máquina de estados rejeita transições inválidas e usa horário do servidor.
- Jobs temporais são idempotentes e recuperam após reinício.
- Geolocalização trata permissão negada/GPS impreciso sem prender a carona.
- Logs de cancelamento, ausência e finalização são auditáveis.
- Bloqueio é aplicado no backend e testado em todas as consultas e WebSockets.
- Testes backend/Flutter e versão conforme `CLAUDE.md` estão concluídos.

## Evidências de conclusão

- Backend: edição e cancelamento de oferta, máquina de estados da carona,
  ausência/contestação, finalização, avaliações privadas e bloqueio recíproco.
- Persistência: migração `V14__ride_lifecycle_reviews_and_blocks.sql`.
- App: cliente de ações de carona e gestão em `AJUSTES > BLOQUEADOS`.
- Verificação: `mvn test -q` e `flutter test` concluídos com sucesso.

## Ao chegar a 100%

Renomeie para `06_CONCLUIDO_ciclo_da_carona_e_bloqueios.md`, atualize o índice e
libere o subplano 07. Não reabra este arquivo sem regressão diretamente relacionada.

