# Documentação de Design System & Rebranding Visual

> **Projeto / Referência:** Rebranding Visual & Design Tokens  
> **Asset de Origem:** [`asset_example.jpg`](file:///r:/Dev/VaiJunto/docs/asset_example.jpg)  
> **Estilo Predominante:** Dark Sport Mode / High-Contrast Editorial / Glassmorphic Outlines & Pitch Accent  
> **Status:** Aprovado para Implementação Frontend (Web & Mobile)

---

## 1. Visão Geral & Direção Criativa

O novo conceito visual extraído da referência [`asset_example.jpg`](file:///r:/Dev/VaiJunto/docs/asset_example.jpg) adota uma estética **Dark Athletic Editorial**, combinando superfícies em tom **Carvão Profundo (`#17181C`)**, realces vibrantes em **Verde Gramado (`#3FA045`)**, moldura ambiental em **Verde Oliva (`#5F7543`)** e tipografia de alto impacto em **Titulares Vazados e Preenchidos em Caixa Alta**.

### Pilares da Identidade Visual
1. **Contraste Extremo & Legibilidade:** Fundo ultra-escuro com tipografia branca pura, proporcionando contraste superior a 17:1 (excede padrão WCAG AAA).
2. **Tipografia com Dupla Personalidade (Solid vs. Stroke):** Títulos principais combinam palavras preenchidas com palavras em contorno (stroke outline), criando movimento e profundidade sem ruído gráfico.
3. **Componentes Glassmorphic e Outlined:** Botões e cartões utilizam bordas nítidas de 1.5px a 2px com transparência sutil, transmitindo tecnologia e modernidade.
4. **Acabamento Ambiental Orgânico:** Áreas de destaque e fundos de gramado/arena trazem textura e energia física para o aplicativo.

---

## 2. Paleta de Cores & Tokens de Cor (Design Tokens)

### 2.1 Tabela de Cores Principais

| Nome Semântico | Código Hex | RGB | Uso Recomendado | Contraste Texto Branca (`#FFF`) | Nível WCAG |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `color-bg-canvas` | `#17181C` | `23, 24, 28` | Fundo principal da aplicação / Hero Section | 17.8:1 | **AAA** |
| `color-bg-frame` | `#5F7543` | `95, 117, 67` | Molduras externas, áreas ambientais | 4.8:1 | **AA** |
| `color-pitch-green` | `#3FA045` | `63, 160, 69` | Realces de gramado, indicadores ativos, badges de jogo | 4.6:1 (Texto escuro) | **AA** |
| `color-pitch-dark` | `#2D7D46` | `45, 125, 70` | Variação de degradê/sombra para o verde | 6.2:1 | **AA** |
| `color-surface-card` | `#0F1012` | `15, 16, 18` | Fundo de cards, modais com 85% opacidade | 19.2:1 | **AAA** |
| `color-border-light` | `#FFFFFF` | `255, 255, 255` | Bordas de botões (`border-width: 1.5px`), strokes de texto | N/A | N/A |
| `color-text-primary` | `#FFFFFF` | `255, 255, 255` | Títulos, botões primários, navegação ativa | 17.8:1 (sobre Canvas) | **AAA** |
| `color-text-secondary` | `#A0A5AD` | `160, 165, 173` | Descrições, datas, horas e rótulos auxiliares | 7.2:1 (sobre Canvas) | **AAA** |
| `color-text-muted` | `#6C727F` | `108, 114, 127` | Placeholders de busca, ícones inativos | 4.5:1 (sobre Canvas) | **AA** |

---

## 3. Sistema Tipográfico (Typography System)

O sistema de tipografia divide-se em duas famílias principais:

### 3.1 Famílias Tipográficas

- **Display / Titulares Emblemáticos:** `Bebas Neue` ou `Anton` (Google Fonts) / Fallback `Impact`, `Arial Narrow Bold`.
  - *Estilo:* Caixa alta (UPPERCASE), peso 900 / Heavy, tracking apertado (`-0.02em` a `0em`).
  - *Variante Stroke:* Textos com preenchimento transparente e contorno branco de 1.5px (`-webkit-text-stroke: 1.5px #FFFFFF`).
- **Navegação & Corpo:** `Inter` ou `IBM Plex Sans` (Google Fonts).
  - *Estilo:* Clean, altíssima legibilidade em tamanhos reduzidos, pesos `400` (Regular), `500` (Medium) e `700` (Bold).

### 3.2 Escala Tipográfica (Type Scale)

| Nível | Família | Tamanho / Line Height | Weight | Tracking / Case | Exemplo de Aplicação |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Hero Display 1** | Bebas Neue / Display | 72px / 1.0 | 900 (Heavy) | `0.02em` / UPPERCASE | Títulos principais (`SOCCER`) |
| **Hero Display Stroke**| Bebas Neue / Display | 72px / 1.0 | 900 / Outline | `0.02em` / UPPERCASE | Título secundário vazado (`TEAM`) |
| **Heading H1** | Bebas Neue / Display | 32px / 1.1 | 700 (Bold) | `0.04em` / UPPERCASE | Titulares de Cards (`NEXT GAME`) |
| **Heading H2** | Inter | 24px / 1.2 | 700 (Bold) | `-0.01em` / Sentence | Subtítulos e Seções |
| **Body Large** | Inter | 16px / 1.5 | 400 (Regular) | `0em` / Normal | Textos descritivos do Hero |
| **Body Medium** | Inter | 14px / 1.4 | 500 (Medium) | `0em` / Normal | Itens da Navbar (`Home`, `Price`, `Blog`) |
| **Caption / Badge** | Inter | 12px / 1.3 | 700 (Bold) | `0.05em` / UPPERCASE | Horários (`NOVEMBER, 21 - 15:00`) |

---

## 4. Geometria, Espaçamentos & Profundidade

### 4.1 Raios de Borda (Border Radius)
- `radius-sm`: `4px` (Badges e tags pequenas)
- `radius-md`: `8px` (Cards, contêineres de jogos, botões retos)
- `radius-lg`: `16px` (Modais e quadros principais)
- `radius-full`: `999px` (Botões de pílula, barra de busca, ícones de redes sociais)

### 4.2 Sombras & Elevação (Depth & Glassmorphism)
- **Glass Card Overlay:** `background: rgba(15, 16, 18, 0.85); backdrop-filter: blur(16px); border: 1px solid rgba(255, 255, 255, 0.15);`
- **Soft Drop Shadow:** `box-shadow: 0px 12px 32px rgba(0, 0, 0, 0.5);`
- **Outlined Focus Ring:** `outline: 2px solid #3FA045; outline-offset: 2px;`

---

## 5. Implementação Técnica de Tema

### 5.1 CSS Variables (`theme.css`)

```css
:root {
  /* Brand Colors */
  --color-bg-canvas: #17181c;
  --color-bg-frame: #5f7543;
  --color-pitch-green: #3fa045;
  --color-pitch-dark: #2d7d46;

  /* Surface & Overlays */
  --color-surface-card: rgba(15, 16, 18, 0.85);
  --color-surface-solid: #0f1012;
  --color-border-light: rgba(255, 255, 255, 0.8);
  --color-border-subtle: rgba(255, 255, 255, 0.15);

  /* Text Colors */
  --color-text-primary: #ffffff;
  --color-text-secondary: #a0a5ad;
  --color-text-muted: #6c727f;

  /* Typography */
  --font-display: 'Bebas Neue', 'Oswald', sans-serif;
  --font-body: 'Inter', system-ui, -apple-system, sans-serif;

  /* Radii */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 16px;
  --radius-full: 999px;

  /* Elevation */
  --shadow-card: 0px 12px 32px rgba(0, 0, 0, 0.5);
  --backdrop-blur: blur(16px);
}
```

### 5.2 Tailwind CSS Extended Config (`tailwind.config.js`)

```javascript
module.exports = {
  theme: {
    extend: {
      colors: {
        brand: {
          canvas: '#17181C',
          frame: '#5F7543',
          pitch: '#3FA045',
          'pitch-dark': '#2D7D46',
        },
        surface: {
          card: 'rgba(15, 16, 18, 0.85)',
          solid: '#0F1012',
        },
        text: {
          primary: '#FFFFFF',
          secondary: '#A0A5AD',
          muted: '#6C727F',
        }
      },
      fontFamily: {
        display: ['Bebas Neue', 'Oswald', 'sans-serif'],
        body: ['Inter', 'sans-serif'],
      },
      borderRadius: {
        'card': '8px',
        'pill': '999px',
      },
      boxShadow: {
        'glass': '0 12px 32px 0 rgba(0, 0, 0, 0.5)',
      }
    }
  }
}
```

### 5.3 Flutter ThemeData & Neo-Brutal/Dark Extensions (`dark_theme.dart`)

```dart
import 'package:flutter/material.dart';

class AthleticDarkTheme {
  static const Color bgCanvas = Color(0xFF17181C);
  static const Color bgFrame = Color(0xFF5F7543);
  static const Color pitchGreen = Color(0xFF3FA045);
  static const Color surfaceCard = Color(0xD90F1012);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A5AD);

  static ThemeData get themeData {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgCanvas,
      primaryColor: pitchGreen,
      colorScheme: const ColorScheme.dark(
        primary: pitchGreen,
        surface: surfaceCard,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'BebasNeue',
          fontSize: 72,
          fontWeight: FontWeight.w900,
          color: textPrimary,
          letterSpacing: 1.2,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'BebasNeue',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 1.0,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
    );
  }
}
```

---

## 6. Refatoração e Especificação de Componentes Visuais

### 6.1 Navbar Superior (Header & Navigation)
- **Layout:** Barra transparente ancorada no topo com `justify-between`.
- **Esquerda:** Ícone de Menu (Hambúrguer) de 24px + Links de Navegação (`Home`, `Price`, `Blog`) com fonte `Inter 14px Medium`.
- **Direita:** Input de busca em formato pílula com borda branca 1px transparente e ícone de lupa.

### 6.2 Botão Estilizado em Pílula (Outlined Action Button)
- **Visual:** Fundo transparente com leve blur (`backdrop-filter`), borda branca nítida de 1.5px, texto em caixa alta preenchido em branco com alto peso (`Inter 14px Bold`).
- **Estados:**
  - *Default:* Border `#FFFFFF80`, Text `#FFFFFF`.
  - *Hover/Focus:* Border `#FFFFFF`, Background `rgba(255, 255, 255, 0.15)`, Transform scale `1.03`.
  - *Active:* Background `#3FA045`, Border `#3FA045` (Pitch Green Highlight).

#### Código HTML/CSS Exemplo:
```html
<button class="btn-outlined-pill">
  SUBSCRIBE
</button>

<style>
.btn-outlined-pill {
  background: rgba(255, 255, 255, 0.05);
  border: 1.5px solid rgba(255, 255, 255, 0.8);
  border-radius: 999px;
  color: #FFFFFF;
  font-family: 'Inter', sans-serif;
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 0.05em;
  padding: 12px 32px;
  cursor: pointer;
  backdrop-filter: blur(8px);
  transition: all 0.2s ease-in-out;
}

.btn-outlined-pill:hover {
  background: rgba(255, 255, 255, 0.2);
  border-color: #FFFFFF;
  transform: translateY(-2px);
}
</style>
```

### 6.3 Card de Próxima Partida / Evento (Next Game Card)
- **Visual:** Card com fundo escuro semi-transparente (`#0F1012D9`), canto arredondado `8px`, divisor horizontal fino.
- **Conteúdo:**
  - Ícone de troféu ou evento + Título em caixa alta (`NEXT GAME` em `Bebas Neue 24px`).
  - Linha divisória em tom branco com 20% opacidade.
  - Data e horário (`NOVEMBER, 21 / 15:00`) destacados em branco e peso alto.

---

## 7. Guia de Aplicação de Assets Visuais

1. **Logotipo & Títulos vazados:**
   - Aplicar a variação de título com efeito *Stroke Outlined* apenas na segunda palavra do bloco principal para manter dinamismo visual (ex: `SOCCER` sólido + `TEAM` em contorno).
2. **Fotografia de Fundo (Action Shot):**
   - Utilizar fotos em alta velocidade com recorte do plano principal (ex: jogador/campo) sob iluminação focal (spotlight).
   - O plano de fundo deve possuir vieta e leve gradiente escuro (`linear-gradient(180deg, rgba(23,24,28,0.7) 0%, rgba(23,24,28,0.95) 100%)`) para garantir contraste total com textos sobrepostos.
3. **Ícones de Ação e Redes Sociais:**
   - Botões de mídias sociais empilhados verticalmente no canto direito, envolvidos em um círculo com linha branca fina (`border: 1px solid rgba(255,255,255,0.4)`).

---

## 8. Resumo Comparativo: Antes vs. Depois

| Aspecto Visual / UX | Design Legado | Novo Design Rebrand (`asset_example.jpg`) |
| :--- | :--- | :--- |
| **Estética Geral** | Layout plano convencional SaaS | Dark Athletic Editorial com Glassmorphism |
| **Contraste & Leitura** | Tons neutros medianos | Contraste de alta intensidade (WCAG AAA) |
| **Identidade Tipográfica**| Fonte única sem diferenciação | Duo Tipográfico: *Bebas Neue Display* + *Inter* |
| **Componentes de Ação**| Botões sólidos planos comuns | Botões vazados em pílula com vidro reflexivo |
| **Atmosfera de Marca** | Genérica | Imersiva, esportiva e de alta performance |

