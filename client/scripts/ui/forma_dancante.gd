## Uma forma que danca diante do fogo.
##
## Arquitectura copiada do `Hall_of_Repetition` do `Iovana Is DEAD`
## (references/hall_of_repetion_procedural_architeture.md): um `Node3D`
## por figura, corpo gerado em tempo de execucao a partir de primitivas,
## juntas calculadas a cada frame, e um corpo-eco deslocado por tras do
## primeiro. Sem `Skeleton3D`, sem `AnimationTree`, sem rig.
##
## O documento diz para NAO recriar a danca do Hall nos aldeoes de
## `BODY OF MINE`, que se movem contidos. Aqui e ao contrario: e a danca
## que se quer. A arquitectura e a mesma; o movimento nao.
##
## Cada figura recebe valores proprios e nunca se sincronizam.
##
## E `@tool`: desenha-se e danca no editor, para se poder escolher a cor
## e a luz a olhar em vez de adivinhar. Na cena ha uma destas por figura,
## em `Dancantes` — sao nos a serio, cada um com os seus valores.
@tool
class_name FormaDancante
extends Node3D

## O que desencontra esta figura de todas as outras.
@export var semente := 1.0
@export var ritmo := 1.0
@export var tamanho := 1.0
@export var espelhar := false
## Quanto o corpo-eco se afasta do primeiro.
@export var eco := 0.03
## Luz eletrica azul. O `a` da cor e a opacidade da figura.
@export var cor := Color(0.16, 0.44, 0.95, 0.9):
	set(v):
		cor = v
		_afinar()
@export var cor_da_borda := Color(0.62, 0.92, 1.0):
	set(v):
		cor_da_borda = v
		_afinar()
## Quanta luz a figura deita. Baixar torna-a discreta contra o fogo.
@export_range(0.0, 3.0) var brilho := 1.0:
	set(v):
		brilho = v
		_afinar()
## Quanto a figura se acende so nas bordas — alto e mais oco, mais
## fantasma.
@export_range(0.5, 6.0) var contorno := 1.5:
	set(v):
		contorno = v
		_afinar()
## Quanto a figura se acende por dentro, e nao so na borda.
@export_range(0.0, 1.0) var miolo := 0.34:
	set(v):
		miolo = v
		_afinar()
## O tremor eletrico.
@export_range(0.0, 1.0) var faisca := 0.35:
	set(v):
		faisca = v
		_afinar()
## Ate que altura a bruma come a figura, a contar do chao.
@export_range(0.0, 2.0) var bruma := 0.62:
	set(v):
		bruma = v
		_afinar()

## Quanto da danca esta a acontecer, de 0 (parada) a 1 (inteira). E o que
## faz as formas entrarem com o fogo em vez de ja la estarem.
##
## No editor esta sempre a 1: uma figura parada e invisivel de mais para
## se lhe escolher a cor.
var vigor := 0.0

const OSSOS := [
	["coxa_esq", "anca_esq", "joelho_esq", 0.052],
	["perna_esq", "joelho_esq", "pe_esq", 0.042],
	["coxa_dir", "anca_dir", "joelho_dir", 0.052],
	["perna_dir", "joelho_dir", "pe_dir", 0.042],
	["braco_esq", "ombro_esq", "cotovelo_esq", 0.040],
	["antebraco_esq", "cotovelo_esq", "mao_esq", 0.032],
	["braco_dir", "ombro_dir", "cotovelo_dir", 0.040],
	["antebraco_dir", "cotovelo_dir", "mao_dir", 0.032],
	["tronco", "bacia", "peito", 0.105],
	# Sem esta barra os bracos comecavam no vazio ao lado do tronco e
	# liam-se como lascas soltas. E ela que os prende ao corpo.
	["ombros", "ombro_esq", "ombro_dir", 0.078],
	["pescoco", "peito", "cabeca", 0.045],
]

var _primario: Node3D
var _eco: Node3D
var _segmentos := {}
var _bolas := {}
var _mat: ShaderMaterial
var _tempo := 0.0


func _ready() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/forma.gdshader")
	_mat.set_shader_parameter("cor_nucleo", Color(cor.r, cor.g, cor.b))
	_mat.set_shader_parameter("cor_borda", cor_da_borda)
	_mat.set_shader_parameter("contorno", contorno)
	_mat.set_shader_parameter("faisca", faisca)
	_mat.set_shader_parameter("bruma", bruma)
	_mat.set_shader_parameter("fase", semente)
	if Engine.is_editor_hint():
		vigor = 1.0
	_primario = _montar_corpo("Primario", 1.0)
	# §29: o segundo corpo fica um pouco fora do primeiro. E ele que faz a
	# figura tremer sem se mexer.
		# §30: o eco anda entre 0.05 e 0.10 em repouso. Estava em 0.42 com um
	# atraso grande, e como os bracos se mexem depressa o eco ficava
	# meio metro ao lado do corpo — liam-se como lascas soltas a flutuar,
	# nao como tremor.
	_eco = _montar_corpo("Eco", 0.16)
	_eco.position = Vector3((1.0 if not espelhar else -1.0) * eco, 0.017, 0.046)
	set_process(true)


