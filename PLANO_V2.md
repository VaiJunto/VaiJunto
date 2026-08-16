# VaiJunto 2.0.0.0 — Plano de Produto do MVP Completo

> Documento vivo de escopo fechado. Novas mudanças devem ser registradas como
> revisão de requisito. Este arquivo descreve o comportamento esperado pelo
> usuário, sem definir ferramentas de implementação.

## 1. Objetivo da versão

Concluir o MVP do VaiJunto para a comunidade da Fatec, cobrindo a jornada completa:

1. cadastrar e gerenciar veículos;
2. oferecer ou encontrar uma carona;
3. solicitar uma vaga;
4. aceitar ou recusar a solicitação;
5. ocultar caronas recusadas e respeitar bloqueios entre pessoas;
6. liberar uma conversa privada depois do aceite;
7. acompanhar o estado da carona até seu encerramento;
8. limitar a ajuda financeira ao rateio estimado dos custos, sem torná-la obrigatória;
9. disponibilizar um painel administrativo para validação e operação da comunidade.

A versão do aplicativo será alterada para `2.0.0.0` somente quando o escopo
confirmado neste plano estiver implementado, validado e pronto para entrega.

Status do planejamento: **PRONTO PARA IMPLEMENTAÇÃO**  
Decisões de produto pendentes: **0**

## Acompanhamento da implementação

Progresso geral atual: **0%**

O valor inicial indica que o código existente ainda não foi auditado história por
história contra este plano; não significa que todas as funcionalidades estejam ausentes.
O primeiro passo da implementação é atualizar este quadro com o estado real do MVP.

Este quadro deve ser atualizado durante a implementação. A porcentagem representa
entrega real da história, incluindo comportamento, integração e validação.

| Progresso | Significado |
|---:|---|
| 0% | Não iniciado |
| 25% | Estrutura inicial criada |
| 50% | Fluxo principal funciona parcialmente |
| 75% | Fluxo completo, ainda faltam validações ou ajustes |
| 100% | Critérios de aceite atendidos e testes concluídos |

Uma história não pode ser marcada como `100%` enquanto uma dependência obrigatória
estiver incompleta. O progresso geral será a média das histórias e dos portões de
entrega listados abaixo. Atualizar também a coluna `Estado` quando houver bloqueio.

| ID | Entrega | Progresso | Estado | Dependências principais |
|---|---|---:|---|---|
| US-PER-01 | Cadastrar e manter meu perfil | 0% | Não iniciado | Autenticação; e-mail institucional; armazenamento de imagem |
| US-END-01 | Pesquisar um endereço relevante | 0% | Não iniciado | Serviço de endereços; referência da Fatec SJC; localização |
| US-END-02 | Gerenciar endereços salvos | 0% | Não iniciado | US-END-01; usuário autenticado; armazenamento privado |
| US-VEI-01 | Cadastrar o primeiro veículo | 0% | Não iniciado | Cadastro autenticado; catálogo de veículos |
| US-VEI-02 | Gerenciar meus veículos | 0% | Não iniciado | US-VEI-01 |
| US-VEI-03 | Escolher o veículo da carona | 0% | Não iniciado | US-VEI-01; US-VEI-02; oferta de carona |
| US-AJU-01 | Calcular o limite estimado | 0% | Não iniciado | US-VEI-01; trajeto; consumo; preço regional |
| US-AJU-02 | Informar ajuda opcional | 0% | Não iniciado | US-AJU-01 |
| US-LIS-01 | Explorar e filtrar caronas | 0% | Não iniciado | Endereços; ofertas e pedidos publicados; privacidade |
| US-MIN-01 | Acompanhar minhas caronas | 0% | Não iniciado | Ofertas, pedidos e participações; histórico |
| US-DEM-01 | Publicar um pedido de carona | 0% | Não iniciado | US-END-01; usuário autenticado; lista principal |
| US-SOL-01 | Pedir uma vaga | 0% | Não iniciado | Oferta publicada; usuário autenticado |
| US-SOL-02 | Aceitar um passageiro | 0% | Não iniciado | US-SOL-01; US-NOT-01 |
| US-SOL-03 | Recusar uma solicitação | 0% | Não iniciado | US-SOL-01; filtros individuais |
| US-SOL-04 | Responder a pedido de carona | 0% | Não iniciado | Pedido publicado; US-CHA-01; US-CHA-02 |
| US-SOL-05 | Passageiro cancelar participação | 0% | Não iniciado | US-SOL-01; US-SOL-02; US-NOT-01; US-ADM-04 |
| US-OFE-00 | Publicar uma oferta de carona | 0% | Não iniciado | US-END-01; US-VEI-03; US-AJU-02; usuário autenticado |
| US-OFE-01 | Editar carona publicada | 0% | Não iniciado | Oferta; US-VEI-03; US-NOT-01 |
| US-OFE-02 | Motorista cancelar carona | 0% | Não iniciado | Oferta; US-NOT-01; US-ADM-04 |
| US-OFE-03 | Iniciar carona | 0% | Não iniciado | Oferta aceita; US-NOT-01 |
| US-OFE-04 | Registrar ausência e contestar | 0% | Não iniciado | US-OFE-03; US-NOT-01; US-ADM-04 |
| US-OFE-05 | Finalizar e avaliar a carona | 0% | Não iniciado | US-OFE-03; localização; US-NOT-01; US-ADM-04 |
| US-BLO-01 | Bloquear e desbloquear pessoa | 0% | Não iniciado | US-CHA-02; filtros de caronas; ajustes |
| US-CHA-01 | Listar conversas | 0% | Não iniciado | Usuário autenticado; armazenamento de conversas |
| US-CHA-02 | Conversar, anexar e denunciar mensagens | 0% | Não iniciado | US-CHA-01; aceite/proposta; mídia; localização; privacidade |
| US-CHA-03 | Receber mensagens oficiais do aplicativo | 0% | Não iniciado | US-CHA-01; eventos automáticos; identidade visual do app |
| US-NOT-01 | Central e envio de notificações | 0% | Não iniciado | Eventos de carona e chat |
| US-OFF-01 | Continuar usando com internet instável | 0% | Não iniciado | Cache local; sincronização; US-CHA-02; listas |
| US-NAV-01 | Navegar pelo aplicativo mobile | 0% | Não iniciado | Lista; minhas caronas; chats; ajustes; identidade visual |
| US-ADM-01 | Entrada administrativa por computador | 0% | Não iniciado | Experiência web/PWA administrativa |
| US-ADM-02 | Login administrativo separado | 0% | Não iniciado | Base administrativa isolada |
| US-ADM-03 | Conceder selo de verificação | 0% | Não iniciado | US-ADM-02; cadastro de usuários; auditoria |
| US-ADM-04 | Operar moderação e ocorrências | 0% | Não iniciado | US-ADM-02; eventos e históricos do sistema |
| US-ADM-05 | Conversa administrativa | 0% | Não iniciado | US-ADM-02; US-CHA-01; US-CHA-02 |
| PORTÃO-JURÍDICO | Revisão jurídica e de privacidade | 0% | Não iniciado | Regras financeiras e de moderação fechadas |
| PORTÃO-UX | Validação da experiência mobile | 0% | Não iniciado | Histórias do aplicativo comum; painel administrativo excluído |
| PORTÃO-PERF | Validação em aparelhos modestos | 0% | Não iniciado | Fluxos mobile; mídia; listas; mapas e chat |
| PORTÃO-QA | Testes completos da jornada | 0% | Não iniciado | Todas as histórias funcionais; PORTÃO-UX; PORTÃO-PERF |
| PORTÃO-ENTREGA | Publicação da versão 2.0.0.0 | 0% | Não iniciado | PORTÃO-JURÍDICO; PORTÃO-UX; PORTÃO-PERF; PORTÃO-QA; documentação |

## 2. Princípios de produto confirmados

- O VaiJunto é voltado à comunidade da Fatec.
- A carona é um deslocamento compartilhado, não uma fonte de lucro.
- A ajuda financeira é opcional e começa sem valor preenchido.
- Informações sensíveis do veículo não ficam públicas na lista de caronas.
- O selo de pessoa verificada é concedido pela equipe pelo painel administrativo.
- O cadastro de veículo é reutilizável; não será solicitado novamente a cada carona.
- Os fluxos devem usar perguntas curtas, linguagem direta e poucos campos por tela.
- A Fatec permanece obrigatoriamente como uma das pontas do trajeto no MVP.

## 3. Jornada principal desejada

### 3.1 Motorista sem veículo

`Oferecer carona → cadastrar veículo → voltar à oferta → montar rota → informar detalhes → publicar`

- O motorista não perde o ponto em que estava.
- Depois de salvar o primeiro veículo, ele volta automaticamente à criação da carona.
- Nas próximas ofertas, o veículo padrão já aparece selecionado.

### 3.2 Motorista com veículo

`Oferecer carona → montar rota → confirmar veículo e detalhes → publicar`

### 3.3 Passageiro

`Ver caronas → abrir uma carona → pedir vaga → aguardar decisão → entrar no chat se aceito`

### 3.4 Motorista respondendo a um pedido publicado

