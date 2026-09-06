#!/usr/bin/env python3
"""Vetoriza um sigilo desenhado: da imagem para tracos riscaveis.

O `ponto_riscado` e input, nao ilustracao (SPEC.md §4). Para virar `ponto`,
um sigilo desenhado precisa virar geometria com comeco, meio e fim — e,
como o ponto e uma copia fiel do desenho, precisa virar TODA a geometria,
nao um resumo dela.

Como funciona:
  1. afina a tinta ate uma linha de um pixel (Zhang-Suen)
  2. le essa linha como um grafo: pontas, cruzamentos, e os caminhos entre
  3. costura os caminhos que atravessam um cruzamento em linha reta, para
     que duas linhas que se cruzam continuem sendo duas linhas e nao quatro
  4. suaviza e reamostra cada traco

O que ele NAO faz, porque nao e medida e sim doutrina:
  - a ordem dos tracos e o sentido de cada um (SPEC.md §4.1: "in a
    required order"). Doutrina de A.C.: de cima para baixo, da esquerda
    para a direita — vale para qual traco vem primeiro e para onde cada
    traco comeca.

Uso:
    python3 tools/extrair_sigilo.py ENTRADA.png [--saida DIR] [--min-px N]

Sai: DIR/tracos.json      polilinhas em pixels da imagem
     DIR/sobreposicao.png conferencia visual, uma cor por traco
"""
import argparse, json, os
import numpy as np
from PIL import Image, ImageDraw

MIN_COMPRIMENTO = 14      # px: abaixo disto e respingo, nao traco
ANGULO_COSTURA = 55.0     # graus: continuidade aceita ao atravessar um no
RAIO_NO = 4.0             # px: um cruzamento nao e um pixel, e um borrao
AMOSTRAS_MIN = 4


# --- tinta -------------------------------------------------------------

def mascara_de_tinta(caminho):
    """Tinta escura sobre fundo claro, clara sobre escuro, ou sobre nada.

    Duas perguntas, nesta ordem:

    1. O fundo e transparente? Entao o que e opaco E a tinta, seja qual for
       a cor dela. Julgar a cor primeiro inverteria o preto-sobre-
       transparente, onde a parte opaca e escura *e* e a tinta.
    2. Senao a folha e opaca inteira, e o fundo e a luminancia que domina.
       A tinta e a outra.
    """
    im = Image.open(caminho).convert("RGBA")
    a = np.asarray(im).astype(int)
    r, g, b, al = a[:, :, 0], a[:, :, 1], a[:, :, 2], a[:, :, 3]
    opaco = al > 128
    lum = (r + g + b) / 3.0
    vermelho = opaco & (r > 90) & (r - g > 45) & (r - b > 45)
    if opaco.mean() < 0.5:
        tinta = opaco
    else:
        escuro = opaco & (lum < 110)
        claro = opaco & (lum > 145)
        tinta = claro if escuro.sum() > claro.sum() else escuro
    # Vermelho conta como tinta, mas volta marcado: no Barco o vermelho nao
    # e cor livre — e o `ponto` firmado (SPEC.md §8.2, §11).
    return (tinta | vermelho), vermelho, im.size


# --- afinamento --------------------------------------------------------

def _vizinhos(m):
    """P2..P9 no sentido horario a partir do norte."""
    p = np.pad(m, 1)
    return [p[0:-2, 1:-1], p[0:-2, 2:], p[1:-1, 2:], p[2:, 2:],
            p[2:, 1:-1], p[2:, 0:-2], p[1:-1, 0:-2], p[0:-2, 0:-2]]


def afinar(m):
    """Zhang-Suen: reduz a tinta a uma linha de um pixel de largura."""
    img = m.astype(np.uint8).copy()
    while True:
        mudou = False
        for passo in (0, 1):
            v = _vizinhos(img)
            B = sum(v)
            seq = v + [v[0]]
            A = sum(((seq[i] == 0) & (seq[i + 1] == 1)).astype(np.uint8)
                    for i in range(8))
            if passo == 0:
                c1 = v[0] * v[2] * v[4] == 0
                c2 = v[2] * v[4] * v[6] == 0
            else:
                c1 = v[0] * v[2] * v[6] == 0
                c2 = v[0] * v[4] * v[6] == 0
            apagar = (img == 1) & (B >= 2) & (B <= 6) & (A == 1) & c1 & c2
            if apagar.any():
                img[apagar] = 0
                mudou = True
        if not mudou:
            return img.astype(bool)


