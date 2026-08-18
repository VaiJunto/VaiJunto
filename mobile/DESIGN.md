# VaiJunto — Design System

> Referência obrigatória antes de criar ou alterar qualquer tela/widget visual.
> O objetivo não é parecer um app Material com borda preta. O VaiJunto deve ser
> reconhecível sem o logo: uma interface de mobilidade universitária urbana,
> física, barulhenta e organizada como um mapa anotado por quem vive a cidade.

## 1. Direção criativa: urban mobility ops

O estilo combina **neobrutalismo físico**, **street zine** e **interface de
operação urbana**. A energia pode lembrar interfaces hacktivistas e grafitadas
de jogos como Watch Dogs 2, mas sem copiar logos, personagens, ícones, layouts
ou assets. A identidade própria vem do vocabulário de caronas: rota, encontro,
campus, horário, origem e destino.

Três ideias precisam aparecer juntas:

1. **Blocos físicos** — toda área interativa importante parece uma peça colada
   sobre o papel: borda de 3 px, sombra sólida e deslocamento ao pressionar.
2. **Mapa anotado** — linhas tracejadas, nós de rota, coordenadas, marcas de
   corte e pequenos códigos criam a sensação de planejamento em movimento.
3. **Sistema clandestino organizado** — títulos fortes convivem com metadados
   monoespaçados como `VJ//RIDE_REQUEST`, `01`, `STATUS: EM BREVE`.

Se a tela parece um dashboard SaaS, um app bancário ou Material 3 padrão, ela
está errada mesmo que use magenta e ultravioleta.

### Arquitetura e UX: reconhecimento antes de memória

- A primeira aba é `CARONAS`: o usuário entra para encontrar uma solução, não
  para preencher um formulário.
- `CARONAS` contém duas visualizações no mesmo lugar: ofertas disponíveis e
  pedidos de passageiros. A troca usa um controle segmentado com linguagem
  explícita, nunca ícones sem texto.
- `CRIAR` contém os modos `OFERECER CARONA` e `PEDIR CARONA`. Eles não viram
  abas globais porque são variações da mesma intenção: publicar.
- Cada publicação tem no máximo duas etapas: `ROTA` e `DETALHES`. Mostrar tudo
  de uma vez aumenta carga cognitiva e empurra o CTA para fora da tela.
- Após publicar, voltar automaticamente para `CARONAS` e atualizar a lista. O
  sistema confirma o resultado em vez de deixar o usuário adivinhar onde foi.
- Usar verbos concretos (`OFERECER CARONA`, `PEDIR CARONA`, `PUBLICAR`) e uma
  decisão principal por viewport. Nunca depender de o usuário conhecer termos
  internos como oferta, demanda ou instância de viagem.

## 2. Assinaturas visuais obrigatórias

Cada tela principal deve usar pelo menos três destas assinaturas; a navbar usa
as cinco primeiras:

- bloco com borda grossa e sombra dura;
- código operacional curto em fonte monoespaçada (`VJ//...`);
- título em caixa alta, peso 900 e espaçamento apertado;
- número de seção/aba (`01`, `02`, `03`, `04`);
- estado ativo ultravioleta com uma barra/tique branco;
- linha de rota tracejada ou nós origem → destino;
- leve sobreposição/rotação de adesivo em conteúdo estático;
- marca de corte, cruz ou grid técnico discreto no papel;
- microtexto funcional como `ROTA • HORÁRIO • ENCONTRO`.

Esses elementos devem comunicar estrutura. Glitch aleatório, ruído, rabisco e
decoração sem significado viram fantasia visual e não devem ser usados.

## 3. Paleta: só duas cores de marca

Cada cor tem papel fixo. O sistema é mais colorido que o cyberpunk tradicional,
mas cada componente usa no máximo duas cores de acento para preservar hierarquia.

| Papel | Cor | Uso |
|---|---|---|
| **Primary / sinal de ação** | Magenta `#D91568` | CTA principal, avatar e bloco isolado de ícone que identifica a ação da tela. Texto branco. Não usar como fundo decorativo grande. |
| **Secondary / seleção** | Ultravioleta `#5146D8` | Aba ativa, toggle selecionado, etiqueta de perfil/status e fita de destaque. Texto branco. Nunca compete com um CTA magenta. |
| **Signal / HUD** | Ciano `#00B8D9` | Linhas de rota, coordenadas, códigos operacionais e feedback informativo. Nunca CTA. |
| Success | Lima `#B6FF3B` | Somente feedback de sucesso. |
| Error | Vermelho `#FF3B3B` | Somente erro e validação. |

