# Subplano 01 — Fundações e segurança

Progresso do subplano: **100%**  
Estado: **Concluído**  
Depende de: **nenhum outro subplano**

## Instrução de contexto

Não leia `PLANO_V2.md`. Este arquivo é suficiente para esta onda. Leia `CLAUDE.md`,
`REQUIREMENTS.md` somente nas seções necessárias ao ambiente e `mobile/DESIGN.md`
antes de alterar telas.

## Objetivo

Auditar a base existente e estabelecer os contratos seguros que os demais planos
usarão: perfil, busca regional de endereço e acesso administrativo separado.

## Controle de progresso

| Item | Entrega | Progresso | Estado | Evidência |
|---|---|---:|---|---|
| BASE-01 | Auditoria inicial e mapa do código existente | 100% | Concluído | entidades/rotas Flutter e migrações mapeadas; V4 é somente aditiva |
| US-PER-01 | Perfil do fatecano | 100% | Concluído | contrato público/privado, foto, curso, nome sob aprovação e exclusão com retenção de 7 dias |
| US-END-01 | Busca regional de endereço | 100% | Concluído | ranking Vale/Fatec, rótulos, coordenadas, expansão explícita e pino ajustável |
| US-ADM-01 | Entrada administrativa desktop | 100% | Concluído | entrada responsiva desktop com retorno explícito ao app comum |
| US-ADM-02 | Autenticação administrativa separada | 100% | Concluído | store separado, convite, recuperação com TOTP, token/roles distintos e auditoria |

## BASE-01 — Auditoria inicial

- Mapear entidades, endpoints, providers, telas, testes e migrações já existentes.
- Atualizar esta tabela com o percentual real antes de reimplementar algo pronto.
- Definir contratos estáveis para usuário, endereço, coordenadas, auditoria e papéis.
- Criar somente novas migrações Flyway; nunca reescrever migrações já aplicadas.
- Documentar compatibilidade e preservação dos dados do MVP.

## US-PER-01 — Perfil do fatecano

- Cadastro: nome completo, foto, curso e e-mail institucional.
- Outros usuários veem apenas primeiro nome, foto, curso e selos permitidos.
- Nome completo e e-mail ficam privados; administradores autorizados podem consultar.
- E-mail institucional não pode ser alterado.
- Alteração de nome exige análise administrativa.
- Curso pode ser alterado livremente.
- Trocar foto de conta verificada pausa o selo até nova conferência.
- `AJUSTES > CONTA` oferece exclusão; caronas, propostas, contestações e pendências
  administrativas devem ser resolvidas antes.
- Exclusão possui recuperação por 7 dias e depois anonimiza/retém somente o exigido.

## US-END-01 — Busca regional de endereço

- Priorizar Vale do Paraíba e Fatec São José dos Campos; uma rua local deve vir
  antes de homônimos distantes.
- Tolerar acentos, abreviações e pequenas diferenças de digitação.
- Mostrar rua/número, bairro, cidade/UF e distância aproximada até a Fatec.
- `BUSCAR FORA DA REGIÃO` amplia explicitamente a busca para o Brasil.
- Guardar rótulo e coordenadas do resultado escolhido.
- Número, complemento e referência são opcionais.
- `USAR MINHA LOCALIZAÇÃO` abre mapa com pino ajustável; busca manual funciona sem permissão.
- Antes do aceite, consumidores futuros devem receber somente bairro/região aproximada.

## US-ADM-01 — Entrada administrativa desktop

- No celular, `vaijunto.app.br` abre o aplicativo comum.
- No computador, abre a entrada administrativa com a mensagem
  `Opa, parece que você descobriu o segredo.`.
- Ações: `ACESSAR PAINEL` e, discretamente, `ABRIR O VAIJUNTO NORMAL`.
- Detecção de tela muda apenas apresentação, nunca autorização.
- Painel é desktop-first; telas estreitas podem recomendar uma tela maior.

## US-ADM-02 — Autenticação administrativa

- Login, credenciais e permissões administrativos são separados das contas comuns.
- Primeira conta é criada pelos desenvolvedores; convites posteriores exigem admin superior.
- Convite expira; recuperação usa e-mail administrativo e confirmação adicional.
- Autenticação em duas etapas é obrigatória.
- Criação, recuperação e mudança de permissão geram auditoria.
- Entrega preparada para o mesmo painel Flutter em PWA e APK, sem duplicar regras.
- Conhecer a URL ou simular desktop nunca concede acesso.

## Critérios de saída

- Contratos estão testados e documentados nos próprios módulos.
- Busca regional não prioriza resultados distantes quando há correspondência local.
- Dados privados não vazam em DTOs públicos.
- Rotas administrativas recusam usuários comuns no backend.
- Migrações sobem em base limpa e em base com os dados atuais.
- Testes backend e Flutter afetados passam.
- Versões do aplicativo foram atualizadas juntas quando aplicável.

## Ao chegar a 100%

Quando todos os itens estiverem em `100%`, renomeie este arquivo para
`01_CONCLUIDO_fundacoes_e_seguranca.md`, atualize `00_INDICE.md` e libere o
subplano 02. Depois disso, não releia este arquivo em tarefas normais.
