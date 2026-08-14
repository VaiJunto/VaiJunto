# Subplano 03 — Publicação e descoberta

Progresso do subplano: **100%**  
Estado: **Concluído**  
Depende de: **01 e 02 concluídos**

## Instrução de contexto

Leia `00_INDICE.md`, este arquivo, `CLAUDE.md`, `mobile/DESIGN.md` para UI e o
código afetado. Não abra os subplanos concluídos nem `PLANO_V2.md`.

## Objetivo

Entregar o núcleo público: selecionar veículo, limitar a ajuda, publicar ofertas
e pedidos, descobrir opções e acompanhar tudo em `MINHAS CARONAS`.

## Controle de progresso

| Item | Entrega | Progresso | Estado | Evidência |
|---|---|---:|---|---|
| US-VEI-03 | Seleção de veículo na oferta | 100% | Concluído | Seletor mobile e validação servidor de propriedade/capacidade. |
| US-AJU-01 | Limite simples da ajuda | 100% | Concluído | Teto conservador no servidor, com distância geográfica como fallback. |
| US-AJU-02 | Ajuda opcional | 100% | Concluído | Zero aceito; valor acima do teto é limitado no servidor. |
| US-OFE-00 | Publicar oferta | 100% | Concluído | Fatec obrigatória, horário futuro e bloqueio de sobreposição. |
| US-DEM-01 | Publicar pedido | 100% | Concluído | Fatec obrigatória, edição/cancelamento pelo dono antes do aceite. |
| US-LIS-01 | Lista e filtros | 100% | Concluído | Feed com filtros de direção/data/horário/bairro, privacidade e API paginada. |
| US-MIN-01 | Minhas caronas | 100% | Concluído | Próximas/histórico e repetição com rota, horário, veículo, vagas e ajuda em rascunho. |
| US-NAV-01 | Navegação mobile | 100% | Concluído | Navegação com criação central e indicadores com limite 9+. |

## Veículo e ajuda financeira

### US-VEI-03

- Veículo padrão inicia selecionado em cartão compacto `modelo • cor • capacidade`.
- `TROCAR` abre seletor; placa não aparece nessa etapa.
- Vagas nunca excedem capacidade confirmada.

### US-AJU-01 e US-AJU-02

- Teto conservador, não tarifa: `(distância × 1,10 ÷ consumo médio) × preço regional`.
- Dividir por motorista + total de vagas oferecidas; aceita/cancela passageiro não eleva teto.
- Pedágio, estacionamento e custos especiais ficam fora.
- Campo começa vazio. Motorista escolhe zero ou qualquer valor até o teto.
- Valor acima do teto é reduzido ao sair do campo/continuar, com explicação curta.
- Mudança de vagas recalcula teto sem aumentar automaticamente a ajuda escolhida.
- Manter cálculo simples, auditável e sujeito ao portão jurídico do subplano 08.

## Publicação

### US-OFE-00

- Direção `INDO PARA A FATEC` ou `SAINDO DA FATEC`; Fatec é uma ponta obrigatória.
- Exigir outro ponto, data, horário esperado, veículo, vagas e ajuda opcional.
- Revisão final mostra região aproximada, data/hora, veículo, vagas e ajuda.
- Impedir duas ofertas do mesmo motorista com horários estimados sobrepostos.
- Não há recorrência automática; reutilização ocorre por `OFERECER NOVAMENTE`.

### US-DEM-01

- Passageiro informa direção, outro ponto, data e faixa de horário possível.
- Publicação exibe apenas região aproximada.
- Antes de aceitar proposta, pode editar livremente ou cancelar sem motivo/ocorrência.
- Alteração envia resumo aos chats de motoristas com proposta pendente.
- Depois do aceite, desistência usa cancelamento com justificativa.
- Não há recorrência automática.

## Descoberta, área pessoal e navegação

### US-LIS-01

- Abas `CARONAS OFERECIDAS` (padrão) e `PEDIDOS DE CARONA`.
- Filtros: direção, data, faixa de horário e bairro; chips removíveis e `LIMPAR FILTROS`.
- Ordenar por horário mais próximo e depois proximidade do ponto da pessoa.
- Proximidade usa localização atual; fallback para endereço escolhido e último pesquisado.
- Estados vazios oferecem `OFERECER CARONA` ou `PUBLICAR PEDIDO`.
- Cartões nunca revelam endereço exato ou veículo protegido antes do aceite.

### US-MIN-01

- Abas `PRÓXIMAS` e `HISTÓRICO`; cartões `VOCÊ DIRIGE`/`VOCÊ VAI`.
- Próximas em ordem crescente; histórico mais recente primeiro e paginado.
- Filtros por papel/estado.
- `OFERECER NOVAMENTE` copia rota, horário e veículo para rascunho; data, vagas e
  ajuda exigem confirmação. Nunca copiar pessoas, chats ou ocorrências.

### US-NAV-01

- Barra inferior: `INÍCIO`, `MINHAS CARONAS`, `CHATS`, `AJUSTES` e `+` central.
- `+` abre `OFERECER CARONA` e `PEDIR CARONA`.
- Indicadores em caronas/chats mostram contagem até `9+`, não dependem só de cor
  e não animam continuamente.
- Evento em primeiro plano pode usar uma única cápsula compacta, uma linha, poucos
  segundos, sem empilhar e sem aparecer na tela já relacionada.
- Vibração/animação respeitam configurações do aparelho.

## Critérios de saída

- Concorrência e autorização são validadas no servidor.
- Consultas são paginadas e possuem índices adequados.
- Privacidade do endereço é testada antes/depois do aceite.
- Formulários preservam rascunho ao cadastrar veículo ou voltar etapa.
- Fluxos funcionam em tela pequena e com teclado aberto.
- Testes backend/Flutter e versão conforme `CLAUDE.md` estão concluídos.

## Ao chegar a 100%

Renomeie para `03_CONCLUIDO_publicacao_e_descoberta.md`, atualize o índice e
libere o subplano 04. Não reabra este arquivo em tarefas futuras sem regressão direta.

## Evidências

- `mvn test -q` — passou.
- `flutter test --no-pub test/api_datetime_test.dart test/geocoding_result_model_test.dart` — 3 testes passaram.
- Análise Dart dos arquivos alterados — sem erros.