`Ver pedidos de passageiros → escolher um pedido → iniciar conversa/proposta →
combinar detalhes → passageiro aceitar ou recusar dentro do chat`

### 3.5 Motorista recebendo uma solicitação

`Receber pedido → avaliar passageiro → aceitar ou recusar → conversar se aceito`

## 4. Épico A — Veículos

### US-VEI-01 — Cadastrar o primeiro veículo

**Como** motorista, **quero** cadastrar meu veículo antes de oferecer uma
carona, **para** que capacidade, identificação e custo estimado sejam coerentes.

Critérios confirmados:

- O cadastro será exigido ao tentar oferecer uma carona sem possuir veículo.
- Ao concluir, o motorista retorna automaticamente à criação da carona.
- O cadastro terá duas etapas curtas.
- Etapa 1: placa, ano, marca, modelo, versão e cor.
- Etapa 2: combustível, quantidade de passageiros e consumo sugeridos.
- Ao final, o motorista pode adicionar uma foto opcional do veículo sem impedir
  a conclusão do cadastro.
- O sistema sugere capacidade e consumo a partir do veículo selecionado.
- O motorista deve confirmar as sugestões.
- Se não houver uma sugestão disponível, os dados poderão ser informados manualmente.
- A quantidade representa passageiros e não inclui o motorista.

### US-VEI-02 — Gerenciar meus veículos

**Como** motorista, **quero** uma área com meus veículos, **para** adicionar,
editar, remover e escolher qual uso normalmente.

Critérios confirmados:

- A área se chamará `MEUS VEÍCULOS` e ficará em `AJUSTES`.
- Será permitido cadastrar vários veículos.
- Um veículo poderá ser marcado como padrão.
- A área permitirá adicionar, editar e excluir veículos.
- enquanto o veículo ainda não possuir histórico de caronas, placa, marca, modelo
  e capacidade podem ser corrigidos respeitando as validações do cadastro;
- depois que existir histórico, alterações de placa, marca, modelo ou capacidade
  são enviadas para análise administrativa e não substituem silenciosamente os
  dados antigos;
- cor, combustível e consumo podem ser editados normalmente pelo motorista;
- caronas futuras vinculadas recebem os novos dados operacionais e seus passageiros
  pendentes ou aceitos são notificados sobre a alteração;
- mudanças de combustível ou consumo recalculam o limite da ajuda financeira;
- se o novo limite for menor que a ajuda informada na carona, o valor é reduzido
  ao novo máximo e os participantes são avisados;
- um veículo ligado a uma carona futura ou em andamento não pode ser excluído;
- antes de excluir, o motorista precisa trocar o veículo dessas caronas ou
  cancelá-las conforme as regras aplicáveis;
- a tela informa quais caronas impedem a exclusão e oferece acesso direto a elas;
- ao excluir, o veículo desaparece de `MEUS VEÍCULOS`, mas permanece arquivado
  nos registros das caronas anteriores;
- caronas antigas preservam a identificação e as características do veículo que
  estavam válidas no momento da viagem;
- uma mesma placa pode pertencer a apenas uma conta de usuário ativa;
- tentativa de cadastrar uma placa já vinculada orienta a pessoa a solicitar
  análise administrativa, sem revelar dados do outro proprietário;
- administradores podem consultar o cadastro completo, alterações, vínculos,
  caronas e estado arquivado do veículo para resolver conflitos;
- administradores analisam pedidos de alteração de placa, marca, modelo ou
  capacidade quando o veículo já possuir histórico;
- a decisão administrativa sobre transferência de placa fica registrada em auditoria.

### US-VEI-03 — Escolher o veículo da carona

**Como** motorista com mais de um veículo, **quero** confirmar ou trocar o
veículo ao criar a oferta, **para** publicar capacidade e custo corretos.

Critérios confirmados:

- O veículo padrão começa selecionado.
- A oferta mostra um cartão compacto, por exemplo:
  `Chevrolet Onix • Branco • 4 passageiros`.
- O cartão possui a ação `TROCAR`.
- A placa não aparece nesse cartão.
- A quantidade de vagas oferecidas não pode superar a capacidade confirmada.

## 5. Épico B — Ajuda financeira e limite de rateio

### US-AJU-01 — Calcular o limite estimado

**Como** motorista, **quero** receber um limite estimado para a ajuda
financeira, **para** compartilhar os gastos sem transformar a carona em lucro.

Base de cálculo confirmada:

- distância estimada do trajeto;
- reserva de 10% sobre a distância para pequenos desvios e pontos de encontro;
- consumo médio estimado e confirmado no cadastro do veículo;
- combustível escolhido para aquela carona;
- preço regional de referência do combustível;
- divisão igual entre todos os ocupantes, incluindo o motorista.

Regras confirmadas:

- o cálculo é deliberadamente simples e conservador: serve apenas para criar um
  teto razoável, não para reproduzir com exatidão todos os custos da viagem;
- pedágio, estacionamento e outras despesas adicionais não entram no cálculo;
- não haverá tratamentos especiais complexos por tipo de trajeto ou tecnologia
  do veículo nesta versão;
- para o rateio, `total de ocupantes` significa motorista mais o total de vagas
  oferecidas na carona;
- pedidos, aceites, recusas e cancelamentos de passageiros não aumentam o limite
  individual já calculado;
- alterar o total de vagas durante a janela permitida recalcula o limite, sem
  aumentar automaticamente o valor de ajuda escolhido pelo motorista;

Fórmula de referência:

`custo estimado = distância ajustada ÷ consumo × preço médio do combustível`

`limite individual = custo estimado ÷ total de ocupantes`

O modelo usa uma referência regional mantida pelo sistema, sem bloquear a criação
da carona por variações pequenas ou temporárias de preço. A revisão jurídica formal
do modelo antes do lançamento permanece `OBRIGATÓRIA`.

### US-AJU-02 — Informar uma ajuda opcional

**Como** motorista, **quero** escolher se peço ajuda financeira e qual valor,
**para** poder oferecer também caronas gratuitas.

Critérios confirmados:

- O campo começa vazio.
- Vazio significa carona sem ajuda financeira.
- O motorista pode informar qualquer valor entre zero e o limite calculado.
- o valor abaixo do teto é uma escolha do motorista e não uma tarifa calculada
  ou sugerida pelo aplicativo;
- O sistema não preenche automaticamente o limite como preço sugerido.
- Se o motorista informar um valor maior, o valor será reduzido ao limite.
- O ajuste acontece ao sair do campo ou ao tentar continuar, não enquanto digita.
- O aplicativo explica o ajuste com linguagem simples, por exemplo:
  `Ajustamos para R$ 5,00, o máximo estimado para esta rota.`
- A tela deverá explicar resumidamente como o limite foi calculado.

## 6. Épico C — Descoberta, solicitação e decisão da carona

### US-LIS-01 — Explorar e filtrar caronas

**Como** fatecano, **quero** alternar entre ofertas e pedidos próximos,
**para** encontrar rapidamente uma carona compatível com meu trajeto.

Requisitos confirmados:

- a lista principal possui as abas `CARONAS OFERECIDAS` e `PEDIDOS DE CARONA`;
- ao abrir a tela, `CARONAS OFERECIDAS` é a aba selecionada por padrão;
- a troca de aba é direta e preserva os filtros que fizerem sentido nas duas listas;
- os filtros disponíveis são `INDO PARA A FATEC`, `SAINDO DA FATEC`, data,
  faixa de horário e bairro;
- os filtros mais usados ficam acessíveis sem ocupar grande parte da tela;
- a lista ordena primeiro pelo horário esperado mais próximo;
- quando duas opções possuem horário equivalente, a mais próxima do ponto de
  saída da pessoa aparece primeiro;
- para calcular proximidade, o aplicativo usa a localização atual quando houver
  permissão;
- sem essa permissão, usa o endereço salvo escolhido pela pessoa e, se nenhum
  tiver sido escolhido, o último local pesquisado;
- se nenhuma referência estiver disponível, mantém a ordenação por horário e
  permite que a pessoa informe um bairro ou endereço;
- cada cartão respeita as informações permitidas antes do aceite e não revela
  endereço exato nem dados protegidos do veículo;
- filtros ativos ficam visíveis e podem ser removidos individualmente ou pela
  ação `LIMPAR FILTROS`;
- quando `CARONAS OFERECIDAS` não tiver resultados, o estado vazio oferece
  `OFERECER CARONA`;
- quando `PEDIDOS DE CARONA` não tiver resultados, o estado vazio oferece
  `PUBLICAR PEDIDO`;
- paginação, atualização e estados vazios devem manter a experiência direta em
  telas pequenas.

### US-MIN-01 — Acompanhar minhas caronas

**Como** usuário, **quero** reunir minhas participações atuais e anteriores,
**para** acompanhar compromissos sem procurar novamente na lista pública.

Requisitos confirmados:

- existe a área `MINHAS CARONAS` com as abas `PRÓXIMAS` e `HISTÓRICO`;
- a área reúne caronas nas quais a pessoa é motorista ou passageiro;
- cada cartão identifica claramente o papel com `VOCÊ DIRIGE` ou `VOCÊ VAI`;
- `PRÓXIMAS` reúne solicitações pendentes, vagas aceitas, ofertas publicadas e
  caronas em andamento;