### Base papel/tinta

| Token | Claro | Escuro |
|---|---|---|
| `paper` | `#F3F0E8` | `#0E0D14` |
| `surface` | `#FFFFFF` | `#1A1723` |
| `ink` | `#111014` | `#F4F0E6` |

`ink` nunca é `Colors.black` fixo. Toda borda, sombra, ícone estrutural e linha
de rota usa `ColorScheme.ink`.

## 4. Tipografia com dois registros

### Voz humana

- Família: **IBM Plex Sans**, escolhida pela construção técnica/editorial sem
  perder legibilidade em corpo pequeno.
- Títulos: caixa alta, `w900`, tracking entre `-0.6` e `0`.
- Botões: caixa alta, `w900`, tracking entre `0.3` e `0.6`.
- Corpo: `w500`/`w600`, frase normal e leitura confortável.
- Nada de títulos leves, cinza claro ou centralização excessiva.

### Voz do sistema

- Família: **IBM Plex Mono**.
- Códigos, números de aba, horários compactos e metadados usam
  `fontFamily: 'monospace'`, caixa alta, `w700`, 9–12 px.
- Microtexto nunca substitui a informação humana. Ele funciona como camada de
  identidade: `PEDIR CARONA` continua legível; `VJ//RIDE_REQUEST` é apoio.
- Não usar “lorem hacker”, hexadecimais aleatórios ou termos técnicos falsos.

## 5. Geometria e profundidade

- **Borda:** `NeoBrutal.borderWidth` (3 px).
- **Sombra grande:** `NeoBrutal.shadowOffset` (5,5), sempre `blurRadius: 0`.
- **Sombra pequena:** `shadowOffsetSmall` (3,3), em navbar, badges e ícones.
- **Raio:** 5 px. Pílulas e avatar usam 999. Cantos mais retos dão caráter digital e editorial.
- **Grid:** espaçamento base de 4 px; distâncias preferenciais 8, 12, 16, 24,
  32. Evitar valores aleatórios.
- **Rotação adesivo:** `-0.015` a `-0.04` radianos em cards estáticos. Nunca em
  inputs, listas, botões ou itens da navbar.
- **Camadas:** no máximo uma sombra grande e uma pequena aninhada. Três caixas
  com sombra dentro de outra caixa viram ruído.

## 6. Movimento e resposta tátil

- Botão pressionado desloca exatamente até a sombra e perde a sombra em 80 ms.
- Sem ripple Material, sem bounce macio e sem animação flutuante.
- Troca de seleção pode durar 120–160 ms; a geometria não deve “dançar”.
- Loading fica dentro do bloco que iniciou a ação.
- Respeitar áreas de toque mínimas de 48 px.

### Mapa vivo, não papel de parede

- Grandes vazios nunca recebem uma cor lisa sem contexto. Usar o
  `NeoStreetBackdrop` com rota pontilhada, grid técnico e microdados nas bordas.
- O pontilhado corre lentamente na direção da rota; um pacote magenta percorre
  o traçado e os nós ciano respiram. A animação ambiental completa um ciclo em
  12 s ou mais e nunca pisca.
- Todo valor animado precisa fechar o ciclo: fase do tracejado, deslocamento do
  grid e pulso devem ter o mesmo frame em `0` e `1`. Marcadores de rotas abertas
  iniciam e terminam fora da viewport para a troca de lado ficar invisível.
- O conteúdo permanece estático. Cards, inputs, títulos e CTA não flutuam junto
  com o fundo; isso preserva leitura, foco e a sensação física neobrutalista.
- Movimento comunica estado: o pacote significa busca/deslocamento, os nós
  significam pontos de encontro e as células significam sincronização.
- Respeitar `MediaQuery.disableAnimations`. Nesse caso o mapa mantém uma pose
  legível, sem deslocamento, e nenhum fluxo perde informação.
- Nunca usar scanline sobre texto, glitch contínuo, ruído aleatório, glow ou
  partículas. A interface deve parecer viva, não defeituosa.

### Corrida geométrica (só painel administrativo)

- `NeoGeometryRunBackdrop` ocupa a faixa vazia do cabeçalho do painel de
  operações, entre o título e os botões de ação. É o único lugar com movimento
  contínuo grande, e fica sempre dentro de uma caixa com borda — nunca atrás
  de texto, lista ou da tela inteira.
- O percurso não é um loop: cada obstáculo vem de um hash do índice do bloco,
  que só cresce. Não há frame de emenda porque nada volta ao início — em 15
  minutos passam ~2.750 blocos sem repetir trecho.
