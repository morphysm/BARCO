#!/usr/bin/env python3
"""Faz uma pedra preta e escreve-a como .glb.

    blender --background --python tools/gerar_pedra.py -- SAIDA.glb [semente]

Nao ha modelo de pedra em textures/, e uma pedra e das poucas coisas que
sai melhor gerada que descarregada: e so massa irregular. Feita aqui, sai
com a contagem de triangulos que se quer e sem textura nenhuma a pesar.

Duas decisoes que sao do `assentamento` e nao da geometria:

- NAO e preta a serio, e nao e fosca. Uma pedra preta e fosca, na
  escuridao em que a nganga esta, nao e uma pedra: e um buraco no ecra —
  experimentado, e desaparecia. O que a faz ler e o brilho: preta e
  polida, como pedra de rio, para a chama lhe correr pelas arestas.
- E achatada. Uma pedra assenta, nao equilibra.
"""
import math
import random
import sys

import bmesh
import bpy


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if not args:
        print("uso: ... -- SAIDA.glb [semente]")
        return
    destino = args[0]
    random.seed(int(args[1]) if len(args) > 1 else 7)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    malha = bpy.data.meshes.new("pedra")
    obj = bpy.data.objects.new("pedra", malha)
    bpy.context.collection.objects.link(obj)

    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=3, radius=1.0)

    # Deformar por camadas: uma onda larga da a forma geral, as mais
    # curtas dao as facetas. Ruido por vertice sozinho daria uma bola
    # rugosa, nao uma pedra.
    for v in bm.verts:
        x, y, z = v.co
        r = 1.0
        r += 0.26 * math.sin(1.7 * x + 0.9) * math.cos(1.3 * z - 0.4)
        r += 0.12 * math.sin(3.1 * y + 2.2) * math.cos(2.7 * x + 1.1)
        r += 0.05 * math.sin(6.3 * z + 0.7)
        r += random.uniform(-0.035, 0.035)
        v.co = v.co.normalized() * r

    # Achatada: uma pedra assenta.
    for v in bm.verts:
        v.co.y *= 0.62

    bmesh.ops.triangulate(bm, faces=bm.faces)
    bm.to_mesh(malha)
    bm.free()

    # Facetada, nao lisa: pedra parte-se em planos.
    for p in malha.polygons:
        p.use_smooth = False

    mat = bpy.data.materials.new("pedra_preta")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    # Quase preta, nao preta. Ver o cabecalho.
    bsdf.inputs["Base Color"].default_value = (0.055, 0.053, 0.051, 1.0)
    # Polida: e o reflexo da chama que lhe da forma, nao a cor.
    bsdf.inputs["Roughness"].default_value = 0.22
    bsdf.inputs["Metallic"].default_value = 0.0
    malha.materials.append(mat)

    bpy.ops.export_scene.gltf(
        filepath=destino,
        export_format="GLB",
        export_materials="EXPORT",
        export_normals=True,
        export_texcoords=False,
        export_tangents=False,
        export_skins=False,
        export_animations=False,
        export_yup=True,
    )
    print("pedra: %d triangulos" % len(malha.polygons))


main()