- `HISTÓRICO` reúne caronas concluídas, canceladas, recusadas ou expiradas;
- cada estado usa texto direto e não depende somente de cor ou ícone;
- uma carona concluída pelo motorista oferece a ação `OFERECER NOVAMENTE`;
- essa ação cria um novo rascunho com rota, horário e veículo anteriores, sempre
  permitindo revisão antes da publicação;
- data, vagas e ajuda financeira precisam ser confirmadas para a nova oferta;
- passageiros, solicitações, aceites, ocorrências e conversas nunca são copiados
  para a nova carona;
- `PRÓXIMAS` ordena do compromisso mais próximo para o mais distante;
- `HISTÓRICO` ordena do evento mais recente para o mais antigo;
- o histórico pode ser filtrado por `COMO MOTORISTA`, `COMO PASSAGEIRO` e estado;
- todo o histórico disponível para a conta é carregado gradualmente, respeitando
  as regras de retenção e exclusão definidas na política de privacidade.

### US-DEM-01 — Publicar um pedido de carona

**Como** passageiro, **quero** publicar quando e de onde preciso sair,
**para** que motoristas compatíveis possam me oferecer uma carona.

Requisitos confirmados:

- o formulário pergunta se a pessoa está indo para a Fatec ou saindo da Fatec;
- a Fatec permanece como uma das pontas obrigatórias e a pessoa informa o outro ponto;
- o pedido exige data e uma faixa de horário em que a pessoa consegue sair;
- a escolha do ponto usa a busca regional, os endereços salvos e a localização
  atual definidos no épico de endereços;
- antes de publicar, a pessoa revisa direção, região aproximada, data e faixa de horário;
- o pedido aparece na aba `PEDIDOS DE CARONA` respeitando a privacidade do endereço;
- motoristas interessados respondem pelo fluxo de proposta em chat pendente;
- o pedido não reserva vaga em nenhuma oferta;
- não haverá repetição semanal automática na versão 2.0;
- enquanto nenhuma proposta tiver sido aceita, o passageiro pode editar ponto,
  data e faixa de horário do pedido;
- antes do aceite, o passageiro também pode cancelar o pedido sem informar motivo
  e sem gerar cancelamento ou ocorrência negativa;
- depois que uma proposta for aceita, o pedido público já estará encerrado e a
  desistência seguirá o fluxo de cancelamento de participação, com justificativa;
- quando o pedido for editado, cada motorista com proposta pendente recebe no
  chat uma mensagem automática resumindo o que mudou;
- se a alteração tornar o pedido incompatível, o motorista pode retirar a proposta
  sem gerar cancelamento ou ocorrência negativa.

### US-SOL-01 — Pedir uma vaga

**Como** fatecano, **quero** pedir uma vaga em uma carona disponível, **para**
que o motorista possa aceitar ou recusar minha participação.

Estado inicial: `AGUARDANDO RESPOSTA`.

Requisitos confirmados:

- este fluxo começa em uma carona publicada pelo motorista;
- cada solicitação reserva exatamente uma vaga para a própria pessoa autenticada;
- não é possível solicitar vagas adicionais para amigos, familiares ou acompanhantes;
- qualquer outra pessoa precisa possuir sua própria conta e enviar uma solicitação
  separada para o motorista;
- enviar uma solicitação ou receber uma proposta não reserva a vaga;
- enquanto aguarda resposta, o passageiro pode solicitar várias caronas com
  horários sobrepostos;
- o motorista aceita ou recusa;
- quando uma solicitação ou proposta é aceita, os demais pedidos e propostas do
  passageiro que conflitarem com aquele horário são encerrados automaticamente;
- cada conversa ou solicitação encerrada recebe uma mensagem automática informando
  apenas que o passageiro confirmou outra carona;
- um pedido pendente não expira por tempo contado desde sua criação;
- o pedido permanece aberto até o horário esperado de saída da carona;
- ao chegar o horário esperado sem decisão, o pedido expira;
- o chat normal é liberado depois do aceite do motorista.

### US-SOL-02 — Aceitar um passageiro

**Como** motorista, **quero** aceitar uma solicitação, **para** confirmar a
vaga do passageiro e liberar a conversa privada.

Requisitos já informados:

- somente o motorista da carona pode decidir;
- antes de concluir o aceite, o sistema verifica os compromissos já aceitos do
  passageiro;
- uma pessoa não pode ser aceita em duas caronas cujos horários estimados se
  sobreponham;
- quando houver conflito, o novo aceite é bloqueado e a tela mostra qual compromisso
  existente ocupa aquele período, sem expor dados a terceiros;
- o aceite confirma o passageiro na carona;
- cada aceite reduz automaticamente uma vaga disponível;
- quando as vagas chegam a zero, a carona deixa de aparecer na lista pública;
- ao preencher a última vaga, todas as solicitações ainda pendentes daquela carona
  são encerradas com `AS VAGAS FORAM PREENCHIDAS`;
- esse encerramento não é tratado como recusa, cancelamento ou ocorrência negativa
  para nenhuma das partes;
- se uma participação for cancelada depois, a vaga volta e a carona pode reaparecer
  na lista enquanto ainda estiver dentro do período válido;
- solicitações encerradas por lotação não são restauradas automaticamente; a pessoa
  interessada precisa enviar um novo pedido se a vaga reaparecer;
- o aceite libera o chat entre motorista e passageiro;
- os dados liberados para cada lado depois do aceite seguem integralmente as regras
  da seção de privacidade deste plano.

### US-SOL-03 — Recusar uma solicitação

**Como** motorista, **quero** recusar um pedido, **para** não incluir aquele
passageiro naquela carona.

Requisitos já informados:

- a recusa vale somente para aquela carona;
- a carona recusada deixa de aparecer para aquele passageiro;
- a recusa não bloqueia automaticamente a pessoa em outras caronas;
- depois da recusa, a interface mostra `DESFAZER` por alguns segundos;
- usar `DESFAZER` dentro desse período devolve a solicitação ao estado pendente;
- depois que a ação desaparece, aquela solicitação permanece recusada e não volta
  à lista do motorista.

### US-SOL-04 — Motorista responder a um pedido de carona

**Como** motorista, **quero** responder ao pedido publicado por um passageiro,
**para** conversar e propor uma carona compatível.

Requisitos confirmados:

- este fluxo começa em um pedido de carona publicado pelo passageiro;
- o motorista inicia uma conversa/proposta com o passageiro;
- motorista e passageiro podem conversar antes da decisão;
- o passageiro aceita ou recusa a proposta dentro do chat;
- antes do aceite, o chat mostra primeiro nome, foto, selo, horário, ajuda
  financeira quando existir e quantidade de vagas;
- modelo, cor e placa continuam ocultos enquanto a proposta estiver pendente;
- o passageiro pode conversar com vários motoristas interessados no mesmo pedido;
- o passageiro pode aceitar apenas uma proposta;
- ao aceitar uma proposta, o pedido sai da lista e as demais propostas são
  encerradas com a mensagem `O passageiro encontrou uma carona`;
- ao recusar, aquela proposta e conversa são arquivadas;
- recusar uma proposta não bloqueia o motorista em pedidos futuros;
- este chat pendente é uma exceção à regra geral de liberar chat somente depois
  do aceite;
- dados exibidos antes do aceite continuam obedecendo às regras de privacidade;
- a proposta pendente expira automaticamente no horário esperado de saída da carona;
- ao expirar, as duas partes veem uma mensagem automática de encerramento e não
  podem continuar enviando conteúdo naquela conversa;
- o motorista pode retirar sua proposta antes do passageiro aceitá-la;
- retirar uma proposta ainda pendente não gera ocorrência ou advertência;
- a conversa é encerrada com uma mensagem automática e permanece arquivada.

### US-SOL-05 — Passageiro cancelar sua participação

**Como** passageiro, **quero** cancelar um pedido pendente ou uma vaga aceita,
**para** liberar o motorista quando eu não puder mais participar.

Requisitos confirmados:

- o passageiro pode cancelar enquanto aguarda a resposta;
- o passageiro também pode cancelar depois do aceite;
- depois do aceite, a vaga cancelada volta a ficar disponível;
- o cancelamento solicita um motivo;
- haverá uma lista curta de motivos fixos, semelhante a aplicativos de mobilidade;
- os motivos são `MUDANÇA DE PLANOS`, `ENCONTREI OUTRA CARONA`,
  `NÃO POSSO ESPERAR`, `PEDIDO FEITO POR ENGANO`, `QUESTÃO DE SEGURANÇA` e `OUTRO`;
- a opção `OUTRO` permite escrever um motivo livre;
- em `OUTRO`, escrever o motivo é obrigatório;
- a outra parte vê somente a categoria fixa selecionada;
- o texto livre de `OUTRO` fica visível apenas para seu autor e administradores;
- todos os cancelamentos depois do aceite ficam registrados para análise administrativa;
- três cancelamentos de passageiro em 30 dias geram um alerta para revisão manual;
- dois cancelamentos de passageiro dentro da última hora antes da saída também
  geram um alerta;
- os alertas não aplicam punição, advertência ou identificação pública automaticamente.

### US-OFE-00 — Publicar uma oferta de carona