- O salto é analítico (janela fixa de decolagem/pouso por obstáculo), então o
  cubo passa limpo em qualquer taxa de quadros e a pose congelada continua
  coerente. Nada de física simulada nem de valor aleatório em tempo de execução.
- Vocabulário: quadrado magenta correndo, picos ciano, blocos de tinta e
  torres de fundo em parallax. Sem gradiente, sem brilho, sem partícula.
- Fica sempre atrás: alfa máximo ~0,35, ancorado na base da área, e as linhas
  da lista permanecem opacas por cima. Título e descrição da seção ficam fora
  do card, sobre fundo limpo.
- `MediaQuery.disableAnimations` congela o percurso em um trecho legível.

### Loading próprio

- Não usar `CircularProgressIndicator` como linguagem principal do produto.
- A splash usa um painel `VJ//LOCAL_BOOT`, células sólidas em sequência e uma
  frase humana sobre o que está ocorrendo (`RECUPERANDO SUA ROTA`).
- Loadings de ação ficam dentro do botão que os iniciou. Loadings de conteúdo
  aparecem em um bloco físico curto, sem deslocar a estrutura da tela.

## 7. Anatomia das telas

### Cabeçalho global

- Símbolo adesivado ultravioleta à esquerda.
- Título humano em caixa alta.
- Código operacional monoespaçado logo abaixo (`VJ//RIDES`).
- Avatar magenta à direita abre Ajustes.
- Linha inferior grossa separa o sistema do conteúdo.

### Introdução de fluxo

- `NeoCard` pode ser levemente rotacionado apenas em estados vazios e destaques; formulários ficam retos e compactos.
- Bloco de ícone magenta isolado.
- Badge ultravioleta identifica perfil ou estado.
- Título direto e uma frase que explique a ação.
- Pode incluir microlegenda de etapas: `ROTA • HORÁRIO • ENCONTRO`.

### Formulários

- Seções têm títulos fortes e linguagem natural.
- Inputs continuam retos, brancos/surface, borda de 3 px.
- Seleção de direção usa ultravioleta apenas no lado ativo.
- Um CTA magenta por tela. Ações menores usam `NeoOutlineButton`.

### Autenticação

- Autenticação é uma passagem, não uma tela de exploração. A prioridade absoluta
  é concluir a tarefa e sair: marca compacta, título curto, campos e CTA.
- Login e cadastro compartilham o `NeoAuthBackdrop`: base mais escura que o app,
  um scanner diagonal de 14 s e uma única linha de sinal quase apagada. O fundo
  dá vida sem simular mapa, coordenadas, nós, textos ou múltiplos objetos.
- Login contém e-mail, senha, `ENTRAR` e um botão secundário claramente clicável
  para criar conta. O secundário tem contorno, mas só o CTA principal é magenta.
- O login cabe em 390 × 844 px sem exigir rolagem para encontrar `ENTRAR` ou
  `CRIAR CONTA`. Evitar glitch em títulos, status fictício e caixas aninhadas.
- Cadastro com apenas nome, e-mail e senha usa uma única tela. Paginação só é
  permitida quando existirem cinco ou mais campos ou decisões realmente distintas.
- O CTA do cadastro permanece fixo e visível. Requisitos de senha usam um painel
  compacto com barra de força, estado verbal e quatro critérios em duas colunas;
  o feedback aparece durante a digitação e nunca vira uma etapa inteira.
- A versão permanece no rodapé fixo das duas telas, separada do conteúdo rolável.
- Tipo de transporte não pertence ao cadastro da pessoa. Qualquer conta pode
  pedir ou oferecer; características como van/fretado pertencem à publicação.
- Confirmação de e-mail mostra endereço, estado do envio e campo de seis dígitos
  no mesmo bloco. Reenvio é ação secundária e expõe o cooldown claramente.
- A camada futurista fica em identificadores decorativos como
  `VJ//EMAIL_HANDSHAKE`. Títulos, estados, campos e ações sempre usam o nome
  literal da tarefa, como `Confirme o código`, `CÓDIGO ENVIADO` e
  `CONFIRMAR CÓDIGO`, sem transformar funções reais em roleplay.
- E-mails transacionais seguem a mesma hierarquia: papel claro, tinta escura,
  blocos físicos, magenta para a ação e códigos operacionais em ciano. O código
  de confirmação é o maior elemento da mensagem e mantém contraste alto.
