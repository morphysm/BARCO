## Tela de RISCO. SPEC.md §4, §7.
##
## Tela preta. O dedo deposita `pemba`. O caminho do `ponto` nao e
## mostrado — so as marcas de inicio de segmento (SPEC.md §4.1).
##
## Fatia vertical: sem pagamento, sem servidor, sem `permanencia` ainda.
## Ver SPEC.md §12.
extends Node2D

const MARGEM := 0.92
## Faixas reservadas a pagina impressa: o nome em cima, os rotulos em
## baixo. O `ponto` nunca entra nelas.
const FAIXA_TOPO := 96.0
const FAIXA_BASE := 210.0
const COR_MARCA := Color(0.937, 0.925, 0.882, 0.55)
const COR_GUIA := Color(0.937, 0.925, 0.882, 0.14)
const COR_TINTA := Color(0.937, 0.925, 0.882)

@export var irmandade: Irmandade

var _campo: Node2D
var _guia: Node2D
var _marcas: Node2D
var _tracos_no: Node2D
var _rotulo: Label
var _titulo: Label
var _botao_fechar: Button
var _botao_refazer: Button
var _botao_guia: Button

var _tracos: Array[PackedVector2Array] = []
var _traco_atual: PackedVector2Array = PackedVector2Array()
var _linha_atual: PembaTraco
var _dedo := -1
var _fechado := false

## SPEC.md §4.3: o primeiro contato com cada entidade e um traçado guiado,
## gratuito, sem nota e sem limite. So depois o `ponto` passa a ser
## avaliado.
## Indice da assinatura mostrada no guia; -1 = guia desligado.
var _guiado := 0

## SPEC.md §6.2: quem resolve a `hora_asmodeica` e o servidor, a partir de
## UTC mais `profiles.tz`. O cliente so exibe o que o servidor reporta.
## Enquanto nao ha servidor, isto fica falso — e a chave de depuracao
## abaixo nunca existe fora de build de debug.
var _hora_asmodeica := false


func _ready() -> void:
	if irmandade == null:
		irmandade = load("res://resources/irmandades/calunga_pequena.tres")
	_montar()
	get_viewport().size_changed.connect(_ajustar_campo)
	_ajustar_campo()


func _montar() -> void:
	_campo = Node2D.new()
	add_child(_campo)

	_guia = Node2D.new()
	_guia.draw.connect(_desenhar_guia)
	_campo.add_child(_guia)

	_tracos_no = Node2D.new()
	_campo.add_child(_tracos_no)

	_marcas = Node2D.new()
	_marcas.draw.connect(_desenhar_marcas)
	_campo.add_child(_marcas)

	var folha := CanvasLayer.new()
	add_child(folha)

	_titulo = _texto(irmandade.nome, 34)
	_titulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_titulo.offset_top = 48
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	folha.add_child(_titulo)

	_rotulo = _texto("", 26)
	_rotulo.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_rotulo.offset_top = -190
	_rotulo.offset_bottom = -120
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	folha.add_child(_rotulo)

	var barra := HBoxContainer.new()
	barra.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	barra.offset_top = -104
	barra.offset_bottom = -40
	barra.offset_left = 40
	barra.offset_right = -40
	barra.add_theme_constant_override("separation", 20)
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	folha.add_child(barra)

	# TODO(CONTENT.pt.md): rotulos definitivos sao texto autoral. Ver §2 —
	# descrever o ato, nunca o efeito. Estes sao estruturais.
	_botao_guia = _botao("guia", _alternar_guia)
	_botao_fechar = _botao("fechar o risco", _fechar_risco)
	_botao_refazer = _botao("riscar de novo", _limpar)
	barra.add_child(_botao_guia)
	barra.add_child(_botao_fechar)
	barra.add_child(_botao_refazer)

	_atualizar_rotulo_guia()


func _ajustar_campo() -> void:
	var vista := get_viewport_rect().size
	var ref: Vector2 = _referencia()
	var util := maxf(vista.y - FAIXA_TOPO - FAIXA_BASE, 1.0)
	var escala: float = minf(vista.x * MARGEM / ref.x, util / ref.y)
	_campo.scale = Vector2(escala, escala)
	_campo.position = Vector2(
		(vista.x - ref.x * escala) * 0.5,
		FAIXA_TOPO + (util - ref.y * escala) * 0.5)
	_marcas.queue_redraw()
	_guia.queue_redraw()


# --- captura -----------------------------------------------------------
# SPEC.md §4.1: InputEventScreenDrag amostrado num PackedVector2Array,
# normalizado para a resolucao de referencia antes de qualquer comparacao.

func _unhandled_input(evento: InputEvent) -> void:
	if _fechado:
		return
	if evento is InputEventScreenTouch:
		if evento.pressed and _dedo == -1:
			_dedo = evento.index
			_comecar_traco(_campo.to_local(evento.position))
		elif not evento.pressed and evento.index == _dedo:
			_dedo = -1
			_terminar_traco()
	elif evento is InputEventScreenDrag and evento.index == _dedo:
		_continuar_traco(_campo.to_local(evento.position))


