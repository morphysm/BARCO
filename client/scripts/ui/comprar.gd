## O balcao. Onde se compra, que nao e onde se depoe.
##
## A tira do `assentamento` nao e um carrinho e continua a nao ser (GDD §2,
## pilar 3): la carrega-se numa oferenda e arrasta-se, um gesto, uma
## decisao. Aqui e outra coisa — escolhe-se um cesto, paga-se de uma vez,
## e volta-se com creditos nomeados. Sao duas salas, e de proposito.
##
## O cesto escolhe-se ANTES de pagar e paga-se exactamente o que se
## escolheu. Nao ha troco, e por isso nao ha saldo: um saldo residual era
## moeda intermedia, e o `AGENTS.md` proibe-a pelo nome.
##
## O que aqui se ve em dolares e o que o Ko-fi vai cobrar. Quem soma e o
## servidor quando emite o codigo; isto mostra a mesma conta para a pessoa
## a poder conferir antes de pagar.
class_name Comprar
extends CanvasLayer

## TODO(CONTENT.pt.md): rotulos definitivos sao texto autoral. Estes sao
## estruturais — dizem o que o botao faz e mais nada (SPEC.md §10, §2:
## descrever o acto, nunca o efeito).
const LARGURA := 760

signal fechou

var _oferendas: Array[Oferenda] = []
var _cesto: Dictionary = {}
var _servidor: Servidor
var _codigo := ""

var _coluna: VBoxContainer
var _rolo: ScrollContainer
var _linhas: VBoxContainer
var _total: Label
var _pedir: Button
var _estado: Label
var _a_pedir := false
var _a_verificar := false
var _consulta: Timer
var _caixa_do_codigo: VBoxContainer
var _rotulo_do_codigo: Label
var _abrir_kofi: Button
var _tenho: Label
var _conta_compras: ContaCompras
var _copia_estado: Label
var _copia_web: JavaScriptObject
var _copia_callback: JavaScriptObject


func _init(oferendas: Array[Oferenda]) -> void:
	_oferendas = oferendas


func _ready() -> void:
	_servidor = load("res://resources/servidor/supabase.tres")
	if OS.has_feature("web"):
		JavaScriptBridge.eval(CodigoClipboard.SCRIPT_WEB)
		_copia_web = JavaScriptBridge.get_interface("BarcoClipboard")
		_copia_callback = JavaScriptBridge.create_callback(_resultado_copia_web)
	_montar()
	Creditos.mudaram.connect(_mostrar_o_que_ha)
	_actualizar()
	_consulta = Timer.new()
	_consulta.wait_time = 5.0
	_consulta.timeout.connect(_verificar)
	add_child(_consulta)
	_consulta.start()
	await Conta.entrar()
	if is_inside_tree():
		_conta_compras._actualizar()
		_actualizar()
		await _restaurar_encomenda()


func _montar() -> void:
	var fundo := ColorRect.new()
	fundo.color = Color.BLACK
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)

	# A mesma faixa estreita ao centro do menu dos `pedidos`, presa em
	# cima e em baixo para o rolo crescer com o ecra.
	var meio := VBoxContainer.new()
	meio.set_anchors_preset(Control.PRESET_FULL_RECT)
	meio.anchor_left = 0.5
	meio.anchor_right = 0.5
	meio.offset_left = -LARGURA * 0.5
	meio.offset_right = LARGURA * 0.5
	meio.offset_top = 44
	meio.offset_bottom = -44
	# Ao centro: com poucas oferendas o bloco fica no meio do ecra em vez
	# de encostado ao topo com um vazio por baixo.
	meio.alignment = BoxContainer.ALIGNMENT_CENTER
	meio.add_theme_constant_override("separation", 14)
	add_child(meio)
	_coluna = meio

	var titulo := Pagina.texto("escolhe o que queres levar", 30)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meio.add_child(titulo)

	_tenho = Pagina.texto("", 18)
	_tenho.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tenho.modulate = Color(1, 1, 1, 0.6)
	meio.add_child(_tenho)

	# O contentor distribui a altura restante, sem realimentar a medida
	# minima do proprio rolo a cada actualizacao do pagamento.
	_rolo = ScrollContainer.new()
	_rolo.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rolo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rolo.custom_minimum_size.y = 120
	_rolo.mouse_force_pass_scroll_events = false
	meio.add_child(_rolo)
	var rolo := _rolo

	_linhas = VBoxContainer.new()
	_linhas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Cada linha tem espaco proprio para os controlos de quantidade.
	_linhas.add_theme_constant_override("separation", 14)
	rolo.add_child(_linhas)

	for o in _oferendas:
		_linhas.add_child(_uma_linha(o))

	_total = Pagina.texto("", 26)
	_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meio.add_child(_total)

	_conta_compras = ContaCompras.new()
	_conta_compras.autenticou.connect(_recuperou)
	meio.add_child(_conta_compras)

	var botoes := HBoxContainer.new()
	botoes.alignment = BoxContainer.ALIGNMENT_CENTER
	botoes.add_theme_constant_override("separation", 14)
	meio.add_child(botoes)

	_pedir = Pagina.botao("pedir o código", 22)
	_pedir.pressed.connect(_pedir_codigo)
	botoes.add_child(_pedir)

	var voltar := Pagina.botao("voltar", 22)
	voltar.pressed.connect(func() -> void: fechou.emit())
	botoes.add_child(voltar)

	# A caixa do codigo so aparece depois de ele existir.
	_caixa_do_codigo = VBoxContainer.new()
	_caixa_do_codigo.alignment = BoxContainer.ALIGNMENT_CENTER
	_caixa_do_codigo.add_theme_constant_override("separation", 10)
	_caixa_do_codigo.visible = false
	meio.add_child(_caixa_do_codigo)

	_rotulo_do_codigo = Pagina.texto("", 44)
	_rotulo_do_codigo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caixa_do_codigo.add_child(_rotulo_do_codigo)

	var como := Pagina.texto(
		"cola este código na mensagem, ao pagar", 18)
	como.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	como.modulate = Color(1, 1, 1, 0.7)
	_caixa_do_codigo.add_child(como)

	var linha_kofi := HBoxContainer.new()
	linha_kofi.alignment = BoxContainer.ALIGNMENT_CENTER
	_abrir_kofi = Pagina.botao("copiar código e abrir o Ko-fi", 20)
	_abrir_kofi.pressed.connect(_ir_ao_kofi)
	_caixa_do_codigo.add_child(_abrir_kofi)
	_caixa_do_codigo.add_child(linha_kofi)
	var verificar := Pagina.botao("verificar pagamento", 20)
	verificar.pressed.connect(_verificar)
	linha_kofi.add_child(verificar)
	_copia_estado = Pagina.texto("", 18)
	_copia_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caixa_do_codigo.add_child(_copia_estado)
	_estado = Pagina.texto("", 18)
	_estado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caixa_do_codigo.add_child(_estado)

	call_deferred("_ajustar_rolo")
	get_viewport().size_changed.connect(_ajustar_rolo)


