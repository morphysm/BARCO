#!/usr/bin/env python3
"""Reduz os modelos do `assentamento` ao que a cena precisa.

Rodar:
    blender --background --python tools/decimar_modelos.py -- ENTRADA/ SAIDA/ [alvo]

Dois cortes, e os dois vem do modo como a cena e desenhada:

1. TEXTURAS PEQUENAS. O shader `gravura` e unshaded e nao amostra textura
   nenhuma — a cor sai de uma trama de linhas calculada a partir de uma
   luz so. As imagens nunca chegam a ser lidas pelo app: existem para o
   editor, para se reconhecer o objeto ao arrumar a nganga. Para isso
   256 px chegam, e sao a diferenca entre 9 MB e uma fracao disso.

   (Tira-las por completo poupa mais, mas deixa os modelos irreconheciveis
   no editor. Nao vale a troca.)

2. MENOS TRIANGULOS. A camara e ortogonal, fixa, e o objeto esta quase
   todo no escuro. Cento e trinta mil triangulos numa teia que se ve de um
   angulo so, a meia luz, nao se distinguem de seis mil.

O que NAO se toca: as normais. E delas que a trama tira o sombreado.
"""
import os
import sys
import bpy

ALVO_PADRAO = 6000
TEXTURA_PADRAO = 256


def limpar():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def triangulos():
    total = 0
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.data.calc_loop_triangles()
            total += len(o.data.loop_triangles)
    return total


def sem_chaves_de_forma():
    """Fora as shape keys: o modificador nao se aplica com elas, e nada no
    `assentamento` anima."""
    for o in bpy.data.objects:
        if o.type == "MESH" and o.data.shape_keys:
            o.shape_key_clear()


def decimar(alvo):
    sem_chaves_de_forma()
    antes = triangulos()
    if antes <= alvo:
        return antes, antes
    razao = alvo / antes
    for o in bpy.data.objects:
        if o.type != "MESH" or len(o.data.polygons) < 8:
            continue
        bpy.context.view_layer.objects.active = o
        m = o.modifiers.new(name="decimar", type="DECIMATE")
        m.decimate_type = "COLLAPSE"
        m.ratio = razao
        m.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=m.name)
    return antes, triangulos()


def encolher_texturas(limite):
    """Reduz cada imagem ate caber em `limite` px no lado maior."""
    for img in bpy.data.images:
        if img.size[0] <= 0 or img.size[1] <= 0:
            continue
        maior = max(img.size)
        if maior <= limite:
            continue
        fator = limite / maior
        img.scale(max(1, int(img.size[0] * fator)), max(1, int(img.size[1] * fator)))


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if len(args) < 2:
        print("uso: ... -- ENTRADA/ SAIDA/ [tris] [px_textura]")
        return
    entrada, saida = args[0], args[1]
    alvo = int(args[2]) if len(args) > 2 else ALVO_PADRAO
    limite_textura = int(args[3]) if len(args) > 3 else TEXTURA_PADRAO
    os.makedirs(saida, exist_ok=True)

    nomes = sorted(f for f in os.listdir(entrada) if f.lower().endswith(".glb"))
    print("\n%-26s %10s %10s %10s %10s" % ("modelo", "tris antes", "tris depois", "antes", "depois"))
    for nome in nomes:
        origem = os.path.join(entrada, nome)
        destino = os.path.join(saida, nome)
        limpar()
        bpy.ops.import_scene.gltf(filepath=origem)
        antes, depois = decimar(alvo)
        encolher_texturas(limite_textura)
        bpy.ops.export_scene.gltf(
            filepath=destino,
            export_format="GLB",
            export_materials="EXPORT",
            export_image_format="AUTO",
            export_normals=True,
            export_texcoords=True,
            export_tangents=False,
            export_skins=False,
            export_animations=False,
            export_yup=True,
        )
        print("%-26s %10d %10d %9dK %9dK" % (
            nome, antes, depois,
            os.path.getsize(origem) // 1024, os.path.getsize(destino) // 1024))


main()
