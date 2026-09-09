## Importa os sigilos vetorizados e monta a `irmandade` da
## `calunga_pequena`.
##
## Rodar (depois de tools/extrair_sigilo.py):
##   godot --headless --path client --script res://tools/importar_sigilos.gd
##
## Cada `ponto_riscado` e uma COPIA FIEL do desenho autoral em
## references/. Nada aqui simplifica, resume ou reinventa a geometria: os
## tracos vem medidos de `capturas/<nome>/tracos.json`. O ponto e o
## desenho — e o que se pratica.
##
## Assinaturas nao partilham geometria e nao se compoem umas com as outras
## (SPEC.md §5.1).
extends SceneTree

const PontoDataS := preload("res://scripts/resources/ponto_data.gd")
const EntidadeS := preload("res://scripts/resources/entidade.gd")
const IrmandadeS := preload("res://scripts/resources/irmandade.gd")

## Espaco de referencia da `irmandade`. Todas as assinaturas cabem aqui,
## para que um mesmo traco do dedo signifique o mesmo contra todas.
const COMUM := Vector2(640, 1000)
const MARGEM := 0.96

## TOLERANCE_PX de SPEC.md §4.2, na escala do espaco comum.
const TOLERANCIA := 40.0

const SIGILOS := {
	"exu_caveira": {
		"nome": "Exu Caveira",
		"json": "res://../capturas/caveira/tracos.json",
		"coroa": "astaroth",
		"dominio": ["travessia", "dissolucao", "limiar", "guarda_do_cemiterio"],
		"oferendas": ["marafo", "charuto", "vela_preta"],
		"animal": "",
	},
	"rosa_negra": {
		"nome": "Rosa Negra",
		"json": "res://../capturas/rosa/tracos.json",
		"coroa": "astaroth",
		"dominio": ["luto_convertido_em_poder", "amor_findo", "vinganca_fria", "rainha_das_almas"],
		"oferendas": ["rosas_negras", "perfume", "espelho", "veu", "champanhe", "cigarrilha"],
		"animal": "galinha_preta",
	},
	"exu_aranha": {
		"nome": "Exu Aranha",
		"json": "res://../capturas/aranha/tracos.json",
		"coroa": "lucifer",
		"dominio": ["armadilha", "amarracao", "paciencia", "teia"],
		"oferendas": ["linha_preta", "agulha", "aranha_morta", "mel", "marafo"],
		"animal": "",
	},
}


func _initialize() -> void:
	var entidades: Array[Entidade] = []
	for slug in SIGILOS:
		var e := _importar(slug, SIGILOS[slug])
		if e == null:
			printerr("faltou vetorizar: ", SIGILOS[slug]["json"])
			quit(1)
			return
		entidades.append(e)

	var irm: Irmandade = IrmandadeS.new()
	irm.slug = "calunga_pequena"
	irm.nome = "Calunga Pequena"
	irm.reino = "calunga_pequena"
	# `Exu Caveira` e o rei do cemiterio.
	irm.rei = "exu_caveira"
	irm.entidades = entidades
	assert(ResourceSaver.save(irm, "res://resources/irmandades/calunga_pequena.tres") == OK)

	print("irmandade %s — rei: %s" % [irm.slug, irm.rei])
	for e in entidades:
		print("  %-12s %3d tracos   tolerancia %.1f" % [
			e.slug, e.ponto_riscado.segmentos.size(), e.ponto_riscado.tolerancia_px])
	quit()


## Array[String] tipado a partir de um literal do dicionario acima.
func _texto(bruto: Array) -> Array[String]:
	var saida: Array[String] = []
	for x in bruto:
		saida.append(str(x))
	return saida


func _importar(slug: String, meta: Dictionary) -> Entidade:
	var f := FileAccess.open(meta["json"], FileAccess.READ)
	if f == null:
		return null
	var dados: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()

	var caixa: Dictionary = dados["caixa"]
	var origem := Vector2(float(caixa["x0"]), float(caixa["y0"]))
	var tamanho := Vector2(
		float(caixa["x1"]) - float(caixa["x0"]),
		float(caixa["y1"]) - float(caixa["y0"]))
	# A caixa do desenho cabe inteira no espaco comum, com a proporcao
	# preservada e centrada.
	var escala: float = minf(COMUM.x / tamanho.x, COMUM.y / tamanho.y) * MARGEM
	var desloca := (COMUM - tamanho * escala) * 0.5

	var p: PontoData = PontoDataS.new()
	p.referencia = COMUM
	p.tolerancia_px = TOLERANCIA
	var segmentos: Array[Curve2D] = []
	for bruto in dados["tracos"]:
		var c := Curve2D.new()
		for ponto in bruto:
			c.add_point((Vector2(float(ponto[0]), float(ponto[1])) - origem) * escala + desloca)
		if c.point_count >= 2:
			segmentos.append(c)
	p.segmentos = segmentos
	assert(ResourceSaver.save(p, "res://resources/pontos/%s.tres" % slug) == OK)

	var e: Entidade = EntidadeS.new()
	e.slug = slug
	e.nome = meta["nome"]
	e.coroa = meta["coroa"]
	e.reino = "calunga_pequena"
	e.ponto_riscado = p
	e.dias_semana = [1, 5]        # GDD §11: segunda e sexta como base.
	e.hora_minima = -1
	e.animal_tradicional = meta["animal"]
	e.oferendas_aceitas = _texto(meta["oferendas"])
	e.dominio = _texto(meta["dominio"])
	e.texto_apresentacao = ""     # CONTENT.pt.md §3: [ a escrever ]
	assert(ResourceSaver.save(e, "res://resources/entities/%s.tres" % slug) == OK)
	return e