- A temática pode usar formato de comprovante, rota e metadados funcionais, mas
  nunca depende de GIF, imagem externa, emoji ou animação para comunicar. Corpo
  em 16 px ou mais, instrução literal e validade visível preservam a leitura em
  telas pequenas e para pessoas com baixa visão.

### Estados vazios

- Um estado vazio informa três coisas, nesta ordem: resultado da busca (`0
  ROTAS`), significado humano (`NENHUMA CARONA AGORA`) e próximo passo com CTA.
- O card fica compacto e ligeiramente acima do centro. O mapa vivo e o status
  de atualização ocupam o vazio; não adicionar ilustrações grandes ou mais
  escolhas apenas para preencher espaço.
- Estados vazios devem oferecer a ação mais útil, não culpar o usuário e não
  prometer dados inexistentes.

### Carona fixa

- O controle `CARONA FIXA` aparece somente em `CRIAR > OFERECER > DETALHES`.
- É indicado para van, fretado ou rota realmente repetida. Quando ativo, a
  publicação continua no feed depois do horário de saída até ser cancelada.
- No feed, usar badge `FIXA` e mostrar `FIXA • HH:MM`; nunca exibir uma data
  antiga como se fosse uma viagem única ainda futura.
- Não perguntar no cadastro se a pessoa é motorista de van. A recorrência é
  propriedade da carona, não uma identidade permanente do usuário.

### Navbar de rodapé

- Quatro destinos: `CARONAS`, `CRIAR`, `CHAT`, `AJUSTES`.
- O rodapé é uma barra única com divisões internas para reduzir altura e ruído; o destino ativo recebe bloco ultravioleta.
- Cada bloco mostra número `01–04`, ícone e label curto.
- Aba ativa: fundo ultravioleta + texto branco + tique/barra branca.
- Abas inativas: `surface`, com texto `ink`.
- Pressionar achata o bloco como `NeoButton`.
- Ordem padrão: `CARONAS`, `CRIAR`, `CHAT`, `AJUSTES`.

### Regra de altura e rolagem

- A ação principal e os controles essenciais devem caber na primeira viewport de 390 × 844 px.
- Formulários longos viram etapas curtas; nunca empilhar todos os campos por conveniência de implementação.
- Rolagem é fallback para teclado, acessibilidade e telas menores, não requisito para descobrir o CTA.
- Listas naturalmente rolam; telas de ação não devem exigir rolagem antes da primeira decisão.

### Estados futuros

- A área é clicável e abre uma tela real, nunca um snackbar solto.
- Usar badge ultravioleta `EM DESENVOLVIMENTO` ou `EM BREVE`.
- Explicar em uma frase o valor futuro, sem simular dados ou ações falsas.

## 8. Componentes oficiais

Reutilizar antes de desenhar algo novo:

- `NeoButton` / `NeoOutlineButton` — ações físicas com estado pressionado.
- `NeoCard` / `NeoBadge` — superfície e etiqueta.
- `NeoAvatar` — identidade e acesso à conta.
- `NeoBottomNavBar` — navegação principal em quatro blocos.
- `NeoFlowHeader` / `NeoRouteReview` — etapas curtas dos fluxos de publicação.
- `NeoStreetBackdrop` — grid técnico discreto atrás da área autenticada.
- `NeoAuthBackdrop` — scanner lento e escuro exclusivo da autenticação.
- `NeoGeometryRunBackdrop` — corrida geométrica infinita na faixa do cabeçalho
  do painel administrativo.
- `AuthVisualShell` — estrutura de confirmação de e-mail e fluxos auxiliares.
- `NeoLoadingIndicator` / `NeoBootRail` — loading em células e boot da sessão.
- `NeoBrutal.decoration(...)` — única forma de criar borda+sombra manual.
- `ColorScheme.ink` — única tinta estrutural.

## 9. Padrões proibidos

- `NavigationBar`/`BottomNavigationBar` padrão do Material.
- Ícone solto com label cinza no rodapé.
- Card branco sem borda ou com sombra suave.
- Gradiente, glassmorphism, blur, elevation Material ou glow neon.
- Vários cards centralizados com muito espaço vazio, estilo landing page.
- Arredondamento “fofo” acima de 10 px fora de badges/avatares.
- Magenta e ultravioleta usados apenas como decoração sem papel semântico.
- Ciano/lima como decoração.
- Glitch ilegível, scanline constante ou animação que prejudica leitura.
- Copiar interface, logo, grafite ou composição de outra marca/jogo.

## 10. Checklist de revisão sênior

