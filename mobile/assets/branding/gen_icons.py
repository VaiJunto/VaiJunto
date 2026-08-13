"""Gera a arte do icone VaiJunto e as camadas que o Android consome.

Duas partes independentes:

1. PRANCHA — as pecas de apresentacao (`app_icon_squircle/circle/teardrop.png`).
   Cartao completo com contorno e sombra dura, do jeito aprovado. Servem para
   loja, README e mockup; nao vao para o launcher.

2. ANDROID — as camadas do icone adaptativo. Aqui a geometria e do launcher, nao
   nossa: o canvas tem 108dp, o aparelho mostra so os 72dp centrais e recorta com
   a propria mascara (squircle no One UI do S23, circulo no Pixel). Por isso o
   fundo e roxo chapado de borda a borda e o primeiro plano tem SO a marca. Se o
   PNG trouxesse o cartao desenhado, a mascara do aparelho cortaria por fora dele
   e sobraria uma moldura escura em L — era exatamente o defeito anterior.

    python mobile/assets/branding/gen_icons.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont


HERE = Path(__file__).resolve().parent
MOBILE = HERE.parent.parent
RES = MOBILE / "android" / "app" / "src" / "main" / "res"
MASTER = HERE / "app_icon_master.png"
MARK_CACHE = HERE / "app_icon_mark.png"

UV = (0x51, 0x46, 0xD8)
INK = (0x0E, 0x0D, 0x14)
PAPER = (0xF3, 0xF0, 0xE8)
CYAN = (0x00, 0xB8, 0xD9)
MAGENTA = (0xD9, 0x15, 0x68)
SIZE = 1024
SHADOW = (68, 82)
OUTLINE = 18
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2,
             "xxhdpi": 3, "xxxhdpi": 4}

# Canvas adaptativo: 108dp total, 72dp visiveis (raio 36dp), 66dp de zona segura.
ADAPTIVE_DP = 108.0
MASK_R_DP = 36.0
CENTER_DP = (54.0, 54.0)

# Expoente da superelipse da mascara do One UI, MEDIDO na tela do S23: recortei o
# icone do Nubank da gaveta (roxo chapado full-bleed, logo a silhueta dele e a
# propria mascara) e ajustei |x/R|^p + |y/R|^p = 1 por minimos quadrados.
# Resultado: p = 2.75, R = 79.1px a 2.20 px/dp (= 35.95dp, confirmando os 72dp).
# Erro rms de 0.32px. Nao chutar este valor: com p = 4.2, que era o palpite
# anterior, a face alcancava 86.7px na diagonal contra 86.9px da mascara — o
# contorno sumia nos quatro cantos e sobrava so nos lados.
MASK_POWER = 2.75
DIAG_RATIO = 2 ** (0.5 - 1 / MASK_POWER)   # quanto a curva estica na diagonal

# O cartao neobrutal cabe DENTRO da area visivel, com contorno preto grosso e
# duro. Sem sombra dura: dentro de 72dp nao sobra espaco para deslocar o cartao
# sem que a faixa escura vire moldura torta em vez de sombra. Entao aqui a
# assinatura e o contorno, e ele e igual nos quatro lados.
#
# A face usa MASK_POWER, o mesmo expoente da mascara. Duas superelipses
# concentricas de mesmo expoente mantem a distancia entre elas praticamente
# constante — varia so DIAG_RATIO (10%) entre lado e diagonal. Expoente diferente
# do da mascara e o que faz o contorno sumir nos cantos.
BAND_DP = 4.0
FACE_R_DP = MASK_R_DP - BAND_DP                           # 32dp: 89% do visivel
INK_R_DP = MASK_R_DP + 0.5    # meio dp alem da mascara: nao deixa costura clara
MARK_RATIO = 2 / 3                                        # marca sobre a face
MONO_MARK_DP = 48.0       # icone tematico nao tem cartao: a marca respira mais

# Antialias de 1.25px de largura FIXA, em pixels do arquivo. O launcher ainda
# reduz o asset (324px de xxhdpi viram ~158px na gaveta), e uma borda de 1px
# exata serrilha nessa reducao; 1.25px atravessa limpo e continua lendo como
# corte duro. Nada de rampa larga: neobrutalismo nao tem borda esfumada.
FEATHER_PX = 1.25

# Legado (API 24-25): mesmo desenho, so que a forma e nossa e ocupa o canvas
# inteiro. O limite e a diagonal do contorno, que e onde a curva estica mais.
LEGACY_SCALE = (54.0 - 0.5) / (MASK_R_DP * DIAG_RATIO)


def extract_mark():
    """Isola o V aprovado: sem cartao, sem contorno, sem sombra.

    O resultado fica cacheado em `app_icon_mark.png` e passa a ser a fonte da
    marca. A extracao le o master apenas na primeira vez — reextrair de um master
    reexportado a cada rodada degradava o antialias do V.
    """
    if MARK_CACHE.exists():
        cached = Image.open(MARK_CACHE).convert("RGBA")
        return cached.crop(cached.getbbox())

    src = Image.open(MASTER).convert("RGBA")
    data = np.asarray(src).astype(np.float64)
    rgb, alpha = data[..., :3], data[..., 3]
    foreground_palette = np.array((PAPER, CYAN, MAGENTA), dtype=float)
    background_palette = np.array((UV, INK), dtype=float)
    distance_foreground = np.sqrt(
        ((rgb[..., None, :] - foreground_palette) ** 2).sum(-1)).min(-1)
    distance_background = np.sqrt(
        ((rgb[..., None, :] - background_palette) ** 2).sum(-1)).min(-1)
    # A diferenca entre as duas paletas preserva o antialias do V, mas rejeita
    # por completo a face roxa e a sombra preta do master reexportado.
    matte = np.clip((distance_background - distance_foreground + 18.0) / 42.0,
                    0, 1) * (alpha > 24)
    foreground = np.clip(
        (rgb - (1 - matte[..., None]) * np.array(UV, float))
        / np.maximum(matte, 1e-6)[..., None], 0, 255)
    mark = Image.fromarray(
        np.dstack([foreground, matte * 255]).astype(np.uint8), "RGBA")
    mark = mark.crop(mark.getbbox())
    mark.save(MARK_CACHE, optimize=True)
    return mark


MARK = extract_mark()


# --------------------------------------------------------------------------
# 1. Pranchas de apresentacao
# --------------------------------------------------------------------------

def superellipse_mask(power=4.2):
    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    cx, cy, radius = 455, 430, 356
    equation = (np.abs((xx - cx) / radius) ** power
                + np.abs((yy - cy) / radius) ** power)
    alpha = np.clip((1 - equation) * 18 + .5, 0, 1)
    return Image.fromarray((alpha * 255).astype(np.uint8), "L")


def circle_mask():
    mask = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).ellipse((99, 74, 811, 786), fill=255)
    return mask


def cubic_points(segments, samples=80):
    points = []
    for p0, p1, p2, p3 in segments:
        for t in np.linspace(0, 1, samples, endpoint=False):
            u = 1 - t
            x = u**3*p0[0] + 3*u*u*t*p1[0] + 3*u*t*t*p2[0] + t**3*p3[0]
            y = u**3*p0[1] + 3*u*u*t*p1[1] + 3*u*t*t*p2[1] + t**3*p3[1]
            points.append((round(x), round(y)))
    return points


def teardrop_mask():
    mask = Image.new("L", (SIZE, SIZE), 0)
    segments = [
        ((455, 52), (655, 190), (820, 365), (820, 570)),
        ((820, 570), (820, 760), (655, 820), (455, 820)),
        ((455, 820), (255, 820), (90, 760), (90, 570)),
        ((90, 570), (90, 365), (255, 190), (455, 52)),
    ]
    ImageDraw.Draw(mask).polygon(cubic_points(segments), fill=255)
    return mask


def place_mark(canvas, width, center):
    height = round(width * MARK.height / MARK.width)
    mark = MARK.resize((width, height), Image.Resampling.LANCZOS)
    x = round(center[0] - width / 2)
    y = round(center[1] - height / 2)
    canvas.alpha_composite(mark, (x, y))


def compose(face_mask, mark_width, mark_center):
    """Monta uma peca manual: sombra dura, contorno, face e marca."""
    shifted = Image.new("L", (SIZE, SIZE), 0)
    shifted.paste(face_mask, SHADOW)
    outline = face_mask.filter(ImageFilter.MaxFilter(OUTLINE * 2 + 1))
    ink_alpha = ImageChops.lighter(shifted, outline)

    icon = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    ink = Image.new("RGBA", (SIZE, SIZE), INK + (255,))
    ink.putalpha(ink_alpha)
    icon.alpha_composite(ink)

    face = Image.new("RGBA", (SIZE, SIZE), UV + (255,))
    face.putalpha(face_mask)
    icon.alpha_composite(face)
    place_mark(icon, mark_width, mark_center)
    return icon


def make_icons():
    return {
        "squircle": compose(superellipse_mask(), 500, (455, 438)),
        "circle": compose(circle_mask(), 470, (455, 435)),
        "teardrop": compose(teardrop_mask(), 440, (455, 495)),
    }


# --------------------------------------------------------------------------
# 2. Camadas do Android
# --------------------------------------------------------------------------

def shape_alpha(size, kind, center_dp, radius_dp):
    """Alpha de um circulo ou squircle, com borda dura de largura uniforme.

    O valor algebrico da superelipse NAO serve como rampa de antialias: o
    gradiente dele varia em volta da curva, entao a borda sai fina nos lados e
    esfumada nas diagonais — o "brilho" que aparecia nos cantos. Dividir por
    |grad| converte esse valor em distancia de verdade, e a rampa passa a ter a
    mesma largura em toda a volta.
    """
    scale = size / ADAPTIVE_DP
    power = MASK_POWER if kind == "squircle" else 2.0
    yy, xx = np.mgrid[0:size, 0:size]
    ax = np.abs((xx + .5) / scale - center_dp[0]) / radius_dp
    ay = np.abs((yy + .5) / scale - center_dp[1]) / radius_dp

    equation = ax ** power + ay ** power - 1.0
    gradient = np.sqrt((power * ax ** (power - 1) / radius_dp) ** 2
                       + (power * ay ** (power - 1) / radius_dp) ** 2)
    distance = equation / np.maximum(gradient, 1e-9)   # em dp, negativo dentro

    feather_dp = FEATHER_PX / scale
    alpha = np.clip(.5 - distance / feather_dp, 0, 1)
    return Image.fromarray((alpha * 255).astype(np.uint8), "L")


def place_mark_dp(canvas, size, width_dp, center_dp=CENTER_DP):
    scale = size / ADAPTIVE_DP
    place_mark(canvas, round(width_dp * scale),
               (center_dp[0] * scale, center_dp[1] * scale))


def card(size, kind, center_dp, radius_dp, ink_radius_dp):
    """Desenha o cartao neobrutal e devolve o RGBA com tinta, face e marca.

    Contorno e face sao duas superelipses concentricas de mesmo expoente. Nao usar
    dilatacao aqui: `MaxFilter` tem elemento quadrado, entao engrossaria o traco
    em 41% nas diagonais — justamente onde ele precisa ficar honesto.
    """
    face_alpha = shape_alpha(size, kind, center_dp, radius_dp)
    ink_alpha = shape_alpha(size, kind, center_dp, ink_radius_dp)

    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ink = Image.new("RGBA", (size, size), INK + (255,))
    ink.putalpha(ink_alpha)
    layer.alpha_composite(ink)
    face = Image.new("RGBA", (size, size), UV + (255,))
    face.putalpha(face_alpha)
    layer.alpha_composite(face)
    place_mark_dp(layer, size, MARK_RATIO * radius_dp * 2, center_dp)
    return layer


def adaptive_foreground(size):
    """Primeiro plano: o cartao inteiro, cabendo nos 72dp que o aparelho mostra.

    O fundo adaptativo tambem e tinta, entao o preto continua ate a borda da
    mascara mesmo que a curva do One UI nao seja exatamente a nossa. Desenhar o
    contorno aqui, em vez de confiar so no fundo, garante o traco em qualquer
    mascara.
    """
    return card(size, "squircle", CENTER_DP, FACE_R_DP, INK_R_DP)


def adaptive_monochrome(size):
    """Camada para o icone tematico (One UI 5+ / Material You).

    Silhueta cheia da marca em branco; quem colore e o sistema, com a cor do
    papel de parede. Aqui nao entra cartao: o proprio recorte do sistema faz o
    corpo do icone. Sem esta camada o S23 no modo "icone colorido" cai num
    fallback feio, gerado a forca a partir do primeiro plano.
    """
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    place_mark_dp(layer, size, MONO_MARK_DP)
    white = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    white.putalpha(layer.getchannel("A"))
    return white


def legacy_icon(kind, size=SIZE):
    """Icone para API 24-25, que nao conhece camada adaptativa.

    Aqui a forma e nossa e o cartao ocupa o canvas todo. Mesmo desenho do caso
    adaptativo — contorno constante, sem sombra — so em outra escala.
    """
    return card(size, kind, CENTER_DP, FACE_R_DP * LEGACY_SCALE,
                MASK_R_DP * LEGACY_SCALE)


def write_android_layers():
    written = []
    for density, multiplier in DENSITIES.items():
        folder = RES / f"mipmap-{density}"
        folder.mkdir(parents=True, exist_ok=True)

        adaptive_edge = round(108 * multiplier)
        adaptive_foreground(adaptive_edge).save(
            folder / "ic_launcher_foreground.png", optimize=True)
        adaptive_monochrome(adaptive_edge).save(
            folder / "ic_launcher_monochrome.png", optimize=True)

        legacy_edge = round(48 * multiplier)
        for filename, kind in (("ic_launcher.png", "squircle"),
                               ("ic_launcher_round.png", "circle")):
            legacy_icon(kind).resize(
                (legacy_edge, legacy_edge), Image.Resampling.LANCZOS).save(
                folder / filename, optimize=True)

        # Restos das tentativas anteriores: nenhum XML referencia mais isso e
        # cada um viajava dentro do APK.
        for obsolete in ("ic_launcher_squircle_foreground.png",
                         "ic_launcher_circle_foreground.png",
                         "ic_launcher_teardrop.png"):
            path = folder / obsolete
            if path.exists():
                path.unlink()
                written.append(f"-{path.relative_to(RES)}")
    return written


# --------------------------------------------------------------------------
# 3. Provas visuais
# --------------------------------------------------------------------------

def launcher_mask(size, kind):
    """Mascara do aparelho: 72dp de 108dp. So para a prova; o launcher tem a sua."""
    return shape_alpha(size, kind, (54.0, 54.0), 36.0)


def render_adaptive_preview():
    """Como o S23 (e o Pixel) monta as camadas, no tamanho real da home."""
    size = 432
    canvas = Image.new("RGB", (1180, 640), (32, 30, 36))
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default(size=18)
    small = ImageFont.load_default(size=15)

    def composed(kind, themed=False):
        if themed:
            base = Image.new("RGBA", (size, size), (0x2B, 0x27, 0x4A, 255))
            tint = Image.new("RGBA", (size, size), (0xC9, 0xC4, 0xFF, 255))
            tint.putalpha(adaptive_monochrome(size).getchannel("A"))
            base.alpha_composite(tint)
        else:
            base = Image.new("RGBA", (size, size), INK + (255,))
            base.alpha_composite(adaptive_foreground(size))
        base.putalpha(launcher_mask(size, kind))
        return base

    # O legado ja e o icone inteiro, enquanto do canvas adaptativo so 72 dos
    # 108dp aparecem. Encolher a coluna legada nessa proporcao deixa a prancha
    # na mesma escala visual que o aparelho mostra.
    columns = [
        ("S23 / One UI", composed("squircle"), 1.0),
        ("S23 / icone tematico", composed("squircle", themed=True), 1.0),
        ("Pixel / circulo", composed("circle"), 1.0),
        ("API 24 / legado", legacy_icon("squircle", size), 72 / 108),
    ]
    draw.text((28, 20), "VAIJUNTO / APLICACAO NO APARELHO", fill=PAPER,
              font=font)
    for row, backdrop in enumerate(((32, 30, 36), PAPER)):
        y0 = 56 + row * 292
        draw.rectangle((0, y0, 1180, y0 + 288), fill=backdrop)
        for col, (label, icon, ratio) in enumerate(columns):
            cx = 160 + col * 290
            color = PAPER if row == 0 else INK
            box = draw.textbbox((0, 0), label, font=small)
            draw.text((cx - (box[2] - box[0]) / 2, y0 + 16), label,
                      fill=color, font=small)
            for slot, cy, dx in ((150, y0 + 122, 0), (72, y0 + 240, -62),
                                 (48, y0 + 240, 18), (36, y0 + 240, 70)):
                edge = round(slot * ratio)
                thumb = icon.resize((edge, edge), Image.Resampling.LANCZOS)
                canvas.paste(thumb, (cx + dx - edge // 2, cy - edge // 2),
                             thumb)
    canvas.save(HERE / "app_icon_s23_adaptive_preview.png", optimize=True)


def render_contact_sheet(icons):
    canvas = Image.new("RGB", (1200, 760), (42, 39, 47))
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.load_default(size=20)
    labels = {"squircle": "SQUIRCLE / SAMSUNG",
              "circle": "CIRCULO / PIXEL",
              "teardrop": "GOTA / OUTROS"}
    for row, backdrop in enumerate(((42, 39, 47), PAPER)):
        y0 = row * 380
        draw.rectangle((0, y0, 1200, y0 + 380), fill=backdrop)
        for col, (kind, icon) in enumerate(icons.items()):
            cx = 200 + col * 400
            color = PAPER if row == 0 else INK
            label = labels[kind]
            box = draw.textbbox((0, 0), label, font=font)
            draw.text((cx - (box[2] - box[0]) / 2, y0 + 22), label,
                      fill=color, font=font)
            for display, cy, dx in ((230, y0 + 174, 0),
                                    (92, y0 + 310, -48),
                                    (48, y0 + 310, 48)):
                thumb = icon.resize((display, display), Image.Resampling.LANCZOS)
                canvas.paste(thumb, (cx + dx - display // 2,
                                     cy - display // 2), thumb)
    canvas.save(HERE / "app_icon_variations.png", optimize=True)


def main():
    icons = make_icons()
    for kind, icon in icons.items():
        icon.save(HERE / f"app_icon_{kind}.png", optimize=True)
    # `app_icon_master.png` fica intocado: e a fonte da marca, nao uma saida.
    removed = write_android_layers()
    render_contact_sheet(icons)
    render_adaptive_preview()
    print("pranchas:", ", ".join(icons))
    print("camadas android: ic_launcher_foreground, ic_launcher_monochrome, "
          "ic_launcher, ic_launcher_round")
    if removed:
        print("removidos:", len(removed), "arquivos obsoletos")


if __name__ == "__main__":
    main()
