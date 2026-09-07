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
const FAIXA_BASE := 246.0
const COR_MARCA := Color(0.937, 0.925, 0.882, 0.55)
const COR_GUIA := Color(0.937, 0.925, 0.882, 0.14)
const COR_TINTA := Color(0.937, 0.925, 0.882)
## O vermelho da recusa. `pemba` vermelha, nao vermelho de aviso de
## software (GLOSSARY: a pemba e branca ou vermelha).
const COR_RECUSA := Color(0.78, 0.18, 0.14)

@export var irmandade: Irmandade

var _campo: Node2D
var _guia: Node2D
var _marcas: Node2D
var _tracos_no: Node2D
var _rotulo: Label
var _titulo: Label
var _lugar: Label
var _botao_fechar: Button
var _botao_refazer: Button

var _tracos: Array[PackedVector2Array] = []
var _traco_atual: PackedVector2Array = PackedVector2Array()
var _linha_atual: PembaTraco
var _dedo := -1
var _fechado := false

## O `ponto` que esta a frente. O guia esta SEMPRE ligado: sem ele o
## campo e uma folha preta, e uma folha preta nao ensina ninguem a riscar.
##
## Nao ha como desliga-lo e nao ha por onde escolher outro — ha o ponto
## que esta a frente, e passa-se ao seguinte riscando este.
var _ponto: Entidade

## O compasso de espera entre o "podes" e o eclipse.
var _a_passar := false
var _espera := 0.0

## Quanto se ve o ultimo risco antes de o sol comecar a ser tapado. O
## resultado tem de assentar; a passagem nao lhe rouba o lugar.
const ESPERA_ATE_AO_ECLIPSE := 2.6

## SPEC.md §6.2: quem resolve a `hora_asmodeica` e o servidor, a partir de
## UTC mais `profiles.tz`. O cliente so exibe o que o servidor reporta.
## Enquanto nao ha servidor, isto fica falso — e a chave de depuracao
## abaixo nunca existe fora de build de debug.
var _hora_asmodeica := false


func _ready() -> void:
	# Atravessa-se uma vez. Quem ja passou abre no `assentamento`.
	if not Engine.is_editor_hint() and Passagem.completa(irmandade):
		call_deferred("_ir_para_o_assentamento")
		return
	if irmandade == null:
		irmandade = load("res://resources/irmandades/calunga_pequena.tres")
	_montar()
	get_viewport().size_changed.connect(_ajustar_campo)
	_ajustar_campo()


func _ir_para_o_assentamento() -> void:
	get_tree().change_scene_to_file("res://scenes/assentamento.tscn")


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

	# Em cima, sempre o nome da entidade. Em baixo, o lugar que ela
	# responde. Enquanto nao se sabe quem atendeu, o alto fica vazio: nao
	# se anuncia uma entidade antes de o risco a nomear.
	_titulo = _texto("", 34)
	_titulo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_titulo.offset_top = 48
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	folha.add_child(_titulo)

	_rotulo = _texto("", 26)
	_rotulo.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_rotulo.offset_top = -222
	_rotulo.offset_bottom = -164
	_rotulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	folha.add_child(_rotulo)

	_lugar = _texto(irmandade.nome, 22)
	_lugar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_lugar.offset_top = -158
	_lugar.offset_bottom = -122
	_lugar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	folha.add_child(_lugar)

	var barra := HBoxContainer.new()
	barra.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	barra.offset_top = -110
	barra.offset_bottom = -46
	barra.offset_left = 40
	barra.offset_right = -40
	barra.add_theme_constant_override("separation", 20)
	barra.alignment = BoxContainer.ALIGNMENT_CENTER
	folha.add_child(barra)

	# TODO(CONTENT.pt.md): rotulos definitivos sao texto autoral. Ver §2 —
	# descrever o ato, nunca o efeito. Estes sao estruturais.
	_botao_fechar = _botao("posso passar?", _fechar_risco)
	_botao_refazer = _botao("riscar de novo", _limpar)
	barra.add_child(_botao_fechar)
	barra.add_child(_botao_refazer)

	# O ponto da vez. A ordem e a da `irmandade`.
	_ponto = Passagem.proximo(irmandade)
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

