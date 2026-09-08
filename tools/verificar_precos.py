#!/usr/bin/env python3
"""Confere que os precos do cliente e os do servidor nao derivaram.

    python3 tools/verificar_precos.py

O cliente MOSTRA o preco; o servidor DECIDE com ele. Se os dois
discordarem, uma pessoa ve 2 USD no botao e paga outra coisa — ou paga o
certo e nao recebe nada. Nenhum dos dois lados da por isso sozinho, e por
isso e que ha esta ferramenta.

Le os `.tres` do cliente e a tabela `atos` do projecto alojado, pela chave
PUBLICA (a `atos` tem politica de leitura publica de proposito: sao os
numeros que estao nos botoes).
"""
import json
import pathlib
import re
import subprocess
import sys
import urllib.request

OFERENDAS = pathlib.Path("client/resources/oferendas")
SERVIDOR = pathlib.Path("client/resources/servidor/supabase.tres")


def do_cliente():
    precos = {}
    for f in sorted(OFERENDAS.glob("*.tres")):
        t = f.read_text()
        slug = re.search(r'slug = "(.*)"', t)
        cafes = re.search(r"cafes = (\d+)", t)
        if slug and cafes:
            precos[slug.group(1)] = int(cafes.group(1))
    return precos


def do_servidor():
    t = SERVIDOR.read_text()
    url = re.search(r'url = "(.*)"', t).group(1)
    chave = re.search(r'chave_publica = "(.*)"', t).group(1)
    pedido = urllib.request.Request(
        url + "/rest/v1/atos?select=slug,cafes",
        headers={"apikey": chave, "Authorization": "Bearer " + chave})
    with urllib.request.urlopen(pedido, timeout=30) as r:
        return {a["slug"]: a["cafes"] for a in json.load(r)}


def main():
    cliente = do_cliente()
    try:
        servidor = do_servidor()
    except Exception as e:
        print("nao se chegou ao servidor:", e)
        return 2

    mau = False
    for slug in sorted(cliente):
        c = cliente[slug]
        s = servidor.get(slug)
        if s is None:
            print("  FALTA no servidor: %-16s (o cliente pede %d cafe/s)" % (slug, c))
            mau = True
        elif s != c:
            print("  DIVERGE: %-16s cliente %d, servidor %d" % (slug, c, s))
            mau = True
        else:
            print("  ok       %-16s %d cafe(s)" % (slug, c))

    sobra = sorted(set(servidor) - set(cliente))
    if sobra:
        print("")
        print("  actos so no servidor (do §10.1, sem oferenda a apontar-lhes):")
        for slug in sobra:
            print("    %-22s %d cafe(s)" % (slug, servidor[slug]))

    print("")
    print("PRECOS DIVERGENTES" if mau else "os dois lados dizem o mesmo")
    return 1 if mau else 0


if __name__ == "__main__":
    sys.exit(main())
