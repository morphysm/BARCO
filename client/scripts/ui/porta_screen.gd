## A PORTA. A primeira coisa que o app mostra depois de instalado, antes
## de qualquer outra coisa carregar.
##
## Nao e a porta do §1.1 do SPEC — essa e o limiar de cobertura que deixa
## passar de um `ponto` para o seguinte, e nao tem tela nenhuma. Esta e a
## Porta que o texto nomeia: onde se deixa tudo e se entra.
##
## Terminal monocromatico de anos 90: branco sobre preto, um canal de cor
## so, letra de matriz de pontos. Nada aqui e decorativo — o app pergunta
## uma coisa a serio antes de deixar entrar, e a tela e o tom da
## pergunta.
##
## Atravessa-se uma vez. Quem entrou nao volta a ser perguntado; quem
## desiste fecha o app e a Porta continua fechada, entao da proxima vez
## esta ca outra vez.
extends Control

## O texto e de A.C. e nao se toca: nem uma virgula, nem uma quebra de
## linha. `CONTENT_pt.md` manda.
const RITUAL := """Você entrará rápido neste reino e sairá rápido —
transformado em outro alguém, ou em outra coisa.
Antes de entrar, responsabilize-se pela sua escolha.
Algumas escolhas, como esta, não têm volta —
mesmo sendo só um app."""

const ENTRAR := "Deixo tudo na Porta e entro."
const DESISTIR := "Desisto e apago o app."

## As linhas de arranque. Sao cenario, nao sao conteudo do ritual: o que
## dizem e que a maquina esta a acordar.
const ARRANQUE := [
	"INITIALIZING...",
	"LOADING REINO.SYS...",
	"CONEXÃO ESTABELECIDA",
]

## Atribuicao do tipo de letra. E exigencia da licenca (CC BY-SA 4.0),
## nao e um agradecimento: sai daqui so quando a letra sair com ela.
const CREDITO := "IBM PC font courtesy of int10h.org / VileR, CC BY-SA 4.0"

## O atabaque por baixo da Porta. Toca UMA vez, do princípio, e acaba —
## sao 50 segundos com um fim a serio, nao um ciclo. Quem ficar mais
## tempo a decidir fica em silencio com a pergunta, e isso e justo.
##
## Nao toca para quem ja atravessou: essa pessoa nao ve esta tela.
@export var atabaque: AudioStream = preload(
	"res://resources/audio/INTRO_Solo de Atabaque.ogg")
## Por BAIXO, nao por cima. A gravacao vem a nivel normal (media de
## -20 dB), portanto sem isto ficava a frente do que a tela esta a dizer.
@export_range(-40.0, 6.0) var volume_do_atabaque := -6.0

const LETRA := "res://resources/fonts/PxPlus_IBM_VGA8.ttf"
## A letra e de 8x16 pixeis. Em multiplos de 16 cada pixel dela cai
## inteiro num quadrado de pixeis do ecra; fora disso esborrata.
const CORPO := 32
const CORPO_DO_CREDITO := 16

## A tinta do app (a mesma do `risco`): osso, nao branco de escritorio.
const TINTA := Color(0.937, 0.925, 0.882)
const TINTA_FRACA := Color(0.937, 0.925, 0.882, 0.35)

## Letras por segundo da maquina de escrever.
const VELOCIDADE := 46.0
## A pausa antes da ULTIMA linha. E a viragem de tom da frase — "mesmo
## sendo so um app" desmonta tudo o que veio antes — e uma frase que
## desmonta precisa do silencio de quem vai dizer outra coisa. Sem isto
## sai no mesmo folego que o resto e nao se ouve.
const PAUSA_ANTES_DO_FIM := 1.7
## Quanto tempo cada linha de arranque fica antes da seguinte.
const PASSO_DO_ARRANQUE := 0.34
const PAUSA_DEPOIS_DO_ARRANQUE := 0.55
## O piscar do cursor e do marcador do menu.
const PISCA := 0.53

var _fundo: ColorRect
var _arranque: Label
var _texto: RichTextLabel
var _cursor: Label
var _menu: HBoxContainer
var _opcoes: Array[Button] = []
var _escolhida := 0
var _aceso := true
var _a_espera := false
var _decidido := false


func _ready() -> void:
	if not Engine.is_editor_hint() and Passagem.atravessou():
		call_deferred("_seguir_em_frente")
		return
	_montar()
	_correr()


func _seguir_em_frente() -> void:
	get_tree().change_scene_to_file("res://scenes/risco.tscn")


