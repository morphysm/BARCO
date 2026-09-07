#!/usr/bin/env python3
"""Recorta o fundo do sigilo do chao e grava um PNG com alfa.

O ficheiro de A.C. e um JPG: a marca em vermelho sobre PRETO, sem canal
alfa nenhum. Posto tal e qual no chao, o que se via era um quadrado preto
— e o preto sobre um chao escuro nao se ve de todo.

Aqui o fundo sai pela luminancia (o escuro fica transparente) e a tinta
sobe de forca: no ficheiro ela nao passa de 128 em 255, e no escuro da
sala isso nao chega.

    python3 tools/recortar_sigilo.py
"""
import pathlib
import sys

import numpy as np
from PIL import Image

ORIGEM = pathlib.Path("client/resources/imagens/MORPHISTIC SIGIL_para o chão.jpg")
DESTINO = pathlib.Path("client/resources/imagens/sigilo_chao.png")

## Abaixo desta luminancia e fundo.
CORTE = 0.30
## Quanto a tinta sobe.
FORCA = 2.0


def main():
    if not ORIGEM.exists():
        print("nao ha origem em", ORIGEM)
        return 1
    a = np.array(Image.open(ORIGEM).convert("RGB")).astype(np.float32) / 255.0
    lum = a[:, :, 0] * 0.299 + a[:, :, 1] * 0.587 + a[:, :, 2] * 0.114
    alfa = np.clip(lum / CORTE, 0.0, 1.0)
    rgb = np.clip(a * FORCA, 0.0, 1.0)
    saida = np.dstack([(rgb * 255).astype(np.uint8), (alfa * 255).astype(np.uint8)])
    Image.fromarray(saida, "RGBA").save(DESTINO)
    print("%s -> %s" % (ORIGEM.name, DESTINO.name))
    print("  opaco %.1f%%   transparente %.1f%%" % (
        100 * (alfa > 0.5).mean(), 100 * (alfa < 0.1).mean()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
