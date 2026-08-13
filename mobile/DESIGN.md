# VaiJunto — Design System

> Referência obrigatória antes de criar ou alterar qualquer tela/widget visual
> do app mobile. Se uma mudança de UI não se encaixa nas regras daqui, ou a
> regra está errada (avise e ajuste este arquivo), ou o componente novo está
> quebrando o sistema — não crie uma exceção silenciosa.

## Estilo: neobrutalismo + futurismo + street art

- **Neobrutalismo**: blocos sólidos, borda grossa preta, sombra dura
  deslocada (nunca `blurRadius` — sombra é sempre sólida), cantos discretos
  (nunca totalmente quadrados, nunca muito arredondados).
- **Futurismo**: cores neon saturadas em blocos sólidos, nunca gradiente
  suave.
- **Street art**: rotação leve tipo "adesivo colado torto" em elementos de
  destaque (logo, cards de destaque, badges) — nunca em botões de ação,
  inputs ou listas (ficaria ilegível/incômodo).

## A regra mais importante: só 2 cores de marca

O erro da primeira versão deste tema foi usar 4 neons (amarelo, rosa, ciano,
lima) todos competindo ao mesmo tempo, sem hierarquia — cada tela parecia
usar uma paleta diferente. A correção:

**Cada cor tem UM papel fixo em todo o app. Nunca use uma cor fora do papel
dela, e nunca combine mais de 2 cores de acento no mesmo componente.**

| Papel | Cor | Quando usar |
|---|---|---|
| **Primary** (ação) | Rosa `#FF3EA5` | TODO botão de ação principal (CTA) — Entrar, Criar conta, Confirmar, Publicar pedido, Publicar rota. Ícones de destaque isolados (ex: ícone de e-mail na tela de verificação, pin do autocomplete). Avatar/círculo de identidade do usuário. |
| **Secondary** (seleção/destaque) | Amarelo `#FFDE2D` | Estado selecionado/ativo (segmented button, toggle, badge de tag como "Motorista"). **Nunca** em botão de ação — se um botão amarelo e um rosa aparecem na mesma tela como CTA, alguém vai achar que são duas ações de peso diferente sem motivo. |
| Info (semântico) | Ciano `#00E5FF` | Só em snackbar/aviso informativo. Não é decoração — se você quer uma cor pra um card ou ícone, é rosa ou amarelo, nunca ciano. |
| Success (semântico) | Lima `#B6FF3B` | Só em snackbar de sucesso. |
| Error (semântico) | Vermelho `#FF3B3B` | Só em snackbar/borda de erro de validação. |

Botão secundário/outline (ação de menos peso, ex: "Criar conta grátis" ao
lado de "Entrar") não usa cor de acento — é `surface` (branco/superfície)
com borda preta, mesmo tratamento visual, sem competir com o CTA primário.

### Base (papel/tinta) — muda entre claro/escuro

| Token | Claro | Escuro |
|---|---|---|
| `paper` (fundo do scaffold) | `#FBF6E9` (creme) | `#15131C` |
| `surface` (cards, inputs, botão outline) | `#FFFFFF` | `#201D29` |
| `ink` (borda, texto, sombra) | `#111014` | `#F4F0E6` |

`ink` **não é preto fixo** — é `ColorScheme.ink` (extensão em
`neo_brutal_theme.dart`), que vira quase-branco no tema escuro. Toda borda e
sombra usa isso, nunca `Colors.black` direto, senão some no dark mode.

## Regras de construção

- **Borda**: sempre `NeoBrutal.borderWidth` (3px), cor `scheme.ink`.
- **Sombra**: sempre sólida (`blurRadius: 0`), deslocada
  `NeoBrutal.shadowOffset` (5,5) em blocos grandes ou
  `shadowOffsetSmall` (3,3) em badges/elementos pequenos. Nunca sombra suave
  do Material (`elevation`).
- **Raio de canto**: `NeoBrutal.borderRadius` (10) em cards/inputs/botões;
  `999` (pílula) em badges e avatares circulares.
- **Texto sobre bloco de cor**: sempre `scheme.ink` do tema atual — nunca
  branco/preto fixo (quebra no dark mode) e nunca calculado por contraste
  manual. Exceção: o avatar circular na Home usa branco fixo porque o fundo
  (`primary`/rosa) não muda de tom entre os temas.
- **Rotação "adesivo"**: entre `-0.06` e `-0.01` radianos, só em
  `NeoCard`/`NeoBadge`/logo. Nunca em `NeoButton`, `TextFormField` ou listas
  (autocomplete, etc.) — precisam ficar retos pra continuar legíveis e
  fáceis de tocar.
- **Tipografia**: títulos e labels de destaque em `FontWeight.w800`/`w900`,
  texto de botão sempre maiúsculo. Corpo de texto pode ser `w500`/`w600`
  (ver `textTheme` em `neo_brutal_theme.dart`).

## Componentes prontos (usar estes, não recriar do zero)

Tudo em `lib/core/ui/` e `lib/core/theme/neo_brutal_theme.dart`:

- **`NeoButton`** (`neo_button.dart`) — botão de ação. Sem `color` explícito
  usa `primary` (rosa) por padrão — é o que garante que todo CTA do app
  tenha a mesma cor. Só passe `color` pra um estado *não-CTA* (ex: toggle
  selecionado usando `secondary`).
- **`NeoOutlineButton`** — variante de menos peso (fundo `surface`).
- **`NeoCard`** (`neo_card.dart`) — bloco padrão com borda+sombra. Aceita
  `rotation` pro efeito adesivo.
- **`NeoBadge`** — selo pequeno (pílula), mesmo tratamento.
- **`NeoAvatar`** (`neo_avatar.dart`) — círculo de iniciais (1 ou 2 letras
  do nome, sem depender de foto). Usado no navbar; tocar nele é o padrão
  do app pra abrir dados da conta/logout — não criar um botão de "sair"
  solto e desconectado da identidade do usuário em outro canto da tela.
- **`NeoBrutal.decoration(...)`** — quando nenhum dos widgets acima serve
  (ex: avatar circular), monta a `BoxDecoration` manualmente com essa
  função em vez de escrever borda/sombra à mão.
- **`ColorScheme.ink`** (extensão) — sempre usar em vez de preto/branco
  fixo pra borda/texto/sombra.

## Checklist antes de adicionar UI nova

1. O botão de ação principal da tela usa `NeoButton` sem `color` (rosa
   por padrão)? Se você está passando uma cor pro CTA principal, pare — é
   sinal de que o padrão não está sendo seguido.
2. Alguma cor de acento (rosa/amarelo/ciano/lima) está sendo usada fora do
   papel dela na tabela acima?
3. Tem mais de 2 cores de acento (rosa+amarelo) aparecendo juntas no mesmo
   card/seção? Se sim, simplifique.
4. Sombra tem `blurRadius` maior que 0, ou borda mais fina que 3px? Corrija.
5. Rotação "adesivo" foi usada num botão, input ou item de lista? Remova —
   é só pra elementos de destaque estáticos.

## Onde mexer se a paleta mudar

Tudo fica em `lib/core/theme/neo_brutal_theme.dart` (classe `NeoBrutal` +
`buildNeoBrutalTheme`). Trocar uma cor ali propaga pro app inteiro — não
existe cor de acento hardcoded fora desse arquivo (se encontrar uma, é bug,
mova pra lá).
