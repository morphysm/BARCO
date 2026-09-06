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

import bmesh
import bpy

ALVO_PADRAO = 6000
TEXTURA_PADRAO = 256

## Modelos que nao aguentam o corte normal.
##
## A decimacao por colapso junta vertices vizinhos. Num volume fechado —
## caveira, caldeirao, corrente — isso perde detalhe e mais nada. Numa
## petala, que e uma folha fina com duas faces quase encostadas, junta as
## duas faces e a petala rasga. A rosa a 6 mil triangulos deixava de ser
## uma rosa e passava a ser cacos.
##
## Verificado um a um com tools/ver_modelo.gd: a teia, as velas, as
## correntes, a caveira e o baphomet aguentam os 6 mil sem dar por isso.
ALVOS = {
	# A rosa nao se decima de todo. Petalas e folhas sao folhas finas de
	# duas faces encostadas, e qualquer corte junta as duas e rasga-as —
	# a 12 mil ainda ficavam furos por toda a folhagem. Soldada, cabe em
	# 1,9 MB inteira, praticamente o mesmo que custava rasgada.
	# Decimar destroi as normais de origem, mas isso resolve-se refazendo o
	# sombreado suave a seguir (ver `refazer_sombreado`). O que nao se pode
	# e deixar normais partidas: era isso o salpicado.
	"black_rose": 20000,
}

## Modelos que precisam de mais textura que os 256 px do costume.
##
## 256 chegam para reconhecer um objeto no editor e para uma superficie
## lisa. Nao chegam para folhagem: as folhas da rosa tem nervuras, e a
## essa resolucao saem manchadas.
## A rosa nao pode ser aliviada na geometria — traz normais proprias, e
## soldar ou decimar apaga-as. O unico sitio onde ainda se pode poupar sao
## as texturas, e 256 chegam: o que a estragava nunca foi a resolucao.
TEXTURAS = {}

## Modelos a quem se tira o mapa de rugosidade, ficando com um valor fixo.
##
## A rosa traz o mapa metalico/rugosidade num segundo conjunto de UVs,
## diferente do da cor. O glTF permite; o Godot nao — amostra-o com as UVs
## erradas, e o brilho fica a saltar pelas folhas em manchas. O proprio
## Blender avisa disto ao importar. Sem o mapa e com rugosidade fixa, as
## folhas ficam foscas como folhas.
RUGOSIDADE_FIXA = {}

## Modelos a quem se tira a textura de cor, ficando com uma cor unica.
##
## A rosa vem de fotogrametria: a textura de cor e um atlas de fotografias
## de folhas sobrepostas, com manchas cinzentas e buracos escuros. A
## candeia so faz realcar essa confusao — as folhas ficam malhadas de
## amarelo e branco, que e tudo menos uma rosa negra.
##
## Sem textura e com uma cor escura, o que se ve e a forma: petala, folha,
## caule, apanhados pela chama nas arestas. Que e o que a paleta do Barco
## pede (SPEC.md §11).
COR_FIXA = {}


def limpar():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def triangulos():
    total = 0
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.data.calc_loop_triangles()
            total += len(o.data.loop_triangles)
    return total


def normais_proprias(o):
    """Se a malha traz normais gravadas de origem.

    Modelos de digitalizacao trazem normais por vertice que nao se podem
    recalcular a partir da geometria: e nelas que assenta o sombreado. Soldar
    vertices apaga-as, e recalcular substitui-as — nos dois casos a folhagem
    parte-se num salpicado de preto e ouro. Foi o que aconteceu a rosa.
    """
    d = o.data
    for atrib in ("has_custom_normals", "use_auto_smooth"):
        if getattr(d, atrib, False):
            return True
    return False


def soldar():
    """Junta vertices coincidentes.

    Estes modelos vem quase todos sem indice: cada triangulo traz os seus
    tres vertices, e um vertice partilhado por seis faces aparece seis
    vezes. Soldar corta o ficheiro para um quarto sem perder um
    triangulo — a rosa passa de 7,8 MB para 1,9 MB.

    E tem de ser ANTES de decimar: sem soldar, o colapso nao consegue
    seguir a malha atraves das costuras e rasga-a. Foi assim que a rosa
    ficou em cacos.
    """
    for o in bpy.data.objects:
        if o.type != "MESH" or normais_proprias(o):
            continue
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0001)
        bm.to_mesh(o.data)
        bm.free()


def fixar_rugosidade(valor):
    """Corta o mapa de rugosidade/metalico e poe um valor unico."""
    for mat in bpy.data.materials:
        if not mat.use_nodes:
            continue
        bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bsdf is None:
            continue
        for nome in ("Roughness", "Metallic", "Specular IOR Level"):
            if nome not in bsdf.inputs:
                continue
            for link in list(bsdf.inputs[nome].links):
                mat.node_tree.links.remove(link)
        bsdf.inputs["Roughness"].default_value = valor
        bsdf.inputs["Metallic"].default_value = 0.0