## A largura acompanha o ecra; o VBox distribui a altura restante.
func _ajustar_rolo() -> void:
	if _rolo == null or _linhas == null or not is_instance_valid(_rolo):
		return
	var tamanho := get_viewport().get_visible_rect().size
	_coluna.offset_left = -minf(LARGURA, tamanho.x - 32) * 0.5
	_coluna.offset_right = minf(LARGURA, tamanho.x - 32) * 0.5


## Uma oferenda: o nome, o preco, e quantas se levam.
func _uma_linha(o: Oferenda) -> Control:
	var linha := HBoxContainer.new()
	linha.custom_minimum_size.y = 56
	linha.add_theme_constant_override("separation", 18)

	var menos := Pagina.botao("−", 20)
	menos.name = "menos_" + o.slug
	menos.pressed.connect(_mudar.bind(o.slug, -1))
	linha.add_child(menos)

	var quantos := Pagina.texto("0", 20)
	quantos.custom_minimum_size = Vector2(34, 0)
	quantos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantos.name = "quantos_" + o.slug
	linha.add_child(quantos)

	var mais := Pagina.botao("+", 20)
	mais.pressed.connect(_mudar.bind(o.slug, 1))
	linha.add_child(mais)

	var nome := Pagina.texto(o.nome, 20)
	nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(nome)

	var preco := Pagina.texto("%d %s" % [
		o.cafes * AssentamentoScreen.POR_CAFE, AssentamentoScreen.MOEDA], 20)
	linha.add_child(preco)
	return linha


func _mudar(slug: String, quanto: int) -> void:
	if _a_pedir:
		return
	var novo: int = clampi(int(_cesto.get(slug, 0)) + quanto, 0, 99)
	if novo == 0:
		_cesto.erase(slug)
	else:
		_cesto[slug] = novo
	# Mudar o cesto invalida o codigo que ja foi pedido: ele nomeia o
	# cesto anterior, e o cesto anterior foi selado no servidor.
	_codigo = ""
	_cancelar_copia()
	_caixa_do_codigo.visible = false
	_actualizar()


func _actualizar() -> void:
	var cafes := 0
	for o in _oferendas:
		var n: int = int(_cesto.get(o.slug, 0))
		cafes += o.cafes * n
		var r := _linhas.find_child("quantos_" + o.slug, true, false)
		if r is Label:
			r.text = str(n)
			r.modulate = Color(1, 1, 1, 1.0 if n > 0 else 0.35)
		# Tirar de uma linha vazia nao faz nada, e um botao que nao faz
		# nada nao deve parecer que faz.
		var m := _linhas.find_child("menos_" + o.slug, true, false)
		if m is Button:
			m.disabled = n == 0
			m.modulate = Color(1, 1, 1, 1.0 if n > 0 else 0.3)
	_total.text = "" if cafes == 0 else "total  %d %s" % [
		cafes * AssentamentoScreen.POR_CAFE, AssentamentoScreen.MOEDA]
	_pedir.disabled = cafes == 0 or _a_pedir or (OS.has_feature("web") and not Conta.recuperavel())
	_pedir.modulate = Color(1, 1, 1, 1.0 if not _pedir.disabled else 0.35)
	_mostrar_o_que_ha()
	call_deferred("_ajustar_rolo")