func _comecar_traco(p: Vector2) -> void:
	_traco_atual = PackedVector2Array([p])
	_linha_atual = PembaTraco.new()
	_linha_atual.add_point(p)
	_tracos_no.add_child(_linha_atual)


func _continuar_traco(p: Vector2) -> void:
	if _linha_atual == null:
		return
	# Nao guardar amostras coladas: o dedo parado gera lixo.
	if _traco_atual.is_empty() or _traco_atual[-1].distance_to(p) >= 2.0:
		_traco_atual.append(p)
		_linha_atual.add_point(p)


func _terminar_traco() -> void:
	if _traco_atual.size() > 1:
		_tracos.append(_traco_atual)
	elif _linha_atual != null:
		_linha_atual.queue_free()
	_traco_atual = PackedVector2Array()
	_linha_atual = null


# --- avaliacao ---------------------------------------------------------

func _fechar_risco() -> void:
	if _fechado or _tracos.is_empty():
		return
	if _guiado >= 0:
		# SPEC.md §4.3: primeiro contato nao pontua.
		_limpar()
		return

	_fechado = true
	var r := RiscoScoring.avaliar(_tracos, irmandade, _hora_asmodeica)
	_rotulo.text = _ler(r)


## Diz o que foi feito, nunca o que vai acontecer (CONTENT_pt.md §2).
## Quando o risco nao nomeia ninguem, o app nao explica por que — e nao
## anuncia a `hora_asmodeica` de forma alguma (SPEC.md §5.3, §6.2).
func _ler(r: RiscoResultado) -> String:
	var linhas := ["firmeza %d" % r.firmeza]
	if not r.indefinida and r.entidade_slug != "":
		var e := irmandade.entidade_por_slug(r.entidade_slug)
		if e != null:
			linhas.append(e.nome)
	return "\n".join(linhas)


func _limpar() -> void:
	_fechado = false
	_tracos.clear()
	_traco_atual = PackedVector2Array()
	_linha_atual = null
	_dedo = -1
	for filho in _tracos_no.get_children():
		filho.queue_free()
	_rotulo.text = ""
	_atualizar_rotulo_guia()


## SPEC.md §4.3: o primeiro contato e por entidade. O guia percorre as
## assinaturas da `irmandade` e depois se apaga.
func _alternar_guia() -> void:
	_guiado += 1
	if _guiado >= irmandade.entidades.size():
		_guiado = -1
	_guia.queue_redraw()
	_marcas.queue_redraw()
	_limpar()


func _assinatura_guiada() -> Entidade:
	if _guiado < 0 or _guiado >= irmandade.entidades.size():
		return null
	return irmandade.entidades[_guiado]


func _referencia() -> Vector2:
	for e in irmandade.entidades:
		if e != null and e.ponto_riscado != null:
			return e.ponto_riscado.referencia
	return Vector2(640, 1000)


func _atualizar_rotulo_guia() -> void:
	var e := _assinatura_guiada()
	_rotulo.text = "primeiro contato — %s" % e.nome if e != null else ""


# --- desenho -----------------------------------------------------------

func _desenhar_marcas() -> void:
	# Apenas os inicios de segmento. O caminho, nunca (SPEC.md §4.1).
	#
	# So no primeiro contato: fora dele, as marcas de uma assinatura sao
	# exatamente a resposta que o usuario tem de saber de cor.
	var e := _assinatura_guiada()
	if e == null:
		return
	for m in e.ponto_riscado.marcas_de_inicio():
		_marcas.draw_line(m + Vector2(-9, 0), m + Vector2(9, 0), COR_MARCA, 2.0)
		_marcas.draw_line(m + Vector2(0, -9), m + Vector2(0, 9), COR_MARCA, 2.0)


func _desenhar_guia() -> void:
	var e := _assinatura_guiada()
	if e == null:
		return
	for c in e.ponto_riscado.segmentos:
		_guia.draw_polyline(Polilinha.da_curva(c, 240), COR_GUIA, 2.0)


# --- pagina impressa ---------------------------------------------------
# SPEC.md §11: sem cards, sem sombras suaves, sem cantos arredondados.

func _texto(conteudo: String, tamanho: int) -> Label:
	var l := Label.new()
	l.text = conteudo
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", COR_TINTA)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _botao(rotulo: String, aperto: Callable) -> Button:
	var b := Button.new()
	b.text = rotulo
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", COR_TINTA)
	b.add_theme_color_override("font_hover_color", COR_TINTA)
	b.add_theme_color_override("font_pressed_color", Color.BLACK)
	for estado in ["normal", "hover", "pressed", "focus"]:
		var caixa := StyleBoxFlat.new()
		caixa.bg_color = COR_TINTA if estado == "pressed" else Color(0, 0, 0, 0)
		caixa.border_color = COR_TINTA
		caixa.set_border_width_all(1)
		caixa.set_corner_radius_all(0)
		caixa.content_margin_left = 22
		caixa.content_margin_right = 22
		caixa.content_margin_top = 12
		caixa.content_margin_bottom = 12
		b.add_theme_stylebox_override(estado, caixa)
	b.pressed.connect(aperto)
	return b
