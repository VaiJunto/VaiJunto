# Subplano 02 — Cadastros reutilizáveis

Progresso do subplano: **100%**  
Estado: **Concluído**  
Depende de: **01 concluído**

## Instrução de contexto

Leia somente `00_INDICE.md`, este arquivo, `CLAUDE.md` e os arquivos de código
afetados. Confirme no índice que o subplano 01 está concluído; não abra o arquivo 01.

## Objetivo

Criar dados reutilizáveis que reduzem formulários futuros: endereços salvos,
veículos persistentes e a base da lista de conversas.

## Controle de progresso

| Item | Entrega | Progresso | Estado | Evidência |
|---|---|---:|---|---|
| US-END-02 | Endereços salvos e recentes | 100% | Concluído | Migração V6, `AddressController`/`AddressService`, tela em Ajustes; `mvn test -q` e análise Flutter passam |
| US-VEI-01 | Primeiro veículo | 100% | Concluído | Migração V6, API autorizada e tela de cadastro; compilação backend e análise Flutter passam |
| US-VEI-02 | Gestão de veículos | 100% | Concluído | Lista, padrão e arquivamento lógico; `mvn test -q` passa |
| US-CHA-01 | Estrutura e lista de conversas | 100% | Concluído | Migração V6, API e lista mobile; análise Flutter passa |

## US-END-02 — Endereços salvos e recentes

- Área nos ajustes; nomes rápidos `CASA`, `TRABALHO` e nomes personalizados.
- Atalhos em origem, destino e ponto de encontro; ícone de estrela salva rapidamente.
- Máximo de 10 endereços salvos e 5 locais recentes.
- Renomear, atualizar e excluir; exclusão mostra `DESFAZER` por poucos segundos.
- Recentes podem ser limpos em `AJUSTES > PRIVACIDADE` e expiram após 90 dias.
- Dados são privados. Uma carona publicada guarda snapshot e não muda se o favorito mudar.
- Testar isolamento entre contas e remoção/expiração.

## US-VEI-01 — Primeiro veículo

- Oferecer carona sem veículo redireciona ao cadastro e depois retoma o rascunho.
- Duas etapas curtas: placa/ano/marca/modelo/versão/cor; depois combustível,
  capacidade de passageiros sem motorista e consumo médio sugerido.
- Sugestões precisam de confirmação; ausência de catálogo permite preenchimento manual.
- Foto é opcional e não bloqueia o cadastro.
- Placa normalizada e única entre contas ativas; erro nunca revela o outro proprietário.

## US-VEI-02 — Gestão de veículos

- `AJUSTES > MEUS VEÍCULOS`; vários veículos e um padrão.
- Adicionar, editar, arquivar/excluir e trocar o padrão.
- Veículo em carona futura/em andamento não pode ser excluído; listar caronas bloqueadoras.
- Histórico preserva snapshot e fica visível ao admin.
- Depois de haver histórico, placa/marca/modelo/capacidade exigem análise administrativa.
- Cor, combustível e consumo são editáveis; caronas futuras são notificadas e o
  limite financeiro é recalculado sem aumentar automaticamente o valor pedido.
- Conflito/transferência de placa exige fluxo auditável para o admin.

## US-CHA-01 — Estrutura e lista de conversas

- Modelar conversa individual ligada a carona/proposta, conversa oficial do app e
  conversa administrativa como tipos distintos.
- Passageiros nunca entram em grupo entre si.
- Lista ordena não visualizadas primeiro e depois atividade recente.
- Arquivadas ficam separadas; estado vazio explica quando um chat nasce.
- Carona aceita abre chat motorista–passageiro; proposta reversa pode abrir chat pendente.
- Chat de carona permanece gravável até 24 horas depois do encerramento e então
  vira arquivo somente leitura.
- Nesta etapa, preparar contratos e lista; conteúdo completo fica no subplano 04.

## Critérios de saída

- CRUDs possuem autorização por proprietário, validação e testes.
- Snapshots impedem alteração retroativa de carona/histórico.
- Exclusão é lógica quando a auditoria exigir preservação.
- Lista de conversas diferencia corretamente os três tipos.
- Fluxos mobile seguem `mobile/DESIGN.md` e funcionam em tela pequena.
- Testes backend/Flutter passam e versão é incrementada conforme `CLAUDE.md`.

## Ao chegar a 100%

Quando todos os itens estiverem em `100%`, renomeie para
`02_CONCLUIDO_cadastros_reutilizaveis.md`, atualize `00_INDICE.md` e libere o
subplano 03. Não releia este arquivo nas etapas seguintes, salvo regressão direta.