**Como** motorista, **quero** publicar os dados essenciais da viagem,
**para** encontrar fatecanos interessados nas vagas disponíveis.

Requisitos confirmados:

- o formulário pergunta se o motorista está indo para a Fatec ou saindo da Fatec;
- a Fatec permanece como uma das pontas obrigatórias e o motorista informa o outro ponto;
- a oferta exige data e horário esperado de saída;
- o motorista seleciona um veículo cadastrado e informa a quantidade de vagas;
- a quantidade de vagas nunca pode ultrapassar a capacidade confirmada do veículo;
- a ajuda financeira é opcional e segue o limite simples definido neste plano;
- antes da publicação, a pessoa revisa direção, ponto aproximado, data, horário,
  veículo, vagas e eventual ajuda financeira;
- antes da publicação, o sistema verifica outras caronas em que a pessoa é motorista;
- o motorista não pode publicar duas ofertas cujos horários estimados se sobreponham;
- quando houver conflito, a tela identifica o compromisso e orienta a alterar o
  horário antes de publicar;
- não haverá repetição semanal automática na versão 2.0;
- a ação `OFERECER NOVAMENTE` de uma carona concluída será o caminho rápido para
  reutilizar uma configuração anterior.

### US-OFE-01 — Motorista editar uma carona publicada

**Como** motorista, **quero** editar facilmente as configurações da minha
carona, **para** corrigir ou atualizar os detalhes sem precisar recriá-la.

Requisitos confirmados:

- a carona terá uma ação clara de editar em sua tela de detalhes;
- a edição é permitida somente até uma hora antes do horário previsto de saída;
- durante a última hora antes da saída, os campos ficam bloqueados;
- depois que a viagem começa, nenhuma configuração pode ser editada;
- dentro da última hora, a única alternativa para uma mudança impeditiva é
  cancelar a carona e informar o motivo;
- alterações relevantes geram notificação para passageiros com solicitação
  pendente e passageiros já aceitos;
- a notificação informa resumidamente o que mudou;
- antes do limite de uma hora, podem ser editados rota, horário, veículo, vagas
  e ajuda financeira;
- alterações de rota, horário, veículo ou aumento da ajuda financeira exigem
  nova confirmação dos passageiros já aceitos;
- a vaga permanece reservada enquanto aguarda essa nova confirmação;
- a reconfirmação não vence por um contador iniciado no momento da edição;
- o prazo de reconfirmação será relacionado ao fechamento das edições e ao
  horário esperado de saída, evitando retirar a vaga de quem estava dormindo;
- mudanças importantes que exigem reconfirmação fecham
  duas horas antes do limite geral de edição; como a edição geral fecha uma hora
  antes da saída, essas mudanças fechariam três horas antes da saída;
- o passageiro tem até o fechamento geral das edições, uma
  hora antes da saída, para reconfirmar;
- o motorista não pode reduzir as vagas para menos que o total de passageiros
  já aceitos;
- o aplicativo explica que é necessário liberar vagas antes de fazer essa redução.

### US-OFE-02 — Motorista cancelar uma carona

**Como** motorista, **quero** cancelar uma carona quando não puder realizá-la,
**para** avisar os passageiros e encerrar corretamente os compromissos.

Requisitos confirmados:

- o cancelamento exige um motivo;
- o cancelamento continua disponível durante a última hora, quando a edição já
  está bloqueada;
- todos os cancelamentos ficam registrados para consulta administrativa;
- o registro inclui motorista, carona, data e hora do cancelamento, antecedência
  em relação à saída e motivo informado;
- o painel permitirá avaliar se alguém está cancelando repetidamente ou usando
  o sistema de forma abusiva;
- os motivos fixos são `IMPREVISTO PESSOAL`, `PROBLEMA COM O VEÍCULO`,
  `SAÚDE/EMERGÊNCIA`, `MUDANÇA DE COMPROMISSO`, `QUESTÃO DE SEGURANÇA` e `OUTRO`;
- em `OUTRO`, escrever o motivo é obrigatório;
- passageiros com solicitação pendente e passageiros aceitos recebem notificação;
- a carona cancelada sai da lista pública;
- o chat recebe uma mensagem automática informando o encerramento da carona;
- três cancelamentos em 30 dias geram um alerta para revisão administrativa;
- dois cancelamentos dentro da última hora também geram um alerta;
- alertas não suspendem a conta automaticamente: o administrador avalia o contexto.

### US-OFE-03 — Motorista iniciar a carona

**Como** motorista, **quero** informar o início real da carona, **para** que o
aplicativo diferencie a previsão da execução da viagem.

Requisitos confirmados:

- o horário publicado é sempre apresentado como `HORÁRIO ESPERADO DE SAÍDA`;
- esse horário serve como referência para pedidos, organização e notificações;
- o motorista é quem confirma o início real da carona;
- passageiros aceitos são avisados quando o motorista inicia a carona;
- sem confirmação de todos os passageiros aceitos, o motorista pode antecipar
  a saída em no máximo 15 minutos;
- com confirmação de todos os passageiros aceitos, a saída pode ser antecipada
  além de 15 minutos;
- quando o atraso previsto ultrapassar 15 minutos, o motorista deve informar um
  novo horário esperado de saída;
- todos os passageiros pendentes e aceitos recebem a nova previsão;
- quem não puder esperar pode cancelar sem gerar ocorrência negativa no histórico;
- a vaga de quem desistir por causa do atraso volta a ficar disponível, quando
  ainda houver tempo útil para outra pessoa solicitar.

### US-OFE-04 — Informar que alguém não apareceu

**Como** participante, **quero** informar que a outra pessoa não apareceu,
**para** registrar problemas recorrentes de compromisso.

Requisitos confirmados:

- depois do horário esperado, motorista ou passageiro pode marcar a outra parte
  como `NÃO APARECEU`;
- a ocorrência entra no histórico administrativo;
- a pessoa marcada recebe uma notificação;
- a pessoa tem 48 horas para contestar a ocorrência;
- enquanto existir contestação pendente, a pessoa não pode publicar uma carona
  nem criar um pedido de carona;
- compromissos já aceitos continuam ativos durante a contestação;
- interromper compromissos existentes exige uma suspensão administrativa separada;
- a tela de bloqueio explica que é necessário concluir a contestação para voltar
  a criar ofertas ou pedidos;
- a notificação deixa claro que não contestar dentro do prazo pode resultar em
  confirmação da ocorrência e advertência administrativa;
- se não houver contestação, o caso fica disponível para decisão do administrador;
- o administrador pode marcar a conta como `USUÁRIO ADVERTIDO`;
- a advertência não é aplicada automaticamente apenas pelo fim do prazo;
- normalmente, a advertência fica visível somente para a própria pessoa e para
  administradores;
- quando houver várias advertências confirmadas, o administrador pode tornar a
  identificação de advertência pública;
- a opção administrativa fica disponível quando existirem pelo menos três
  ocorrências confirmadas nos últimos 90 dias;
- atingir esse número não publica a identificação automaticamente;
- o administrador avalia o contexto e decide manualmente;
- o texto público da identificação será `EM OBSERVAÇÃO`;
- detalhes e justificativas permanecem privados para a pessoa e administradores;
- a identificação pública é sempre temporária e possui data de início e término;
- a duração máxima inicial é de 30 dias;
- ao final do prazo, a identificação desaparece automaticamente;
- o administrador pode removê-la antes do vencimento, registrando a justificativa;
- uma renovação exige nova decisão administrativa e novo motivo registrado;
- uma identificação pública nunca pode permanecer indefinidamente na conta;
- não existe punição automática por um registro isolado;
- a contestação oferece motivos fixos e a opção `OUTRO`;
- em `OUTRO`, uma explicação escrita é obrigatória;
- o administrador pode conversar separadamente com as duas partes;
- a decisão final será `OCORRÊNCIA CONFIRMADA` ou `OCORRÊNCIA REMOVIDA`;
- a decisão e sua justificativa ficam registradas;
- para manter o fluxo simples na versão 2.0, a contestação aceita uma explicação
  escrita e as mensagens que a própria pessoa selecionar para compartilhar;
- o administrador pode pedir esclarecimentos pelo chat administrativo;
- a decisão administrativa encerra a contestação; não haverá uma segunda camada
  formal de recurso dentro do aplicativo nesta versão.

### US-OFE-05 — Finalizar e avaliar a carona

**Como** motorista, **quero** registrar o encerramento real da carona, **para**
concluir o compromisso e liberar a avaliação dos participantes.

Requisitos confirmados:

- o motorista encerra a viagem pela ação `FINALIZAR CARONA`;
- a finalização sem justificativa somente é permitida quando a localização do
  motorista estiver dentro de um raio de 500 metros da Fatec ou do ponto de chegada
  registrado na carona;
- ao entrar nesse raio, o aplicativo disponibiliza de forma sutil para o motorista
  o botão `FINALIZAR CARONA`, sem exibir uma contagem regressiva chamativa;
- se o motorista permanecer dentro do raio por 15 minutos, o sistema finaliza a
  carona automaticamente;
- quando faltar um minuto para a finalização automática, o aplicativo envia um
  aviso com a ação `AINDA NÃO CHEGUEI`;
