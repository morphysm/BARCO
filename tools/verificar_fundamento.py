#!/usr/bin/env python3
"""Confere que o fundamento do `assentamento` nao mudou.

O fundamento e autoral: e o vaso que faz este `assentamento` ser o daquela
entidade. Depois de montado, fica travado — nao porque o ficheiro seja
imutavel, mas para que qualquer alteracao apareca em vez de passar
despercebida.

    python3 tools/verificar_fundamento.py             # confere
    python3 tools/verificar_fundamento.py --regravar  # aceita o estado atual

O que muda por cima disto sao `depositos`, que nunca tocam nesta cena.
"""
import hashlib
import pathlib
import sys

CENA = pathlib.Path("client/scenes/assentamento.tscn")
SELO = pathlib.Path("client/scenes/assentamento.travado")


def soma():
    return hashlib.sha256(CENA.read_bytes()).hexdigest()


def pecas():
    return sum(1 for l in CENA.read_text().splitlines() if l.startswith("[node name="))


def main():
    if not CENA.exists():
        print("nao ha cena em", CENA)
        return 1
    agora = soma()
    if "--regravar" in sys.argv:
        SELO.write_text("# Fundamento travado. Ver tools/verificar_fundamento.py\n"
                        "sha256 = %s\npecas = %d\n" % (agora, pecas()))
        print("selado: %d pecas\n%s" % (pecas(), agora))
        return 0
    if not SELO.exists():
        print("sem selo. correr com --regravar para o criar.")
        return 1
    esperado = ""
    for linha in SELO.read_text().splitlines():
        if linha.startswith("sha256"):
            esperado = linha.split("=", 1)[1].strip()
    if esperado == agora:
        print("fundamento intacto — %d pecas" % pecas())
        return 0
    print("FUNDAMENTO ALTERADO")
    print("  selado: %s" % esperado)
    print("  agora:  %s  (%d pecas)" % (agora, pecas()))
    print("  se foi de proposito: --regravar. senao: git checkout -- %s" % CENA)
    return 1


sys.exit(main())
