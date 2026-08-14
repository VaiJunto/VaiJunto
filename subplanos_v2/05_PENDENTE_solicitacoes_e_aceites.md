# Subplano 05 — Solicitações, propostas e aceites

Progresso do subplano: **0%**  
Estado: **Aguardando subplanos 03 e 04**  
Depende de: **03 e 04 concluídos**

## Instrução de contexto

Leia apenas o índice, este arquivo e o código afetado. Não reabra os planos 03/04;
os contratos necessários estão resumidos abaixo.

## Objetivo

Fechar os dois sentidos de encontro: passageiro pede vaga em oferta e motorista
responde a pedido publicado, com concorrência segura e mensagens claras.

## Controle de progresso

| Item | Entrega | Progresso | Estado | Evidência |
|---|---|---:|---|---|
| US-SOL-01 | Passageiro solicita vaga | 0% | Aguardando oferta/chat | — |
| US-SOL-02 | Motorista aceita passageiro | 0% | Aguardando US-SOL-01 | — |
| US-SOL-03 | Motorista recusa solicitação | 0% | Aguardando US-SOL-01 | — |
| US-SOL-04 | Motorista propõe em pedido | 0% | Aguardando pedido/chat | — |
| US-SOL-05 | Passageiro cancela participação | 0% | Aguardando aceite | — |

## US-SOL-01 — Solicitar vaga

- Uma conta solicita exatamente 1 vaga para si; acompanhante precisa de conta própria.
- Pedido/proposta pendente não reserva vaga.
- Passageiro pode tentar várias caronas sobrepostas enquanto aguarda.
- Pedido fica `AGUARDANDO RESPOSTA` até decisão ou horário esperado de saída.
- Ao aceitar uma opção, encerrar automaticamente pedidos/propostas conflitantes.

## US-SOL-02 — Aceitar

- Somente motorista decide; transação atômica valida vaga e conflito de agenda.
- Pessoa não pode ter duas participações aceitas sobrepostas.
- Aceite reduz vaga; zero remove oferta pública e libera chat/dados pós-aceite.
- Ao lotar, encerrar pendentes com `AS VAGAS FORAM PREENCHIDAS`, sem registro negativo.
- Se vaga reabrir, oferta reaparece; pedidos antigos não retornam automaticamente.

## US-SOL-03 — Recusar

- Vale apenas para aquela carona; conteúdo some para o passageiro sem bloquear futuro.
- Mostrar `DESFAZER` por poucos segundos; depois a recusa é definitiva naquele pedido.

## US-SOL-04 — Proposta do motorista

- Em pedido publicado, motorista abre chat/proposta pendente antes do aceite.
- Antes do aceite: primeiro nome, foto, selo, horário, ajuda e vagas; sem veículo.
- Passageiro pode conversar com vários, mas aceitar apenas um.
- Aceitar encerra outras propostas com `O PASSAGEIRO CONFIRMOU OUTRA CARONA`.
- Recusar arquiva apenas aquela proposta; não bloqueia futuro.
- Motorista pode retirar proposta pendente sem ocorrência.
- Proposta expira no horário esperado e vira somente leitura.

## US-SOL-05 — Cancelar participação

- Passageiro pode cancelar pedido pendente ou vaga aceita; vaga aceita retorna.
- Antes de compromisso aceito, cancelamento não exige motivo.
- Depois do aceite, motivos: `MUDANÇA DE PLANOS`, `ENCONTREI OUTRA CARONA`,
  `NÃO POSSO ESPERAR`, `PEDIDO FEITO POR ENGANO`, `QUESTÃO DE SEGURANÇA`, `OUTRO`.
- `OUTRO` exige texto; outra parte vê só categoria, texto fica autor/admin.
- 3 cancelamentos em 30 dias ou 2 na última hora geram revisão manual, nunca punição automática.

## Critérios de saída

- Aceite concorrente nunca ultrapassa vagas nem cria dois compromissos conflitantes.
- Todas as transições são idempotentes, autorizadas e auditáveis.
- Notificações/chat refletem o estado persistido, não estado otimista falso.
- Testar última vaga, dois motoristas simultâneos, cancelamento e reabertura.
- Privacidade antes/depois do aceite possui testes de contrato.
- Testes backend/Flutter e versão conforme `CLAUDE.md` estão concluídos.

## Ao chegar a 100%

Renomeie para `05_CONCLUIDO_solicitacoes_e_aceites.md`, atualize o índice e
libere o subplano 06. Não releia este arquivo posteriormente sem regressão direta.