- usar `AINDA NÃO CHEGUEI` interrompe a finalização e reinicia a contagem somente
  depois de uma nova entrada válida na área;
- se sair da área antes dos 15 minutos, a contagem deixa de ser válida e uma nova
  permanência completa será necessária para a finalização automática;
- se estiver fora das duas áreas aceitas, o motorista ainda pode finalizar, mas
  fica com uma justificativa pendente;
- a justificativa pode ser enviada em até 48 horas após a finalização;
- os motivos são `DESTINO ALTERADO EM COMUM ACORDO`, `ENCERRAMENTO ANTECIPADO`,
  `EMERGÊNCIA`, `PROBLEMA NO VEÍCULO`, `PROBLEMA NO GPS` e `OUTRO`;
- em `OUTRO`, escrever a justificativa é obrigatório;
- se o prazo de 48 horas terminar sem justificativa, o motorista recebe um aviso
  e a falta fica registrada para consulta administrativa;
- três faltas de justificativa em 90 dias geram uma análise manual no painel;
- essa recorrência não aplica suspensão ou identificação pública automaticamente;
- os passageiros aceitos recebem a confirmação de que a carona foi finalizada;
- depois da finalização, motorista e passageiros respondem `CORREU TUDO BEM?`
  com `SIM` ou `TIVE UM PROBLEMA`;
- a avaliação usa uma escala de 1 a 5 estrelas;
- cada passageiro pode avaliar o motorista;
- o motorista pode avaliar separadamente cada passageiro aceito;
- todas as avaliações são opcionais e podem ser ignoradas ou deixadas para depois;
- a avaliação permanece disponível por sete dias depois da finalização;
- depois dos sete dias, a opção desaparece e não gera aviso ou penalidade;
- deixar de avaliar uma ou mais pessoas não bloqueia ofertas, pedidos, chats ou
  qualquer outra função do aplicativo;
- a interface permite ao motorista pular todas as avaliações sem precisar abrir
  individualmente o perfil de cada passageiro;
- as estrelas, avaliações individuais e médias não são públicas e ficam visíveis
  somente no painel administrativo;
- problemas usam motivos fixos e permitem um comentário opcional para análise
  administrativa;
- o aplicativo não apresenta ranking público de motoristas ou passageiros;
- providências que o administrador pode tomar depois da análise da recorrência
  seguem as regras gerais de advertência e moderação.

## 7. Épico D — Bloqueio entre pessoas

### US-BLO-01 — Bloquear uma pessoa

**Como** usuário, **quero** bloquear outra pessoa, **para** não voltar a
encontrá-la nas caronas ou conversas.

Requisitos já informados:

- bloqueio é diferente de recusa;
- o bloqueio é recíproco para fins de descoberta e contato;
- depois do bloqueio, nenhuma das duas pessoas vê caronas, pedidos ou propostas
  da outra;
- as duas pessoas não podem iniciar novas conversas entre si;
- a pessoa bloqueada não recebe aviso informando quem realizou o bloqueio;
- o chat possui uma ação de bloquear em uma área secundária e separada de
  `ACEITAR`, `RECUSAR` e das ações principais da carona;
- `AJUSTES` possui a área `BLOQUEADOS`;
- a área `BLOQUEADOS` lista as pessoas bloqueadas e permite desbloqueá-las sem
  precisar localizar uma conversa antiga;
- se existir uma carona aceita entre as duas pessoas, bloquear encerra aquela
  participação, devolve a vaga e arquiva o chat;
- para a outra pessoa aparece somente `Participação encerrada`, sem revelar o bloqueio;
- ao desbloquear, conteúdos futuros podem voltar a aparecer;
- desbloquear não restaura caronas recusadas, participações canceladas ou chats antigos;
- contas administrativas não podem ser bloqueadas e nunca aparecem em `BLOQUEADOS`;
- conversas administrativas permanecem disponíveis conforme suas próprias regras;

## 8. Épico E — Chat da carona

### US-CHA-01 — Listar conversas

**Como** usuário, **quero** visualizar minhas conversas de carona, **para**
retomar rapidamente a combinação com motorista ou passageiro.

Requisitos iniciais:

- a aba `CHAT` já prevista no aplicativo será usada para a lista;
- no fluxo em que o passageiro pede vaga em uma oferta, apenas o aceite do
  motorista cria ou libera a conversa normal;
- uma proposta iniciada por motorista em resposta a um pedido publicado aparece
  como conversa pendente antes do aceite;
- cada conversa é individual entre motorista e um passageiro;
- passageiros da mesma carona não entram em um grupo e não conversam entre si
  pelo VaiJunto;
- só é possível enviar mensagens quando existe uma carona ou proposta vinculada;
- a conversa continua aberta por 24 horas depois do encerramento da carona;
- depois das 24 horas, a conversa é arquivada e permanece somente para leitura;
- conversas administrativas seguem regras próprias e são a única exceção ao
  vínculo obrigatório com uma carona;
- conversas com mensagens não visualizadas aparecem primeiro e, depois, a lista
  segue a mensagem mais recente;
- o chat `VAIJUNTO` e conversas administrativas com pendência importante ficam em
  destaque sem alterar a ordem de todas as conversas continuamente;
- conversas arquivadas ficam em uma área separada;
- quando não houver conversas, a tela explica que o chat aparece após um aceite
  ou durante uma proposta de motorista.

### US-CHA-02 — Conversar e compartilhar detalhes da carona

**Como** participante aceito, **quero** conversar em privado com a outra parte,
**para** combinar ponto de encontro e detalhes da viagem.

Requisitos iniciais:

- a conversa é vinculada à carona aceita;
- motorista e passageiro podem trocar mensagens;
- no fluxo de resposta a um pedido publicado, a conversa pode começar como
  proposta pendente e conter as ações `ACEITAR` e `RECUSAR` para o passageiro;
- a barra inferior possui o botão `+` à esquerda, campo de texto, botão de câmera,
  acesso a figurinhas e botão contextual de áudio ou envio;
- o menu `+` permite escolher fotos e vídeos da galeria ou compartilhar localização;
- o botão de câmera permite capturar uma nova foto ou vídeo;
- a localização pode usar a posição atual ou um ponto de saída escolhido pela pessoa;
- uma localização recebida oferece ações para abrir o ponto no Google Maps ou Waze;
- as figurinhas disponíveis são cadastradas e gerenciadas pelos administradores;
- usuários comuns não podem criar, importar ou publicar figurinhas próprias;
- quando o campo de texto está vazio, o botão da direita funciona como gravação de áudio;
- para gravar áudio, a pessoa mantém o botão pressionado, arrasta para o lado para
  cancelar ou desliza para cima para travar a gravação sem continuar pressionando;
- cada áudio pode ter no máximo 2 minutos e a interface mostra o tempo gravado
  e o limite durante a captura;
- quando existe texto digitado, o mesmo espaço se transforma no botão de enviar;
- vídeos gravados pelo aplicativo têm duração máxima de 20 segundos;
- a câmera mostra um contador e encerra automaticamente a gravação ao atingir
  20 segundos, impedindo que a pessoa grave além do limite e depois perca o conteúdo;
- vídeos escolhidos da galeria também devem respeitar o limite de 20 segundos;
- ao escolher um vídeo da galeria com mais de 20 segundos, o aplicativo abre um
  editor para a pessoa selecionar e recortar o trecho que deseja enviar;
- cada envio pode conter no máximo cinco fotos ou vídeos, inclusive quando os
  dois tipos forem selecionados juntos;
- fotos e vídeos são comprimidos automaticamente antes do envio, preservando
  qualidade suficiente para combinar os detalhes da carona;
- a localização pode ser enviada como ponto fixo ou compartilhada ao vivo por
  15, 30 ou 60 minutos;
- o compartilhamento ao vivo mostra claramente o tempo restante e pode ser
  encerrado manualmente a qualquer momento por quem o iniciou;
- fotos, vídeos, áudios, figurinhas e localizações fazem parte da conversa privada
  e seguem as mesmas regras de criptografia e denúncia;
- a conversa exibe o indicador `digitando...` enquanto a outra pessoa escreve;
- arrastar uma mensagem para o lado inicia uma resposta e mostra uma referência
  compacta à mensagem original acima do novo conteúdo;
- não existe ação para encaminhar mensagens a outra pessoa ou conversa;
- mensagens próprias podem ser editadas ou apagadas para todos durante o primeiro
  minuto após o envio;
- uma mensagem alterada recebe a indicação `EDITADA`;
- uma mensagem apagada mantém no histórico o marcador `MENSAGEM APAGADA`, sem o
  conteúdo original visível aos participantes;
- não existem mensagens temporárias, mídias de visualização única ou conteúdo que
  desaparece automaticamente depois de aberto;
- cada mensagem usa um único indicador circular, com estes estados:
  - círculo com ponteiro: `ENVIANDO`, ainda saindo do aparelho;
  - círculo vazio: `ENVIADA`, recebida pelo serviço;
  - círculo com um check: `RECEBIDA`, entregue ao aparelho da outra pessoa;
  - círculo preenchido: `VISUALIZADA`, aberta pela outra pessoa;