def fixar_cor(cor):
    """Corta a textura de cor e poe uma cor unica."""
    for mat in bpy.data.materials:
        if not mat.use_nodes:
            continue
        bsdf = next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if bsdf is None:
            continue
        for link in list(bsdf.inputs["Base Color"].links):
            mat.node_tree.links.remove(link)
        bsdf.inputs["Base Color"].default_value = cor
    for img in list(bpy.data.images):
        bpy.data.images.remove(img)


def endireitar_normais():
    """Poe todas as faces viradas para o mesmo lado.

    Modelos de fotogrametria vem com a orientacao das faces baralhada: na
    rosa, metade das faces de cada malha apontavam para dentro. Uma face
    virada ao contrario acende como se estivesse de costas para a chama, e
    fica preta — espalhadas pela folhagem, dao aquele salpicado de preto e
    ouro que nao era textura nenhuma.

    E marca o material como de dois lados: uma folha e uma folha fina, e
    vista por tras tem de continuar la.
    """
    for o in bpy.data.objects:
        if o.type != "MESH" or normais_proprias(o):
            continue
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(o.data)
        bm.free()
    for mat in bpy.data.materials:
        mat.use_backface_culling = False


def refazer_sombreado(malhas):
    """Depois de decimar, poe sombreado suave limpo — SO onde e preciso.

    A decimacao invalida as normais gravadas de origem: ficam a apontar
    para sitios que a geometria ja nao tem, e a folhagem parte-se num
    salpicado. Recalcular um sombreado suave e simples devolve superficies
    inteiras — menos fino que o original, mas certo.

    Feito isto, a malha deixa de ter normais proprias e ja pode ser
    soldada, que e onde esta a poupanca de tamanho.

    So mexe nas malhas que TINHAM normais proprias: as outras ficam com o
    sombreado que o autor lhes deu. Forcar suave em tudo mudava o aspeto
    de metade dos modelos sem que ninguem o tivesse pedido — parecia que a
    luz da cena tinha mudado, e nao tinha.
    """
    for o in malhas:
        if o.type != "MESH":
            continue
        if hasattr(o.data, "free_normals_split"):
            o.data.free_normals_split()
        for p in o.data.polygons:
            p.use_smooth = True


def animado():
    """Um modelo com esqueleto ou accoes nao se decima.

    A decimacao por colapso junta vertices, e os pesos que prendem cada
    vertice ao osso nao sobrevivem a isso: a aranha andaria aos solavancos
    ou nao andaria de todo. Um bicho de catorze mil triangulos tambem nao
    precisa de corte nenhum.
    """
    return len(bpy.data.actions) > 0 or any(o.type == "ARMATURE" for o in bpy.data.objects)




def sem_chaves_de_forma():
    """Fora as shape keys: o modificador nao se aplica com elas, e nada no
    `assentamento` anima."""
    for o in bpy.data.objects:
        if o.type == "MESH" and o.data.shape_keys:
            o.shape_key_clear()
    # Tirar as chaves nao tira a accao que lhes estava presa: ela fica
    # orfa em bpy.data.actions e faz o modelo passar por animado. Foi
    # assim que a vela branca deixou de ser decimada e engordou dez vezes.
    for a in list(bpy.data.actions):
        if a.users == 0:
            bpy.data.actions.remove(a)


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
        sem_chaves_de_forma()
        var_animado = animado()
        if var_animado:
            antes = depois = triangulos()
        else:
            com_normais = [o for o in bpy.data.objects
                    if o.type == "MESH" and normais_proprias(o)]
            antes, depois = decimar(ALVOS.get(os.path.splitext(nome)[0], alvo))
            if depois != antes and com_normais:
                refazer_sombreado(com_normais)
        # Depois do sombreado refeito: quem ja nao tem normais proprias
        # pode ser soldado e endireitado sem perder nada.
        soldar()
        endireitar_normais()
        base = os.path.splitext(nome)[0]
        if base in RUGOSIDADE_FIXA:
            fixar_rugosidade(RUGOSIDADE_FIXA[base])
        if base in COR_FIXA:
            fixar_cor(COR_FIXA[base])
        encolher_texturas(TEXTURAS.get(base, limite_textura))
        bpy.ops.export_scene.gltf(
            filepath=destino,
            export_format="GLB",
            export_materials="EXPORT",
            export_image_format="AUTO",
            export_normals=True,
            export_texcoords=True,
            export_tangents=False,
            export_skins=var_animado,
            export_animations=var_animado,
            export_yup=True,
        )
        print("%-26s %10d %10d %9dK %9dK%s" % (
            nome, antes, depois,
            os.path.getsize(origem) // 1024, os.path.getsize(destino) // 1024,
            "  (animado: nao decimado)" if var_animado else ""))


main()