## Repoe os valores nos materiais. Chamado por cada `@export` para se ver
## a mudanca no editor sem fechar e abrir a cena.
func _afinar() -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter("cor_nucleo", Color(cor.r, cor.g, cor.b))
	_mat.set_shader_parameter("cor_borda", cor_da_borda)
	_mat.set_shader_parameter("contorno", contorno)
	_mat.set_shader_parameter("miolo", miolo)
	_mat.set_shader_parameter("faisca", faisca)
	_mat.set_shader_parameter("bruma", bruma)
	_mat.set_shader_parameter("brilho", brilho)
	for corpo in [_primario, _eco]:
		if corpo == null:
			continue
		var op: float = cor.a * (1.0 if corpo == _primario else 0.16)
		for filho in corpo.get_children():
			var m = (filho as MeshInstance3D).material_override
			if m is ShaderMaterial:
				m.set_shader_parameter("cor_nucleo", Color(cor.r, cor.g, cor.b))
				m.set_shader_parameter("cor_borda", cor_da_borda)
				m.set_shader_parameter("contorno", contorno)
				m.set_shader_parameter("miolo", miolo)
				m.set_shader_parameter("faisca", faisca)
				m.set_shader_parameter("bruma", bruma)
				m.set_shader_parameter("brilho", brilho)
				m.set_shader_parameter("opacidade", op)


func _montar_corpo(nome: String, opacidade: float) -> Node3D:
	var corpo := Node3D.new()
	corpo.name = nome
	add_child(corpo)

	var m: ShaderMaterial = _mat.duplicate()
	m.set_shader_parameter("opacidade", cor.a * opacidade)

	for osso in OSSOS:
		var seg := MeshInstance3D.new()
		seg.name = osso[0]
		var cil := CylinderMesh.new()
		# Raio 0.5 e altura 1: um cilindro de DIAMETRO unitario, que e com
		# o que a formula do documento conta (`radius * 2.0` na escala).
		# Com raio 1 os membros saiam com o dobro da grossura e liam-se
		# como blocos, nao como bracos.
		cil.top_radius = 0.5
		cil.bottom_radius = 0.5
		cil.height = 1.0
		cil.radial_segments = 14
		cil.rings = 2
		seg.mesh = cil
		seg.material_override = m
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		corpo.add_child(seg)
		_segmentos[nome + "/" + osso[0]] = seg

	for par in [["bacia", 0.10], ["peito", 0.125], ["cabeca", 0.088]]:
		var b := MeshInstance3D.new()
		b.name = par[0]
		var esf := SphereMesh.new()
		esf.radius = par[1]
		esf.height = par[1] * 2.0
		esf.radial_segments = 14
		esf.rings = 8
		b.mesh = esf
		b.material_override = m
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		corpo.add_child(b)
		_bolas[nome + "/" + par[0]] = b

	return corpo


## §15: um cilindro entre duas juntas. E a regra central da construcao.
func _por_segmento(seg: MeshInstance3D, a: Vector3, b: Vector3, raio: float) -> void:
	var delta := b - a
	var comp := delta.length()
	if comp <= 0.001:
		seg.visible = false
		return
	seg.visible = true
	var eixo_y := delta / comp
	var ajuda := Vector3.FORWARD
	if absf(eixo_y.dot(Vector3.FORWARD)) >= 0.94:
		ajuda = Vector3.RIGHT
	var eixo_x := ajuda.cross(eixo_y).normalized()
	var eixo_z := eixo_x.cross(eixo_y).normalized()
	# Os eixos ja saem escalados, em vez de `Basis.scaled()`.
	#
	# O documento usa `.scaled()`, mas no Godot 4 esse metodo multiplica as
	# LINHAS da base, nao os eixos: para uma base rodada isso escala nos
	# eixos do mundo e nao nos da peca. Um braco na diagonal saia esmagado
	# — curto e grosso — e liam-se como lascas soltas ao lado do corpo em
	# vez de bracos presos ao ombro.
	seg.transform = Transform3D(
		Basis(eixo_x * (raio * 2.0), eixo_y * comp, eixo_z * (raio * 2.0)),
		(a + b) * 0.5)