- a confirmação de visualização é obrigatória e não pode ser desativada nos ajustes;
- o VaiJunto não oferece chamadas de áudio ou vídeo; o chat serve somente para
  alinhar a carona vinculada;
- o aplicativo aplica limites configuráveis de arquivo antes do envio, comprime
  mídia e informa de forma simples quando um item precisa ser reduzido;
- os limites de produto permanecem 20 segundos por vídeo, 2 minutos por áudio e
  até cinco fotos ou vídeos por envio;
- bloqueio fica disponível no menu secundário da conversa;
- as mensagens das conversas privadas permanecem criptografadas;
- para denunciar, a pessoa entra no modo de seleção e pode marcar várias mensagens;
- todas as mensagens selecionadas são enviadas juntas em uma única denúncia;
- a denúncia cria uma cópia imutável das mensagens e mídias selecionadas no estado
  em que estavam no momento do envio;
- essa cópia continua disponível ao administrador responsável mesmo que o autor
  edite ou apague posteriormente a mensagem original dentro da janela permitida;
- somente as mensagens escolhidas ficam visíveis para o administrador;
- o administrador não recebe automaticamente o restante nem um trecho adicional
  da conversa;
- o envio para análise deve preservar a privacidade do conteúdo não selecionado;
- a denúncia passa pelos estados `ENVIADA`, `EM ANÁLISE` e `RESOLVIDA`;
- mudanças de estado e o resumo final aparecem no chat oficial `VAIJUNTO`;
- o resumo informa que a análise terminou sem revelar medidas privadas tomadas
  sobre outra conta.

### US-CHA-03 — Receber mensagens oficiais do aplicativo

**Como** usuário, **quero** receber avisos automáticos em uma conversa oficial,
**para** encontrar novamente orientações e pendências importantes do VaiJunto.

Requisitos confirmados:

- a lista de conversas possui um chat oficial representado por uma persona do
  ambiente e da identidade do VaiJunto;
- o nome exibido dessa persona é `VAIJUNTO`, com imagem própria e selo `OFICIAL`;
- o selo `OFICIAL` diferencia mensagens automáticas dos selos `VERIFICADO` e
  `ADMIN`, usados por pessoas;
- avisos automáticos aparecem como mensagens nesse chat, em formato semelhante a
  um canal informativo ou newsletter;
- o canal guarda avisos que não devem existir somente como notificações transitórias;
- o aviso de que falta um minuto para a finalização automática aparece nesse chat
  com a ação `AINDA NÃO CHEGUEI`;
- avisos privados por falta de justificativa e outras pendências do usuário também
  podem ser entregues por essa conversa oficial;
- a persona automática é diferente de uma conta administrativa humana;
- o usuário não envia texto livre para a persona;
- quando uma resposta for necessária, a própria mensagem apresenta ações prontas,
  como `AINDA NÃO CHEGUEI`, `JUSTIFICAR` ou `VER CARONA`;
- comunicados de novidades podem ser silenciados;
- avisos operacionais da carona, pendências e comunicações administrativas
  importantes não podem ser silenciados;
- a persona usa a identidade visual do VaiJunto, tom curto, acolhedor e direto;
- mensagens evitam linguagem punitiva antes de uma decisão administrativa;
- cada aviso mostra somente as ações necessárias para aquele evento, mantendo o
  canal simples e permitindo novos tipos de ação sem redesenhar o chat.

### US-NOT-01 — Receber notificações importantes

**Como** participante, **quero** ser avisado sobre mudanças e contatos
relevantes, **para** acompanhar a carona sem manter o aplicativo aberto.

Eventos confirmados:

- novo pedido de vaga ou nova proposta de motorista;
- aceite ou recusa;
- nova mensagem;
- alteração da carona e pedido de reconfirmação;
- cancelamento;
- atraso e nova previsão;
- início da carona;
- registro ou contestação de ausência;
- contato administrativo.

Regras confirmadas:

- todos os eventos ficam registrados na central de notificações do aplicativo;
- quando o aparelho permitir, o evento também gera uma notificação externa;
- por padrão, notificações de mensagem mostram remetente e conteúdo;
- em `AJUSTES`, a pessoa pode desativar a prévia do conteúdo;
- configurações mais restritivas do próprio aparelho prevalecem;
- conversas comuns podem ser silenciadas;
- silenciar uma conversa não oculta alterações, atrasos, reconfirmações ou
  cancelamentos da carona na central de notificações;
- textos e prévias passarão pela revisão final de privacidade da versão.

### US-OFF-01 — Continuar usando com internet instável

**Como** usuário com conexão limitada, **quero** entender o que ainda está
disponível, **para** não perder mensagens nem acreditar que uma ação foi concluída.

Requisitos confirmados:

- sem conexão, o aplicativo mostra as últimas listas, caronas e conversas que já
  foram carregadas no aparelho;
- o conteúdo armazenado recebe uma indicação discreta de que pode estar desatualizado;
- mensagens escritas offline permanecem na conversa e são enviadas automaticamente
  quando a conexão voltar;
- enquanto aguardam conexão, essas mensagens exibem somente o indicador circular
  com ponteiro já definido para o estado de envio, sem a palavra `ENVIANDO`;
- falha definitiva permite tentar novamente ou apagar a mensagem local;
- aceitar, recusar, cancelar, publicar, editar, bloquear e outras ações que mudam
  compromissos exigem conexão confirmada;
- se uma ação crítica não chegar ao serviço, o aplicativo não altera o estado como
  se tivesse dado certo e apresenta `TENTAR NOVAMENTE`;
- o retorno da conexão atualiza os dados preservando o ponto da tela em que a
  pessoa estava.

## 9. Privacidade e informações exibidas

### US-PER-01 — Cadastrar e manter meu perfil

**Como** fatecano, **quero** manter um perfil simples e confiável, **para** usar
as caronas sem expor meus dados pessoais além do necessário.

Requisitos confirmados:

- o cadastro solicita nome completo, foto, curso e e-mail institucional da Fatec;
- o e-mail institucional é usado na autenticação e nunca aparece para outros usuários;
- nome completo também permanece privado para usuários comuns;
- em caronas, pedidos, propostas e chats, outras pessoas veem somente primeiro
  nome, foto, curso e selos permitidos;
- administradores autorizados podem consultar os dados completos para verificação,
  segurança e moderação;
- o e-mail institucional não pode ser alterado depois da criação da conta;
- uma alteração de nome completo é enviada para avaliação administrativa e só
  passa a valer depois da aprovação;
- o curso pode ser atualizado normalmente pela pessoa;
- uma pessoa já verificada que trocar a foto fica temporariamente com o selo
  pausado até a nova imagem ser conferida por um administrador;
- pessoas ainda não verificadas podem trocar a foto sem criar uma análise separada;
- em `AJUSTES > CONTA`, existe a ação `EXCLUIR MINHA CONTA`;
- a exclusão não pode ser concluída enquanto houver carona futura ou em andamento,
  solicitação ou proposta pendente, contestação, denúncia ou outra pendência
  administrativa que dependa da pessoa;
- quando existir impedimento, a tela lista cada pendência e oferece acesso direto
  para resolvê-la;
- depois de resolver os vínculos, a pessoa pode confirmar a exclusão;
- depois da confirmação, a conta entra em período de recuperação por sete dias;
- durante esses sete dias, a pessoa pode cancelar a exclusão e recuperar o acesso;
- ao final do prazo, a exclusão definitiva é processada automaticamente;
- dados que precisem permanecer por obrigação jurídica, segurança ou auditoria são
  anonimizados ou retidos somente pelo período definido na revisão de privacidade;
- o histórico preservado não mantém o perfil excluído visível para outros usuários;

Confirmado:

- antes do aceite, o passageiro vê somente o primeiro nome, a foto e o selo de
  verificação do motorista, a ajuda financeira quando existir e a quantidade de vagas;
- antes do aceite, origem, destino e ponto de encontro são apresentados somente
  pelo bairro ou por uma descrição regional aproximada;
- rua, número, complemento, referência e coordenadas exatas são liberados apenas
  para motorista e passageiro depois do aceite;
- nenhuma informação do veículo aparece antes do aceite;
- ao analisar um pedido, o motorista vê primeiro nome, foto, curso e selo de
  verificação do passageiro;
- depois do aceite, o passageiro vê modelo, cor e placa completa do veículo;
- depois do aceite, o passageiro também vê a foto do veículo quando o motorista
  tiver cadastrado uma;
- o aceite também libera o chat com o motorista;
- contas administrativas são identificadas pelos selos `VERIFICADO` e `ADMIN`;
- detalhes sensíveis do veículo serão exibidos apenas para pessoas aceitas;
- a placa não aparece no seletor compacto durante a criação da oferta.

Regras complementares:

- fotos de perfil ou veículo podem ser ocultadas pelo administrador quando
  violarem as regras da comunidade, sempre com motivo e auditoria;
- nesta versão, o único dado acadêmico compartilhado entre usuários é o curso;
- e-mail institucional, nome completo e demais dados administrativos permanecem
  privados;
- prazos legais de retenção e anonimização serão documentados na política de
  privacidade e aprovados no `PORTÃO-JURÍDICO` antes do lançamento.

## 10. Épico F — Endereços e pontos da carona

