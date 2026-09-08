#!/usr/bin/env python3
"""Confere se o balde de sangue e o som dele ainda andam juntos.

    python3 tools/afinar_sangue.py

O som nao e um impacto, e um despejo: comeca alto, engrossa ate ao pico e
so depois esvazia. Um balde a bater tem o pico no primeiro instante; um
balde a despejar tem-no a meio. Isso muda como a poca tem de crescer — se
ela travar cedo, fica quieta no chao enquanto o ouvido ainda ouve
despejar, e e isso que se le como dessincronizado.

Mede tres coisas no `.ogg`:

  - onde comeca a soar. Se houver silencio a cabeca, o gesto tem de
    esperar por ele, senao o impacto do olho vem antes do do ouvido;
  - onde esta o pico. E ai que a poca deve estar a crescer mais depressa;
  - onde o som acaba de facto, ignorando o silencio do fim. E essa a
    duracao que o `DEMORA` deve ter, nao a duracao do ficheiro.

Depois compara com o que esta no codigo e diz o que mudar. Nao mexe em
nada: quem decide es tu.

Precisa de `ffmpeg` e de `numpy`.
"""
import pathlib
import re
import subprocess
import sys

import numpy as np

SOM = pathlib.Path("client/resources/audio/banho_de_sangue.ogg")
POCA = pathlib.Path("client/scripts/ui/poca_de_sangue.gd")
SHADER = pathlib.Path("client/shaders/sangue.gdshader")

## Abaixo disto e silencio, nao som.
SOALHO = 0.10
## Passo da medida, em segundos.
JANELA = 0.010


def envelope(caminho):
    taxa = 22050
    cru = subprocess.run(
        ["ffmpeg", "-v", "quiet", "-i", str(caminho),
         "-f", "s16le", "-ac", "1", "-ar", str(taxa), "-"],
        capture_output=True).stdout
    x = np.frombuffer(cru, dtype="<i2").astype(np.float32) / 32768.0
    jan = int(taxa * JANELA)
    n = len(x) // jan
    rms = np.sqrt(np.array([(x[i * jan:(i + 1) * jan] ** 2).mean()
                            for i in range(n)]) + 1e-12)
    return rms, len(x) / taxa


def numero(caminho, padrao):
    m = re.search(padrao, caminho.read_text())
    return float(m.group(1)) if m else None


def main():
    if not SOM.exists():
        print("nao ha som em", SOM)
        return 1
    rms, duracao = envelope(SOM)
    pico = rms.max()
    acesos = np.where(rms > pico * SOALHO)[0]
    entrada = acesos[0] * JANELA
    fim = (acesos[-1] + 1) * JANELA
    topo = int(rms.argmax()) * JANELA

    print("O SOM  %s" % SOM.name)
    print("  ficheiro          %.3f s" % duracao)
    print("  entra a           %.3f s" % entrada)
    print("  pico a            %.3f s  (%.0f%% do som)" % (topo, 100.0 * topo / fim))
    print("  acaba a           %.3f s  (%.3f s de silencio no fim)"
          % (fim, duracao - fim))

    demora = numero(POCA, r"const DEMORA := ([0-9.]+)")
    expo = numero(SHADER, r"pow\(clamp\(espalhamento, 0.0, 1.0\), ([0-9.]+)\)")
    print("")
    print("O GESTO")
    print("  DEMORA            %.3f s" % demora)
    # Onde a curva do shader cresce mais depressa.
    t = np.linspace(0, 1, 2001)[1:-1]
    u = t ** expo
    s = u * u * (3.0 - 2.0 * u)
    onde = t[np.gradient(s, t).argmax()]
    print("  expoente          %.2f" % expo)
    print("  cresce mais a     %.3f s  (%.0f%% do gesto)"
          % (onde * demora, 100.0 * onde))

    print("")
    print("BATEM CERTO?")
    mau = False
    if entrada > 0.02:
        print("  NAO: o som tem %.3f s de silencio a cabeca. O gesto devia"
              % entrada)
        print("       esperar esse tempo antes de comecar a espalhar.")
        mau = True
    if abs(demora - fim) > 0.08:
        print("  NAO: o gesto dura %.3f s e o som %.3f s. Poe DEMORA := %.2f"
              % (demora, fim, fim))
        mau = True
    if abs(onde * demora - topo) > 0.10:
        alvo = topo / fim
        # Que expoente poe o maximo de crescimento nessa fraccao.
        melhor = min(np.arange(0.6, 2.01, 0.01),
                     key=lambda k: abs(t[np.gradient((t ** k) ** 2
                         * (3.0 - 2.0 * t ** k), t).argmax()] - alvo))
        print("  NAO: a poca cresce mais a %.3f s e o som pica a %.3f s."
              % (onde * demora, topo))
        print("       Poe o expoente do shader a %.2f." % melhor)
        mau = True
    if not mau:
        print("  sim. o balde espalha ao mesmo compasso a que se ouve despejar.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
