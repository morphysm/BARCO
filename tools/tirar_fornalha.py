#!/usr/bin/env python3
"""Copia UM forno da bancada do `Iovana Is DEAD` para o Barco.

A bancada tem cinco bocas em arco na mesma parede de tijolo. Um arco
sozinho nao se sustenta — fica a flutuar. Entao leva-se a parede inteira
e uma boca so: a `Bay2`, que e a que esta aberta (as `Bay1`, `Bay3` e
`Bay5` estao seladas a arder e nao se pode atirar nada la para dentro).

NAO ALTERA GEOMETRIA. Nao corta, nao redimensiona, nao mexe em materiais.
A malha, os acessores e o binario saem byte a byte como entraram.

UMA EXCEPCAO, a pedido de A.C.: a caveira e os ossos que estavam soltos
dentro da `Bay2` sao TRANSLADADOS 1.5 em x para o vao do meio. E a unica
coisa que se move, e move-se inteira — sao pecas pousadas dentro da
boca, nao parte da fornalha. Sem isto o vao do meio ficava vazio, porque
so as bocas `Bay2` e `Bay4` traziam ossos.

A origem e SO DE LEITURA e nunca e tocada.

    python3 tools/tirar_fornalha.py
"""
import json
import pathlib
import struct
import sys

ORIGEM = pathlib.Path(
    "/home/kadaver/Documents/the-ballerina/godot_project/models/"
    "exu_caveira_furnace_bank_v2_atmosphere_v1.glb")
DESTINO = pathlib.Path("client/resources/modelos/fornalha.glb")

# A boca que fica e a `Bay3` — a do MEIO da bancada, centro em x = 0.
#
# Antes era a `Bay2` (centro -1.24), que ja vinha aberta de fabrica. Mas
# com a bancada centrada na sala, uma boca a -1.24 fica torta, e
# empurrar a bancada para a endireitar enfia-a na parede do lado. A do
# meio e a unica que fica ao centro sem mover nada.
#
# A `Bay3` vem SELADA, entao tira-se-lhe a porta. Nao e alterar
# geometria: e nao referir um no, exactamente como se faz as outras
# bocas. Nada e movido, cortado nem redimensionado.
## As pecas soltas que vem com a caveira, e que acompanham a boca.
OSSOS = ("Bay2_BoneSkull", "Bay2_BoneSkull_EyeSocket1", "Bay2_BoneSkull_EyeSocket2",
         "Bay2_DryBone01", "Bay2_DryBone02", "Bay2_DryBone03", "Bay2_DryBone04",
         "Bay2_DryBone05", "Bay2_DryBone06", "Bay2_DryBone07")

## De quanto se deslocam: do centro da `Bay2` para o da `Bay3`.
PASSO = 1.5

FORA = ("Bay1_", "Bay2_", "Bay4_", "Bay5_",
        # A porta selada e o tapume que estava por tras dela. Sem tirar
        # os dois, o vao continua fechado: via-se um arco escuro e a
        # brasa nao passava.
        "Bay3_UpperDoor_SealedBurning", "Bay3_DoorRefractoryInset")


def ler(caminho):
    d = caminho.read_bytes()
    if d[:4] != b"glTF":
        raise SystemExit("nao e um glb: %s" % caminho)
    pedacos = []
    off = 12
    while off < len(d):
        ln, ty = struct.unpack_from("<II", d, off)
        pedacos.append((ty, d[off + 8:off + 8 + ln]))
        off += 8 + ln
    return pedacos


def escrever(caminho, pedacos):
    corpo = b""
    for ty, dados in pedacos:
        resto = (-len(dados)) % 4
        enchimento = (b" " if ty == 0x4E4F534A else b"\0") * resto
        dados = dados + enchimento
        corpo += struct.pack("<II", len(dados), ty) + dados
    caminho.write_bytes(b"glTF" + struct.pack("<II", 2, 12 + len(corpo)) + corpo)


def main():
    if not ORIGEM.exists():
        print("nao ha origem em", ORIGEM)
        return 1
    pedacos = ler(ORIGEM)
    saida = []
    tirados = 0
    for ty, dados in pedacos:
        if ty != 0x4E4F534A:
            saida.append((ty, dados))          # binario intacto
            continue
        j = json.loads(dados)
        nos = j["nodes"]

        # Os ossos mudam de boca antes de se decidir o que fica.
        movidos = 0
        for n in nos:
            if n.get("name") in OSSOS:
                t = n.get("translation", [0.0, 0.0, 0.0])
                n["translation"] = [t[0] + PASSO, t[1], t[2]]
                movidos += 1

        for n in nos:
            filhos = n.get("children")
            if not filhos:
                continue
            fica = [i for i in filhos
                    if nos[i].get("name", "") in OSSOS
                    or not nos[i].get("name", "").startswith(FORA)]
            tirados += len(filhos) - len(fica)
            n["children"] = fica
        saida.append((ty, json.dumps(j, separators=(",", ":")).encode()))
        print("  ossos mudados de boca: %d (+%.1f em x)" % (movidos, PASSO))

    DESTINO.parent.mkdir(parents=True, exist_ok=True)
    escrever(DESTINO, saida)
    print("%s -> %s" % (ORIGEM.name, DESTINO))
    print("  nos deixados de fora: %d (as bocas %s)" % (tirados, ", ".join(FORA)))
    print("  %d bytes" % DESTINO.stat().st_size)
    return 0


if __name__ == "__main__":
    sys.exit(main())