# --- grafo -------------------------------------------------------------

VIZ8 = [(-1, 0), (-1, 1), (0, 1), (1, 1), (1, 0), (1, -1), (0, -1), (-1, -1)]


def grau(esq):
    g = np.zeros(esq.shape, np.uint8)
    p = np.pad(esq, 1)
    for dy, dx in VIZ8:
        g += p[1 + dy:1 + dy + esq.shape[0], 1 + dx:1 + dx + esq.shape[1]]
    return g * esq


def _viz(esq, y, x):
    alt, lar = esq.shape
    for dy, dx in VIZ8:
        b, a = y + dy, x + dx
        if 0 <= b < alt and 0 <= a < lar and esq[b, a]:
            yield b, a


def podar(esq, minimo=12, passos=3):
    """Corta as farpas curtas que o afinamento deixa.

    Afinar um traco grosso produz pequenos galhos laterais. Cada galho e um
    cruzamento a mais, e cada cruzamento parte uma curva longa em pedacos —
    o ponto passaria a exigir dez tracos onde o desenho tem um.
    """
    esq = esq.copy()
    for _ in range(passos):
        g = grau(esq)
        remover = []
        for ponta in map(tuple, np.argwhere((g == 1) & esq)):
            ramo = [ponta]
            antes, atual = None, ponta
            while len(ramo) <= minimo:
                vs = [v for v in _viz(esq, *atual) if v != antes]
                if len(vs) != 1 or g[vs[0]] >= 3:
                    break                      # chegou a um cruzamento
                antes, atual = atual, vs[0]
                ramo.append(atual)
            if len(ramo) <= minimo:
                remover.extend(ramo)
        if not remover:
            break
        for q in remover:
            esq[q] = False
    return esq


def caminhos(esq):
    """Caminhos entre pontas e cruzamentos, seguindo pixels de grau 2."""
    g = grau(esq)
    nos = set(map(tuple, np.argwhere((g != 2) & esq)))
    alt, lar = esq.shape

    def viz(y, x):
        for dy, dx in VIZ8:
            b, a = y + dy, x + dx
            if 0 <= b < alt and 0 <= a < lar and esq[b, a]:
                yield b, a

    usados = set()
    saida = []

    def andar(ini, seg):
        caminho = [ini, seg]
        usados.add(frozenset((ini, seg)))
        atual, antes = seg, ini
        while tuple(atual) not in nos:
            proximo = None
            for v in viz(*atual):
                if v != antes:
                    proximo = v
                    break
            if proximo is None:
                break
            usados.add(frozenset((atual, proximo)))
            caminho.append(proximo)
            antes, atual = atual, proximo
        return caminho

    for no in nos:
        for v in viz(*no):
            if frozenset((no, v)) not in usados:
                saida.append(andar(no, v))

    # Aneis fechados: nenhum no, todos de grau 2.
    vistos = {p for c in saida for p in c}
    for p in map(tuple, np.argwhere(esq)):
        if p in vistos:
            continue
        anel = [p]
        vistos.add(p)
        atual, antes = p, None
        while True:
            prox = next((v for v in viz(*atual) if v != antes and v not in vistos), None)
            if prox is None:
                break
            vistos.add(prox)
            anel.append(prox)
            antes, atual = atual, prox
        if len(anel) > 8:
            anel.append(p)
            saida.append(anel)
    return saida


def _direcao(caminho, no_fim, quantos=8):
    pts = caminho[-quantos:] if no_fim else caminho[:quantos][::-1]
    if len(pts) < 2:
        return np.array([0.0, 0.0])
    d = np.array(pts[-1], float) - np.array(pts[0], float)
    n = np.linalg.norm(d)
    return d / n if n else d