## A letra. Vem crua de proposito: a suavizacao esta desligada no
## `.import` (`antialiasing=0`), e o Godot ja lhe desliga o
## posicionamento sub-pixel e o `hinting` sozinho, porque reconhece uma
## letra de matriz de pontos ao importa-la. Uma letra destas suavizada
## deixa de ser de matriz de pontos: fica um borrao com forma de letra.
func _tipo_de_letra() -> FontFile:
	return load(LETRA)


func _montar() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var letra := _tipo_de_letra()

	_fundo = ColorRect.new()
	_fundo.color = Color.BLACK
	_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fundo)

	# O bloco todo: arranque, texto, cursor, menu. As linhas alinham a
	# esquerda como num terminal, mas o BLOCO fica ao centro do ecra —
	# encostado a margem apanhava a franja de cor do vidro, que so existe
	# nas bordas, e o texto saía com as letras desalinhadas de cor.
	var meio := CenterContainer.new()
	meio.set_anchors_preset(Control.PRESET_FULL_RECT)
	meio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(meio)

	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 26)
	coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meio.add_child(coluna)

	_arranque = Label.new()
	_arranque.add_theme_font_override("font", letra)
	_arranque.add_theme_font_size_override("font_size", CORPO)
	_arranque.add_theme_color_override("font_color", TINTA_FRACA)
	_arranque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_arranque)

	_texto = RichTextLabel.new()
	_texto.bbcode_enabled = false
	_texto.scroll_active = false
	_texto.fit_content = true
	_texto.text = RITUAL
	_texto.visible_ratio = 0.0
	_texto.add_theme_font_override("normal_font", letra)
	_texto.add_theme_font_size_override("normal_font_size", CORPO)
	_texto.add_theme_color_override("default_color", TINTA)
	_texto.add_theme_constant_override("line_separation", 10)
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_texto)

	_cursor = Label.new()
	_cursor.text = "█"
	_cursor.add_theme_font_override("font", letra)
	_cursor.add_theme_font_size_override("font_size", CORPO)
	_cursor.add_theme_color_override("font_color", TINTA)
	_cursor.visible = false
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	coluna.add_child(_cursor)

	_menu = HBoxContainer.new()
	_menu.add_theme_constant_override("separation", 60)
	_menu.visible = false
	coluna.add_child(_menu)
	_opcoes.append(_opcao(ENTRAR, letra))
	_opcoes.append(_opcao(DESISTIR, letra))

	var credito := Label.new()
	credito.text = CREDITO
	credito.add_theme_font_override("font", letra)
	credito.add_theme_font_size_override("font_size", CORPO_DO_CREDITO)
	credito.add_theme_color_override("font_color", TINTA_FRACA)
	credito.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	credito.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credito.offset_top = -64
	credito.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(credito)

	_por_o_vidro()
	_bater()

	var t := Timer.new()
	t.wait_time = PISCA
	t.timeout.connect(_piscar)
	add_child(t)
	t.start()


## Uma opcao de menu, a maneira do DOS: entre parenteses rectos, sem
## caixa, sem sombra, sem canto redondo. O marcador vive no proprio texto
## — dois espacos quando nao esta escolhida, para nada saltar de sitio.
func _opcao(rotulo: String, letra: FontFile) -> Button:
	var b := Button.new()
	b.text = "  [ %s ]" % rotulo
	# O rotulo fica guardado no proprio botao: o marcador reescreve o
	# texto a cada piscar e tem de saber o que la estava sem o ir buscar
	# a uma lista pela ordem.
	b.set_meta("rotulo", rotulo)
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", letra)
	b.add_theme_font_size_override("font_size", CORPO)
	for cor in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(cor, TINTA)
	for caixa in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(caixa, StyleBoxEmpty.new())
	b.mouse_entered.connect(func() -> void: _escolher(_opcoes.find(b)))
	b.pressed.connect(func() -> void: _decidir(_opcoes.find(b)))
	_menu.add_child(b)
	return b


## O vidro do monitor por cima de tudo. A copia do ecra tem de vir antes
## do rectangulo: e ela que enche o que o shader vai ler.
func _por_o_vidro() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 8
	add_child(camada)

	var copia := BackBufferCopy.new()
	copia.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	camada.add_child(copia)

	var vidro := ColorRect.new()
	vidro.set_anchors_preset(Control.PRESET_FULL_RECT)
	vidro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/crt.gdshader")
	vidro.material = m
	camada.add_child(vidro)