### US-END-01 — Pesquisar um endereço relevante

**Como** fatecano, **quero** encontrar minha rua entre as primeiras sugestões,
**para** informar o ponto da carona sem escolher por engano um endereço distante.

Requisitos confirmados:

- a busca usada em `DE ONDE VOCÊ SAI`, destinos e pontos relacionados à carona
  prioriza o Vale do Paraíba e a região da Fatec São José dos Campos;
- uma rua local compatível deve aparecer antes de homônimos distantes, evitando
  resultados de cidades como Manaus quando existe correspondência regional;
- a ordenação considera correspondência com o texto, tipo do local, cidade,
  bairro e proximidade da Fatec;
- pequenas diferenças de acentuação, abreviações e digitação não devem impedir
  uma sugestão regional relevante;
- inicialmente, a lista mostra resultados do Vale do Paraíba;
- a ação secundária `BUSCAR FORA DA REGIÃO` permite ampliar conscientemente a
  pesquisa para outras partes do Brasil;
- cada sugestão mostra rua e número quando disponíveis, bairro, cidade/UF e
  distância aproximada até a Fatec;
- ao selecionar uma sugestão, o sistema guarda o texto apresentado e as
  coordenadas corretas do ponto;
- depois de selecionar a rua, a pessoa pode informar número, complemento e ponto
  de referência;
- número, complemento e referência são opcionais, permitindo usar portarias,
  condomínios, estabelecimentos ou trechos sem numeração conhecida;
- a ação `USAR MINHA LOCALIZAÇÃO` obtém a posição atual e abre um mapa antes de
  confirmar;
- nesse mapa, a pessoa pode mover o pino para corrigir o ponto exato de encontro;
- se a permissão de localização não estiver disponível, a busca manual continua
  funcionando normalmente.

### US-END-02 — Gerenciar endereços salvos

**Como** usuário, **quero** salvar locais usados com frequência, **para** montar
uma carona sem pesquisar o mesmo endereço novamente.

Requisitos confirmados:

- existe uma área de endereços salvos nos ajustes;
- a pessoa pode usar os nomes rápidos `CASA` e `TRABALHO`;
- também é possível criar um nome personalizado para cada local;
- endereços salvos aparecem como atalhos ao escolher origem, destino ou ponto de
  encontro;
- a pessoa pode renomear, atualizar ou excluir um endereço salvo;
- na escolha de um local, um ícone de estrela permite salvá-lo rapidamente;
- cada pessoa pode manter até dez endereços salvos;
- além dos favoritos, os cinco locais usados mais recentemente aparecem como
  atalhos na escolha de origem, destino ou ponto de encontro;
- endereços salvos são privados e nunca aparecem automaticamente para outros
  usuários;
- número, complemento, referência e coordenada exata seguem a mesma proteção do
  endereço principal;
- ao publicar uma carona ou pedido, o sistema cria uma cópia dos dados de endereço
  usados naquele momento;
- renomear, atualizar ou excluir o endereço salvo depois da publicação não altera
  a rota de caronas ou pedidos já existentes;
- excluir um endereço salvo remove o item imediatamente e mostra a ação `DESFAZER`
  por alguns segundos, sem abrir uma confirmação que interrompa o fluxo;
- em `AJUSTES > PRIVACIDADE`, a pessoa pode apagar todos os locais recentes;
- cada local recente expira automaticamente 90 dias depois de seu último uso.

## 11. Épico G — Painel administrativo e verificação

### US-ADM-01 — Descobrir a entrada administrativa no computador

**Como** integrante da equipe, **quero** encontrar a entrada administrativa ao
abrir o endereço principal em um computador, **para** acessar a operação sem
misturar essa experiência com o aplicativo usado no celular.

Requisitos confirmados:

- no celular, o endereço principal abre a experiência normal do VaiJunto;
- no computador, o endereço principal abre uma página de entrada administrativa;
- a página pode usar uma mensagem bem-humorada, por exemplo:
  `Opa, parece que você descobriu o segredo.`;
- a aparência de computador ou celular muda apenas a experiência visual;
- a identificação do dispositivo nunca substitui autenticação e permissão administrativa;
- tablets, janelas pequenas e o APK administrativo usam o layout desktop disponível,
  sem compromisso de adaptação mobile;
- quando o espaço for insuficiente, a interface pode recomendar o uso de uma tela
  maior, mas nunca enfraquece a autenticação nem redireciona para dados administrativos;
- a página oferece a ação principal `ACESSAR PAINEL`;
- a página também oferece discretamente `ABRIR O VAIJUNTO NORMAL` para alunos
  que precisem usar o aplicativo pelo computador.

### US-ADM-02 — Entrar com permissão administrativa

**Como** administrador, **quero** entrar de forma protegida no painel, **para**
que pessoas comuns não tenham acesso a dados e ações internas.

Requisitos iniciais:

- nenhuma informação administrativa aparece antes da autenticação;
- somente contas com permissão administrativa entram no painel;
- o login administrativo é separado do login dos usuários do VaiJunto;
- cadastros e credenciais administrativas ficam isolados das contas comuns,
  preferencialmente em uma base administrativa separada;
- uma conta comum não pode ser promovida a administrador pelo aplicativo;
- simular um computador ou conhecer o endereço não concede acesso;
- a primeira conta administrativa é criada diretamente pelos desenvolvedores;
- novas contas são convidadas por um administrador com permissão superior e o
  convite possui validade limitada;
- a recuperação exige acesso ao e-mail administrativo e confirmação adicional de
  segurança;
- autenticação em duas etapas é obrigatória para contas administrativas;
- criação, recuperação e alteração de permissão ficam registradas em auditoria;
- o painel administrativo será um único produto em Flutter;
- será entregue simultaneamente para navegador, como PWA instalável, e como APK administrativo;
- navegador/PWA e APK compartilham as mesmas regras, dados e experiência, sem
  criar dois painéis administrativos independentes.

### US-ADM-03 — Conceder o selo de verificação

**Como** administrador, **quero** analisar uma pessoa e conceder ou remover o
selo de verificação, **para** indicar quem foi validado pela equipe do VaiJunto.

Requisitos confirmados:

- o selo não é concedido automaticamente;
- a decisão é realizada pelo painel administrativo;
- o selo representa a conferência manual da identidade e do vínculo ativo com a Fatec;
- nesta versão, o fatecano deve falar diretamente com um dos desenvolvedores
  para solicitar a verificação;
- pessoas sem selo podem usar normalmente as funções do VaiJunto;
- quem ainda não possui o selo aparece como `NÃO VERIFICADO`;
- o selo funciona como confiança adicional e não como bloqueio de entrada;
- em `AJUSTES`, a ação `COMO SER VERIFICADO` explica que é necessário falar
  diretamente com a equipe;
- depois da conferência, o desenvolvedor atribui o selo manualmente;
- não haverá aprovação automática nem um processo documental complexo dentro
  do aplicativo nesta primeira versão;
- futuramente, professores responsáveis ou pessoas de alta confiança poderão
  receber permissão específica para realizar verificações;
- o selo pode ser exibido nas caronas e solicitações conforme as regras de privacidade;
- o desenvolvedor confere nome, foto, e-mail institucional ativo e vínculo informado
  com a Fatec;
- a versão 2.0 guarda somente o resultado, administrador, data e observação da
  conferência, sem armazenar cópias de documentos;
- ao conceder ou remover o selo, o sistema registra o administrador responsável,
  a data e uma observação curta;
- documentos de verificação não serão armazenados dentro do painel nesta versão;
- recusar, pausar ou remover o selo exige motivo registrado e aviso à pessoa pelo
  chat oficial;
- o selo é pausado quando houver mudança de foto aguardando conferência e pode ser
  removido quando o vínculo ou a identidade não puderem mais ser confirmados;
- nenhuma dessas ações bloqueia automaticamente a conta, salvo decisão separada
  de moderação.

### US-ADM-04 — Operar a comunidade

Escopo confirmado:

- pesquisar pessoas, veículos e caronas;
- analisar alterações de nome de perfil e novas fotos de pessoas verificadas;
- abrir o histórico completo de um veículo, incluindo dados atuais, alterações,
  contas vinculadas, caronas anteriores, exclusão e arquivamento;
- analisar conflitos de placa e transferir o vínculo entre contas com motivo e
  registro de auditoria;
- consultar todos os cancelamentos e seus motivos;
- identificar frequência, antecedência e padrões de cancelamento por pessoa;
- consultar avaliações em estrelas, respostas de encerramento e problemas
  informados por motorista, passageiro e carona;
- consultar contestações de ausência pendentes;
- aplicar e remover o estado `USUÁRIO ADVERTIDO`, registrando o motivo;
- tornar uma advertência pública por período determinado e consultar seu vencimento;
- adicionar, organizar, ativar e remover figurinhas disponíveis no chat;
- consultar denúncias e bloqueios;
- suspender contas ou conteúdos;
- visualizar histórico de decisões administrativas;
- acompanhar indicadores gerais sem expor conversas privadas.

### US-ADM-05 — Iniciar uma conversa administrativa

**Como** administrador, **quero** iniciar uma conversa oficial com qualquer
pessoa, **para** orientar, solicitar esclarecimentos ou tratar ocorrências.