def costurar(cs):
    """Junta caminhos que atravessam um cruzamento sem mudar de direcao.

    Sem isto, duas linhas que se cruzam viram quatro cotos, e riscar o
    ponto passaria a exigir quatro tracos onde o desenho tem dois.

    O emparelhamento e feito por cruzamento, nao por ordem de lista: num
    cruzamento de quatro pontas ha tres emparelhamentos possiveis, e casar
    a primeira que aparece costuma bloquear o par certo. Aqui as pontas de
    cada cruzamento sao pontuadas todas contra todas e casadas da melhor
    para a pior.
    """
    cs = [list(c) for c in cs]
    limite = np.cos(np.radians(ANGULO_COSTURA))

    pontas = []                     # (traco, ponta, posicao, direcao)
    for i, c in enumerate(cs):
        pontas.append((i, 0, np.array(c[0], float), _direcao(c, False)))
        pontas.append((i, 1, np.array(c[-1], float), _direcao(c, True)))

    # Agrupar pontas que caem no mesmo cruzamento.
    grupos, tomada = [], [False] * len(pontas)
    for i in range(len(pontas)):
        if tomada[i]:
            continue
        g, tomada[i] = [i], True
        for j in range(i + 1, len(pontas)):
            if not tomada[j] and np.hypot(*(pontas[i][2] - pontas[j][2])) <= RAIO_NO:
                g.append(j)
                tomada[j] = True
        if len(g) >= 2:
            grupos.append(g)

    par = {}
    for g in grupos:
        candidatos = []
        for a in range(len(g)):
            for b in range(a + 1, len(g)):
                pa, pb = pontas[g[a]], pontas[g[b]]
                if pa[0] == pb[0]:
                    continue        # nao costurar um traco a si mesmo
                pont = float(np.dot(pa[3], -pb[3]))
                if pont > limite:
                    candidatos.append((pont, g[a], g[b]))
        candidatos.sort(reverse=True, key=lambda t: t[0])
        usadas = set()
        for _, ia, ib in candidatos:
            if ia in usadas or ib in usadas:
                continue
            usadas.add(ia)
            usadas.add(ib)
            a, b = pontas[ia], pontas[ib]
            par[(a[0], a[1])] = (b[0], b[1])
            par[(b[0], b[1])] = (a[0], a[1])

    # Percorrer as cadeias resultantes.
    visitados, saida = set(), []
    for i in range(len(cs)):
        if i in visitados:
            continue
        # recuar ate o comeco da cadeia
        traco, ponta, local = i, 0, {i}
        while (traco, ponta) in par:
            q, f = par[(traco, ponta)]
            if q in local:
                break               # anel: para onde comecou
            local.add(q)
            traco, ponta = q, 1 - f
        pts = []
        while traco not in visitados:
            visitados.add(traco)
            trecho = cs[traco] if ponta == 0 else cs[traco][::-1]
            pts += trecho if not pts else trecho[1:]
            seguinte = par.get((traco, 1 - ponta))
            if seguinte is None:
                break
            traco, ponta = seguinte
        if pts:
            saida.append(pts)
    return saida


# --- polilinha ---------------------------------------------------------

def comprimento(pts):
    a = np.asarray(pts, float)
    return float(np.hypot(*np.diff(a, axis=0).T).sum()) if len(a) > 1 else 0.0


def suavizar(pts, janela=5):
    a = np.asarray(pts, float)
    if len(a) < janela:
        return a
    nucleo = np.ones(janela) / janela
    saida = a.copy()
    for eixo in (0, 1):
        saida[:, eixo] = np.convolve(a[:, eixo], nucleo, mode="same")
    saida[:janela] = a[:janela]
    saida[-janela:] = a[-janela:]
    return saida


def reamostrar(pts, passo=4.0):
    a = np.asarray(pts, float)
    if len(a) < 2:
        return a
    d = np.concatenate([[0.0], np.cumsum(np.hypot(*np.diff(a, axis=0).T))])
    n = max(AMOSTRAS_MIN, int(d[-1] / passo) + 1)
    alvo = np.linspace(0, d[-1], n)
    return np.stack([np.interp(alvo, d, a[:, 0]), np.interp(alvo, d, a[:, 1])], axis=1)


CORES = [(228, 26, 28), (55, 126, 184), (77, 175, 74), (152, 78, 163),
         (255, 127, 0), (166, 86, 40), (247, 129, 191), (0, 206, 209),
         (154, 205, 50), (255, 215, 0)]