## O atabaque comeca com a tela, nao com o texto: e a primeira coisa que
## acontece, antes de as linhas de arranque piscarem.
func _bater() -> void:
	if atabaque == null:
		return
	var tocador := AudioStreamPlayer.new()
	tocador.stream = atabaque
	tocador.volume_db = volume_do_atabaque
	add_child(tocador)
	tocador.play()


func _correr() -> void:
	await _arrancar()
	await _escrever()
	_cursor.visible = true
	_menu.visible = true
	_a_espera = true
	_escolher(0)


## As linhas de diagnostico, uma de cada vez, e depois o ecra limpa-se.
##
## Cada linha entra com um lampejo: acende a cheio e assenta logo no
## fraco em que fica. E o que um tubo destes fazia quando lhe chegava
## texto de repente, e e o que separa isto de uma lista a aparecer.
func _arrancar() -> void:
	var ate_agora := ""
	for linha in ARRANQUE:
		ate_agora += ("\n" if ate_agora != "" else "") + linha
		_arranque.text = ate_agora
		_arranque.modulate.a = 1.0
		var lampejo := create_tween()
		lampejo.tween_property(_arranque, "modulate:a", 0.68, 0.13)
		await get_tree().create_timer(PASSO_DO_ARRANQUE).timeout
	await get_tree().create_timer(PAUSA_DEPOIS_DO_ARRANQUE).timeout
	_arranque.text = ""


## A maquina de escrever, com o silencio antes da ultima linha.
##
## Nao e uma velocidade irregular: sao dois trechos a mesma velocidade,
## com uma paragem a serio no meio. O corte esta no `\n` da penultima
## linha, e a fraccao sai contada pelo proprio `RichTextLabel` — o que
## conta caracteres e ele, e o que ele conta nao e o comprimento da
## `String`.
func _escrever() -> void:
	var total := _texto.get_total_character_count()
	if total <= 0:
		_texto.visible_ratio = 1.0
		return
	var antes := RITUAL.substr(0, RITUAL.rfind("\n"))
	# Conta-se o prefixo com a MESMA regua: poe-se-o no rotulo, pergunta-se
	# quantos caracteres tem, e volta-se a por o texto todo.
	_texto.text = antes
	var ate_ao_fim: float = float(_texto.get_total_character_count()) / float(total)
	_texto.text = RITUAL

	var t := create_tween()
	t.tween_property(_texto, "visible_ratio", ate_ao_fim,
		ate_ao_fim * float(total) / VELOCIDADE)
	t.tween_interval(PAUSA_ANTES_DO_FIM)
	t.tween_property(_texto, "visible_ratio", 1.0,
		(1.0 - ate_ao_fim) * float(total) / VELOCIDADE)
	await t.finished


func _piscar() -> void:
	_aceso = not _aceso
	if _cursor.visible:
		_cursor.modulate.a = 1.0 if _aceso else 0.0
	_marcar()


## O marcador ao lado da opcao escolhida, a piscar. Fora dela, dois
## espacos: as duas opcoes ficam sempre na mesma coluna.
func _marcar() -> void:
	for i in _opcoes.size():
		var marca := "> " if (i == _escolhida and _aceso) else "  "
		_opcoes[i].text = "%s[ %s ]" % [marca, _opcoes[i].get_meta("rotulo")]


func _escolher(i: int) -> void:
	if i < 0 or i >= _opcoes.size():
		return
	_escolhida = i
	_opcoes[i].grab_focus()
	_aceso = true
	_marcar()


func _unhandled_input(evento: InputEvent) -> void:
	if not _a_espera or _decidido:
		return
	if evento.is_action_pressed("ui_left") or evento.is_action_pressed("ui_up"):
		_escolher(0 if _escolhida == 1 else 1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("ui_right") or evento.is_action_pressed("ui_down"):
		_escolher(0 if _escolhida == 1 else 1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("ui_accept"):
		_decidir(_escolhida)
		get_viewport().set_input_as_handled()


## As duas respostas sao a serio, como na `fornalha`: uma entra, a outra
## fecha o app. O app nao se apaga a si proprio — apagar e da pessoa, e
## e por isso que a frase diz "apago" e nao "apague-me".
func _decidir(i: int) -> void:
	if _decidido or not _a_espera:
		return
	_decidido = true
	if i == 0:
		Passagem.atravessar()
		get_tree().change_scene_to_file("res://scenes/risco.tscn")
	else:
		get_tree().quit()