Requisitos confirmados:

- o administrador pode abrir uma conversa administrativa mesmo sem existir
  carona, proposta ou contato anterior com a pessoa;
- a conversa aparece automaticamente na lista de chats do destinatário;
- o administrador aparece com os selos `VERIFICADO` e `ADMIN`;
- a identificação administrativa deve ser clara para evitar golpes ou confusão
  com uma conversa comum;
- iniciar a conversa administrativa não adiciona silenciosamente o administrador
  a conversas privadas de caronas;
- o sistema registra qual administrador iniciou o contato e quando;
- a conta administrativa não pode ser bloqueada;
- o usuário não é obrigado a responder ou interagir com a conversa administrativa;
- o usuário pode silenciar e arquivar a conversa;
- uma nova mensagem administrativa permanece registrada e pode fazer a conversa
  voltar a aparecer na lista;
- nenhuma das partes pode apagar mensagens de uma conversa administrativa;
- remetente comum e administrador podem editar a própria mensagem somente durante
  o primeiro minuto depois do envio;
- durante esse minuto aparece a ação `EDITAR`;
- depois de um minuto, a ação desaparece e a mensagem se torna permanente;
- mensagens editadas são identificadas visualmente como editadas;
- o administrador não acessa chats privados livremente;
- quando há denúncia, o administrador vê exclusivamente as mensagens selecionadas
  e enviadas pela pessoa denunciante;
- todo acesso a uma denúncia fica registrado.

## 12. Experiência visual

### US-NAV-01 — Navegar pelo aplicativo mobile

**Como** usuário, **quero** acessar as áreas principais com poucos toques,
**para** encontrar, acompanhar ou criar uma carona sem me perder no aplicativo.

Requisitos confirmados:

- a barra inferior possui `INÍCIO`, `MINHAS CARONAS`, `CHATS` e `AJUSTES`;
- um botão central `+`, visualmente destacado, faz parte dessa navegação;
- tocar em `+` abre duas ações grandes e diretas: `OFERECER CARONA` e
  `PEDIR CARONA`;
- `MINHAS CARONAS` mostra um pequeno indicador quando existir solicitação,
  decisão, reconfirmação ou outra ação de carona ainda não vista;
- `CHATS` mostra um indicador quando existirem mensagens não visualizadas;
- o indicador possui design próprio coerente com a identidade do VaiJunto e pode
  usar uma animação breve e sutil ao receber uma nova pendência;
- quando houver pendências, o indicador mostra a quantidade até `9+`;
- o indicador não depende somente de cor, não ocupa espaço excessivo e não fica
  animando continuamente;
- quando um evento chegar com o aplicativo aberto, pode aparecer uma cápsula
  compacta no topo da tela, com ícone, uma linha de resumo e ação ao tocar;
- somente uma cápsula aparece por vez, sem empilhar cartões ou cobrir a navegação;
- a cápsula não aparece quando a pessoa já estiver visualizando a conversa ou a
  carona relacionada;
- a cápsula desaparece sozinha depois de poucos segundos, mas o evento continua
  acessível pelo indicador e pela área correspondente;
- a entrada usa animação leve e uma vibração curta, respeitando as configurações
  de vibração e redução de movimento do aparelho;
- ao entrar na área, visualizar o item e realizar a ação necessária, o indicador
  é atualizado ou removido;
- o indicador mostra a soma de itens não visualizados até `9+` e não tenta exibir
  contagens maiores na barra compacta.

- Toda a experiência do usuário comum é projetada primeiro para telas de celular.
- O painel administrativo é a única exceção: sua experiência é desktop-first e
  não precisa ser adaptada ou validada como uma interface móvel.
- O painel pode usar tabelas, colunas simultâneas, filtros persistentes e maior
  densidade de informação quando isso facilitar o trabalho administrativo.
- O espaço reduzido deve ser tratado com hierarquia clara, sem amontoar ações,
  textos ou informações secundárias na mesma tela.
- Cada etapa possui uma ação principal evidente e usa linguagem curta e direta.
- Informações avançadas aparecem progressivamente, somente quando forem necessárias.
- Ações secundárias ficam em menus, folhas inferiores ou áreas de detalhes, sem
  competir com aceitar, recusar, solicitar, publicar, iniciar e finalizar.
- Formulários longos são divididos em etapas curtas, mantendo o que já foi preenchido.
- Teclado, seletor de mídia e mapas não podem esconder a ação necessária para
  continuar ou confirmar.
- Botões e áreas de toque devem ser confortáveis para uso com uma mão e não depender
  de gestos ocultos como única forma de executar uma ação importante.
- Textos, estados vazios, erros e permissões explicam o próximo passo sem termos técnicos.
- Os fluxos principais precisam ser avaliados em aparelhos pequenos antes de
  qualquer história de interface chegar a `100%`.
- O aplicativo comum deve permanecer leve e utilizável em aparelhos modestos e
  conexões móveis lentas, considerando a realidade de uma faculdade pública.
- Listas, históricos e conversas carregam conteúdo gradualmente, sem tentar trazer
  todo o histórico de uma só vez.
- Fotos e vídeos usam miniaturas e compressão; o arquivo maior só é carregado
  quando necessário.
- Animações são curtas e simples, sem efeitos visuais pesados como requisito para
  entender ou usar uma função.
- Mapas, localização e mídia não devem impedir o restante do aplicativo de abrir
  e funcionar quando a conexão estiver instável.
- O portão de desempenho exige testar início do aplicativo, navegação, listas,
  chat, mapa e envio de mídia em pelo menos um aparelho modesto antes da entrega.
- Preservar o fluxo atual de oferta com poucas etapas.
- Cadastro de veículo separado em duas telas curtas.
- Usar cartões compactos para seleção, sem transformar a criação em formulário longo.
- Explicar limites e correções no momento em que acontecem.
- Manter a linguagem visual e os componentes definidos em `mobile/DESIGN.md`.
- Não mostrar estados internos ou termos técnicos aos usuários.
- A entrada administrativa no computador pode ter humor e personalidade, sem
  comprometer a clareza do acesso protegido.

## 13. Ordem inicial de implementação

1. consolidar todas as decisões de produto deste documento;
2. busca regional e endereços salvos;
3. veículos e área `MEUS VEÍCULOS`;
4. vínculo obrigatório entre veículo e oferta;
5. cálculo e limite da ajuda financeira;
6. lista principal, `MINHAS CARONAS`, pedido de vaga e estados de aceite/recusa;
7. filtros de recusa e bloqueio;
8. chat liberado após aceite;
9. painel administrativo e concessão do selo de verificação;
10. notificações dos eventos principais;
11. privacidade, segurança, denúncia e moderação;
12. validação dos fluxos em telas pequenas e ajustes de UX mobile;
13. validação de desempenho em aparelho modesto e conexão limitada;
14. testes completos da jornada;
15. revisão jurídica e de textos;
16. atualização final da versão para `2.0.0.0` e entrega.

Esta ordem pode ser ajustada durante a implementação quando uma dependência técnica
exigir, sem alterar os requisitos de produto sem registrar uma revisão neste documento.

## 14. Critérios de conclusão da versão 2.0.0.0

- Todas as user stories confirmadas possuem critérios de aceite fechados.
- Todos os fluxos do usuário comum foram validados em telas pequenas, com ações
  principais evidentes e sem conteúdo essencial escondido pelo teclado ou mapa.
- Os fluxos principais permanecem utilizáveis em aparelho modesto e conexão móvel
  limitada, sem travamentos causados por listas, mídia, mapas ou animações.
- A busca de endereço prioriza correspondências do Vale do Paraíba e permite
  ampliar conscientemente a pesquisa para fora da região.
- Nenhuma pessoa oferece carona sem veículo válido.
- Nenhuma oferta permite mais vagas que a capacidade do veículo.
- Ajuda financeira permanece opcional e nunca ultrapassa o limite calculado.
- Passageiros conseguem solicitar vaga e acompanhar a decisão.
- Motoristas conseguem aceitar ou recusar solicitações.
- Recusas e bloqueios alteram corretamente as listas exibidas.
- Chat comum só permite envio quando existe participação aceita ou proposta
  pendente prevista neste plano.
- Dados de motorista e veículo respeitam as decisões de privacidade.
- Painel administrativo exige permissão e permite gerenciar a verificação.
- Estados críticos geram notificações compreensíveis.
- Os fluxos funcionam em celular e web sem quebra visual.
- Migrações preservam os dados existentes.
- Testes automatizados e validação manual da jornada estão concluídos.
- Pendências jurídicas classificadas como obrigatórias estão resolvidas.
- Documentação do produto e do projeto está atualizada.

## 15. Ponto de partida da implementação

1. auditar o aplicativo e o serviço atuais contra cada user story;
2. atualizar `Progresso`, `Estado` e dependências com evidências do código existente;
3. identificar migrações necessárias sem apagar dados do MVP;
4. implementar por dependência, concluindo critérios e testes de cada história;
5. atualizar este documento junto de cada entrega, sem marcar `100%` antes dos testes;
6. executar os portões jurídico, de UX, desempenho e QA;
7. alterar a versão para `2.0.0.0` somente depois que todos os itens estiverem concluídos.