func _process(delta: float) -> void:
	_tempo += delta
	# §17: a fase da o movimento assincrono.
	var f := _tempo * 3.25 * ritmo + semente * 2.11
	var juntas := _juntas(f)
	_vestir(_primario, juntas)
	_vestir(_eco, _juntas(f - 0.035))
	scale = Vector3.ONE * tamanho


func _vestir(corpo: Node3D, j: Dictionary) -> void:
	for osso in OSSOS:
		var seg: MeshInstance3D = _segmentos[corpo.name + "/" + osso[0]]
		_por_segmento(seg, j[osso[1]], j[osso[2]], osso[3])
	for nome in ["bacia", "peito", "cabeca"]:
		_bolas[corpo.name + "/" + nome].position = j[nome]


## As juntas, calculadas — nao animadas. §14.
##
## Isto e danca e nao o andar contido dos aldeoes: a bacia roda, o peito
## contra-roda, os bracos sobem acima da cabeca e o peso passa de um pe
## para o outro.
func _juntas(f: float) -> Dictionary:
	var e := 1.0 if not espelhar else -1.0
	var v := vigor
	var balanco := sin(f * 0.5) * v
	var passo := sin(f) * v

	var bacia := Vector3(
		sin(f * 0.5 + semente) * 0.16 * v,
		0.88 + absf(sin(f)) * 0.055 * v,
		cos(f * 0.42 + semente) * 0.09 * v)
	var peito := bacia + Vector3(
		-sin(f * 0.5 + semente) * 0.12 * v,
		0.44 + cos(f * 1.1) * 0.02 * v,
		sin(f * 0.6) * 0.05 * v)
	var cabeca := peito + Vector3(
		sin(f * 0.7 + 1.3) * 0.06 * v,
		0.24,
		cos(f * 0.55) * 0.04 * v)

	var ombro := 0.155
	var anca := 0.105

	# Os bracos sobem: uma danca de bracos ao alto, nao de bracos caidos.
	var alto_esq := 0.55 + 0.45 * sin(f + semente)
	var alto_dir := 0.55 + 0.45 * sin(f + semente + PI * 0.75)

	var j := {}
	j["bacia"] = bacia
	j["peito"] = peito
	j["cabeca"] = cabeca

	j["ombro_esq"] = peito + Vector3(-ombro * e, 0.10, 0.0)
	j["ombro_dir"] = peito + Vector3(ombro * e, 0.10, 0.0)
	# Os bracos tem de ter comprimento de braco e de PODER descer: antes
	# eram curtos e estavam sempre por cima dos ombros, e liam-se como
	# lascas soltas ao lado do corpo em vez de bracos.
	#
	# `alto` = 0 -> caidos ao longo do corpo; = 1 -> ao alto.
	j["cotovelo_esq"] = j["ombro_esq"] + Vector3(
		-(0.10 + 0.20 * alto_esq) * e,
		-0.30 + 0.52 * alto_esq * v,
		0.07 * sin(f * 1.3))
	j["cotovelo_dir"] = j["ombro_dir"] + Vector3(
		(0.10 + 0.20 * alto_dir) * e,
		-0.30 + 0.52 * alto_dir * v,
		0.07 * sin(f * 1.3 + 2.0))
	j["mao_esq"] = j["cotovelo_esq"] + Vector3(
		-(0.04 + 0.12 * alto_esq) * e,
		-0.28 + 0.50 * alto_esq * v,
		0.10 * cos(f * 1.7))
	j["mao_dir"] = j["cotovelo_dir"] + Vector3(
		(0.04 + 0.12 * alto_dir) * e,
		-0.28 + 0.50 * alto_dir * v,
		0.10 * cos(f * 1.7 + 1.4))

	j["anca_esq"] = bacia + Vector3(-anca * e, -0.03, 0.0)
	j["anca_dir"] = bacia + Vector3(anca * e, -0.03, 0.0)
	# O peso passa de um pe para o outro: um joelho dobra enquanto o outro
	# estica.
	j["joelho_esq"] = j["anca_esq"] + Vector3(
		-0.03, -0.40 + 0.05 * maxf(passo, 0.0), 0.10 * passo)
	j["joelho_dir"] = j["anca_dir"] + Vector3(
		0.03, -0.40 + 0.05 * maxf(-passo, 0.0), -0.10 * passo)
	j["pe_esq"] = j["joelho_esq"] + Vector3(
		0.0, -0.42 + 0.09 * maxf(passo, 0.0) * v, 0.16 * passo)
	j["pe_dir"] = j["joelho_dir"] + Vector3(
		0.0, -0.42 + 0.09 * maxf(-passo, 0.0) * v, -0.16 * passo)

	# O balanco inteiro, a inclinar a figura.
	if absf(balanco) > 0.0:
		rotation.z = balanco * 0.06 * e
	return j