def sobrepor(tamanho, tracos, destino):
    im = Image.new("RGB", tamanho, (10, 10, 10))
    d = ImageDraw.Draw(im)
    for i, pts in enumerate(tracos):
        cor = CORES[i % len(CORES)]
        d.line([(x, y) for x, y in pts], fill=cor, width=3)
        d.text((pts[0][0] + 6, pts[0][1] - 6), str(i), fill=cor)
    im.save(destino)


def endireitar(traco):
    """Poe o traco a comecar em cima, e a esquerda em caso de empate.

    O sentido nao e detalhe: a distancia de Frechet compara ponto a ponto
    ao longo do caminho, entao um traco guardado ao contrario do que a
    pessoa risca da distancia grande num risco perfeito.
    """
    a, b = traco[0], traco[-1]
    if (b[1], b[0]) < (a[1], a[0]):     # (y, x): mais acima, depois mais a esquerda
        return traco[::-1].copy()
    return traco


def chave_de_leitura(caixa, tolerancia=0.03):
    """Ordena os tracos por onde COMECAM: de cima para baixo, da esquerda
    para a direita.

    A altura entra em bandas e nao ao pixel. Sem isso, dois tracos que
    comecam a mesma altura ordenavam-se por uma diferenca de um pixel em
    vez de pela esquerda, e a ordem mudava conforme o desenho.
    """
    banda = max(1.0, tolerancia * (caixa["y1"] - caixa["y0"]))
    return lambda p: (round(p[0][1] / banda), p[0][0])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("entrada")
    ap.add_argument("--saida", default="capturas")
    ap.add_argument("--min-px", type=float, default=MIN_COMPRIMENTO)
    args = ap.parse_args()
    os.makedirs(args.saida, exist_ok=True)

    tinta, vermelho, tamanho = mascara_de_tinta(args.entrada)
    esq = afinar(tinta)
    # Uma farpa nao passa da largura do proprio traco. Medir a largura
    # (area da tinta sobre o comprimento do esqueleto) evita podar demais
    # num desenho de pincel grosso e de menos num de linha fina.
    espessura = 2.0 * tinta.sum() / max(1, esq.sum())
    esq = podar(esq, minimo=max(5, int(espessura)))
    cs = costurar(caminhos(esq))

    tracos = []
    for c in cs:
        pts = np.array([(x, y) for y, x in c], float)   # (linha, coluna) -> (x, y)
        if comprimento(pts) < args.min_px:
            continue
        tracos.append(reamostrar(suavizar(pts)))

    ys, xs = np.nonzero(tinta)
    caixa = {"x0": int(xs.min()), "x1": int(xs.max()),
             "y0": int(ys.min()), "y1": int(ys.max())}

    # Doutrina de A.C.: de cima para baixo, da esquerda para a direita.
    # Governa DUAS coisas, e nenhuma sai do desenho — saem do
    # percorredor de contornos, que comeca onde calha.
    tracos = [endireitar(t) for t in tracos]
    tracos.sort(key=chave_de_leitura(caixa))
    with open(os.path.join(args.saida, "tracos.json"), "w") as f:
        json.dump({"origem": os.path.basename(args.entrada), "caixa": caixa,
                   "px_vermelhos": int(vermelho.sum()),
                   "tracos": [p.tolist() for p in tracos]}, f)
    sobrepor(tamanho, tracos, os.path.join(args.saida, "sobreposicao.png"))

    print("caixa: x[%d..%d] y[%d..%d]" % (caixa["x0"], caixa["x1"], caixa["y0"], caixa["y1"]))
    print("tracos: %d" % len(tracos))
    for i, p in enumerate(tracos):
        print("  %2d  n=%4d  comp=%6.0f  x[%4.0f..%4.0f] y[%4.0f..%4.0f]" % (
            i, len(p), comprimento(p), p[:, 0].min(), p[:, 0].max(),
            p[:, 1].min(), p[:, 1].max()))
    if vermelho.sum():
        print("\nAVISO: %d px vermelhos. No Barco o vermelho e o `ponto` "
              "firmado com `sacrificio` (SPEC.md §8.2)." % vermelho.sum())


if __name__ == "__main__":
    main()