1. A tela ainda seria reconhecível como VaiJunto sem o logo?
2. Existe hierarquia clara entre voz humana e voz do sistema?
3. Todos os elementos clicáveis importantes parecem blocos físicos?
4. O ultravioleta indica seleção/status e o magenta indica ação/identidade?
5. Há um CTA magenta inequívoco e no máximo um por seção?
6. A composição tem algum elemento de mapa/rota, sem virar decoração vazia?
7. Inputs, listas e botões permanecem retos e legíveis?
8. Dark mode preserva bordas usando `scheme.ink`?
9. A tela evita componentes Material reconhecíveis sem customização?
10. O resultado parece uma ferramenta urbana viva, não um template?

## 11. Ícone do launcher

O ícone é a única superfície onde o neobrutalismo **não** manda: a forma é do
sistema operacional, não nossa.

No Android o ícone é adaptativo. O canvas tem 108dp, o aparelho mostra apenas os
**72dp centrais** (raio 36dp) e recorta com a máscara dele — squircle no One UI
(S23), círculo no Pixel, gota em outros. O cartão neobrutal existe, mas tem que
caber inteiro dentro desses 72dp:

1. **Fundo** (`@color/ic_launcher_background`) é tinta `#0E0D14`. Não é
   decoração: é o que sobra na borda da máscara e completa o contorno.
2. **Primeiro plano** (`ic_launcher_foreground`) traz o cartão completo —
   contorno preto de **4dp uniforme**, face ultravioleta de raio 32dp (89% do
   visível) centrada em (54,54), marca ocupando 2/3 da face.
3. **Monocromático** (`ic_launcher_monochrome`) é só a silhueta da marca em
   branco, 48dp, para o ícone temático do One UI 5+/Material You. Sem cartão:
   ali o corpo do ícone é o próprio recorte do sistema.

**Aqui não tem sombra dura.** Dentro de 72dp não sobra espaço para deslocar o
cartão sem que a faixa escura pare de ler como sombra e passe a ler como moldura
torta — foi testado no aparelho e não funcionou. A assinatura no launcher é o
contorno, e ele é igual nos quatro lados. Sombra dura fica nas telas do app e nas
peças de apresentação, onde a forma é nossa.

Três armadilhas, as três já pagas neste projeto:

- **Centro errado.** A face é concêntrica com a máscara, em (54,54). Centrar em
  52 "de olho" produz uma moldura escura em L que parece defeito.
- **Expoente chutado.** A máscara do One UI é superelipse de expoente **2,75** —
  medido, não estimado: recortei o ícone do Nubank da gaveta do S23 (roxo chapado
  full-bleed, logo a silhueta dele é a própria máscara) e ajustei por mínimos
  quadrados, erro rms de 0,32px. Com o palpite anterior de 4,2 a face esticava
  86,7px na diagonal contra 86,9px da máscara: **o contorno sumia nos quatro
  cantos.** Contorno e face são duas superelipses concêntricas de mesmo expoente,
  o que mantém a espessura constante (varia 10% entre lado e diagonal).
- **Antialias como rampa algébrica.** O valor de `|x/R|^p + |y/R|^p − 1` não
  serve como borda: o gradiente dele varia em volta da curva, então a borda sai
  fina nos lados e esfumada nas diagonais — lê como brilho. Dividir por `|grad|`
  converte em distância real, e a rampa passa a ter largura fixa (`FEATHER_PX`,
  1,25px) em toda a volta. Neobrutalismo não tem borda esfumada.

Não usar `MaxFilter` para o contorno: elemento quadrado engrossa o traço em 41%
nas diagonais, exatamente onde ele precisa ser honesto.

Compromisso conhecido: com a curvatura casada ao One UI, a face chega perto da
borda nas diagonais quando a máscara é circular (Pixel), e ali o contorno afina.
Aceitável — a calibragem é para o S23.

O PNG legado de API 24–25 usa o mesmo desenho em escala maior, onde a forma é
nossa. As peças de apresentação (`assets/branding/app_icon_squircle.png` e
companhia) mantêm contorno **e** sombra dura, porque nelas nada recorta.

Tudo é gerado por `python mobile/assets/branding/gen_icons.py`, que também
reescreve a prova visual `app_icon_s23_adaptive_preview.png`. A marca vem de
`app_icon_mark.png`; não editar os mipmaps à mão.

## 12. Onde alterar tokens

Paleta, bordas, sombras e tema ficam em
`lib/core/theme/neo_brutal_theme.dart`. Uma nova assinatura visual recorrente
deve virar componente em `lib/core/ui/`; não repetir implementação por tela.