## A pergunta ao guia: "posso passar?"
##
## Mede-se contra O PONTO QUE ESTA A FRENTE, nao contra a melhor
## assinatura das tres: a pergunta nao e "quem atendeu?", e "risquei o
## que me foi posto?".
##
## Riscado o suficiente, o guia poe o seguinte. Riscado o terceiro, o
## eclipse. Abaixo do limiar, a resposta e nao, em vermelho.
func _fechar_risco() -> void:
	if _fechado or _tracos.is_empty() or _ponto == null:
		return

	var m := RiscoScoring.medir(_tracos, _ponto.ponto_riscado)
	var cobertura: float = m.get("cobertura", 0.0)

	if cobertura < Passagem.COBERTURA_PARA_PASSAR:
		# TODO(CONTENT.pt.md): texto autoral. Este e estrutural.
		_rotulo.text = "Ainda não, risca mais!"
		_rotulo.add_theme_color_override("font_color", COR_RECUSA)
		return

	_fechado = true
	Passagem.passar(_ponto.slug)
	var seguinte := Passagem.proximo(irmandade)
	if seguinte == null:
		_rotulo.remove_theme_color_override("font_color")
		_rotulo.text = ""
		_a_passar = true
		_espera = 0.0
		set_process(true)
		return

	# Empurra para o seguinte: o guia troca de desenho e a pessoa
	# continua, sem ter de carregar em nada.
	_ponto = seguinte
	_rotulo.remove_theme_color_override("font_color")
	_limpar()
	_ajustar_campo()
	_guia.queue_redraw()
	_marcas.queue_redraw()
	# TODO(CONTENT.pt.md): texto autoral. Este e estrutural.
	_rotulo.text = "agora o ponto de %s" % seguinte.nome


## Riscado o terceiro, o eclipse. Nao ha botao: o resultado assenta e
## atravessa-se, e daqui nao se volta.
func _process(delta: float) -> void:
	if not _a_passar:
		set_process(false)
		return
	_espera += delta
	if _espera >= ESPERA_ATE_AO_ECLIPSE:
		_a_passar = false
		set_process(false)
		get_tree().change_scene_to_file("res://scenes/eclipse.tscn")


## Diz o que foi feito, nunca o que vai acontecer (CONTENT_pt.md §2).
## Quando o risco nao nomeia ninguem, o app nao explica por que — e nao
## anuncia a `hora_asmodeica` de forma alguma (SPEC.md §5.3, §6.2).
func _ler(r: RiscoResultado) -> String:
	# Quem atendeu vai para o alto, nao para aqui. Quando ninguem atendeu,
	# o alto fica vazio — o app nao revela nada (SPEC.md §5.3).
	var e: Entidade = null
	if not r.indefinida and not r.abandonado and r.entidade_slug != "":
		e = irmandade.entidade_por_slug(r.entidade_slug)
	_titulo.text = e.nome if e != null else ""
	return "firmeza %d" % r.firmeza


func _limpar() -> void:
	_fechado = false
	_titulo.text = ""
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
func _assinatura_guiada() -> Entidade:
	return _ponto


func _referencia() -> Vector2:
	for e in irmandade.entidades:
		if e != null and e.ponto_riscado != null:
			return e.ponto_riscado.referencia
	return Vector2(640, 1000)


## O alto diz de quem e o `ponto` que esta a frente; o baixo diz o que
## fazer com ele. Aqui nao ha nada a descobrir — ha um desenho a
## completar, e o guia acompanha.
func _atualizar_rotulo_guia() -> void:
	_titulo.text = _ponto.nome if _ponto != null else ""
	if _rotulo == null:
		return
	_rotulo.remove_theme_color_override("font_color")
	# TODO(CONTENT.pt.md): texto autoral. Estes sao estruturais.
	_rotulo.text = "risca o ponto, depois pergunta" if _ponto != null else ""


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