## O que ja esta comprado e por gastar. Existe para nao se comprar duas
## vezes a mesma coisa sem dar por isso.
func _mostrar_o_que_ha() -> void:
	if _tenho == null:
		return
	var tem: Dictionary = Creditos.tudo()
	if tem.is_empty():
		_tenho.text = ""
		return
	var partes: Array[String] = []
	for o in _oferendas:
		var n: int = int(tem.get(o.slug, 0))
		if n > 0:
			partes.append("%s ×%d" % [o.nome, n])
	_tenho.text = "" if partes.is_empty() else "por gastar:  " + ", ".join(partes)


func _pedir_codigo() -> void:
	if _a_pedir:
		return
	if OS.has_feature("web") and not Conta.recuperavel():
		return
	_codigo = ""
	_cancelar_copia()
	_pedir.disabled = true
	_rotulo_do_codigo.text = "…"
	_caixa_do_codigo.visible = true

	_a_pedir = true
	_abrir_kofi.disabled = true
	var cod: String = await Creditos.pedir_codigo(_cesto)
	_a_pedir = false
	if cod == "":
		# Sem servidor nao ha codigo, e dizer isso e melhor do que ficar
		# a olhar para tres pontos.
		_rotulo_do_codigo.text = "não deu"
		_pedir.disabled = false
		return
	_codigo = cod
	_rotulo_do_codigo.text = cod
	_pedir.disabled = false
	await _verificar()


func _ir_ao_kofi() -> void:
	if _servidor == null or _servidor.kofi_url == "":
		_rotulo_do_codigo.text = _codigo if _codigo != "" else ""
		_abrir_kofi.text = "falta o endereço do Ko-fi"
		return
	if _codigo == "" or _abrir_kofi.disabled:
		return
	_copiar_codigo(_servidor.kofi_url)


func _copiar_codigo(destino := "") -> void:
	if _codigo == "":
		return
	if OS.has_feature("web"):
		_copia_estado.text = "a copiar…"
		_copia_web.copiar(_codigo, destino, _copia_callback)
		return
	DisplayServer.clipboard_set(_codigo)
	if DisplayServer.clipboard_get() != _codigo:
		_copia_estado.text = "não foi possível copiar o código"
		return
	_copia_estado.text = "código copiado — cola-o na mensagem do Ko-fi"
	if destino != "" and OS.shell_open(destino) != OK:
		_copia_estado.text = "código copiado; não foi possível abrir o Ko-fi"


func _resultado_copia_web(argumentos: Array) -> void:
	if argumentos.size() < 2 or str(argumentos[0]) != _codigo:
		return
	match str(argumentos[1]):
		"copiado":
			_copia_estado.text = "código copiado — cola-o na mensagem do Ko-fi"
		"manual":
			_copia_estado.text = "selecciona e copia o código na janela aberta"
		"abertura_bloqueada":
			_copia_estado.text = "código copiado — usa o link na janela aberta"


func _cancelar_copia() -> void:
	if _copia_web != null:
		_copia_web.cancelar()
	if _copia_estado != null:
		_copia_estado.text = ""


func _exit_tree() -> void:
	_cancelar_copia()


# TODO(CONTENT.pt.md): rotulos estruturais de pagamento.
func _verificar() -> void:
	if _a_pedir or _a_verificar:
		return
	_a_verificar = true
	if _codigo == "":
		await Conta.entrar()
		_a_verificar = false
		_actualizar()
		_conta_compras._actualizar()
		return
	var codigo_consultado := _codigo
	var estado: Dictionary = await Creditos.estado_codigo(codigo_consultado)
	_a_verificar = false
	if codigo_consultado != _codigo:
		return
	if estado.is_empty():
		_abrir_kofi.disabled = true
		_estado.text = "sem ligação — verifica novamente"
		return
	_total.text = "total  %s USD" % str(estado.get("total_usd", ""))
	if estado.get("estado", "") == "revisao":
		_abrir_kofi.disabled = true
		_estado.text = "pagamento por verificar — contacta o suporte no Ko-fi"
		return
	var creditado: bool = estado.get("estado", "") == "creditado"
	_abrir_kofi.disabled = creditado
	_estado.text = "pagamento recebido" if creditado else "à espera do pagamento"
	if creditado:
		_cancelar_copia()
		await Creditos.actualizar()


func _recuperou() -> void:
	_codigo = ""
	_cancelar_copia()
	_caixa_do_codigo.visible = false
	_actualizar()
	await Creditos.actualizar()
	await _restaurar_encomenda()


func _restaurar_encomenda() -> void:
	var encomenda: Dictionary = await Creditos.ultima_encomenda()
	if encomenda.is_empty() or _codigo != "" or _a_pedir or not _cesto.is_empty():
		return
	_cesto.clear()
	for item in encomenda.get("codigo_itens", []):
		_cesto[str(item["ato_slug"])] = int(item["quantidade"])
	_actualizar()
	_codigo = str(encomenda["codigo"])
	_rotulo_do_codigo.text = _codigo
	_caixa_do_codigo.visible = true
	await _verificar()
