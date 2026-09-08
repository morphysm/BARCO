## Prova a TELA da Porta (SPEC.md §1.1) — nao a porta de cobertura, que e
## a `prova_porta.gd`.
##
## Mede duas coisas que nao se veem numa fotografia parada:
##   1. a pausa antes da ultima linha — segue `visible_ratio` quadro a
##      quadro e diz quanto tempo esteve parada, e onde;
##   2. o menu — carrega nas setas e ve se a escolha anda e se o marcador
##      muda de lado;
##   3. a franja de cor — fotografa DUAS vezes, com o desvio ligado e
##      desligado, e compara. A diferenca entre as duas e a franja e mais
##      nada: comparar canais na mesma fotografia nao servia, porque a
##      tinta do app ja e osso e nao branco (R != B por si so).
##
##   godot --path client --script res://tools/prova_porta_tela.gd --resolution 1600x1000
extends SceneTree

var _tela: Node
var _texto: RichTextLabel
var _relogio := 0.0
var _amostras: Array = []
var _espera_do_par := 0
var _passo := 0
var _arranque_fotografado := false


func _initialize() -> void:
	# O registo aponta para OUTRO ficheiro antes de se lhe tocar. Isto
	# escreve `atravessou_a_porta`, e escrever no registo a serio apaga o
	# progresso de quem esta a usar o app — o proprio `passagem.gd` avisa,
	# e foi por isso que o `REGISTO` nao e `const`.
	Passagem.REGISTO = "user://prova_porta_tela.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Passagem.REGISTO))
	_tela = load("res://scenes/porta.tscn").instantiate()
	root.add_child(_tela)


func _process(d: float) -> bool:
	_relogio += d

	# Passo 4 e depois da tela ja ter sido deitada fora: dai para a frente
	# nao se lhe toca em nada, que apontar para um no libertado enche o
	# ecra de erros e a prova nunca mais acaba.
	if _passo == 4:
		_espera_do_par -= 1
		if _espera_do_par > 0:
			return false
		# Aqui o `self` E a arvore: a cena actual e propriedade dela.
		var actual: Node = current_scene
		print("")
		print("ATRAVESSA-SE UMA VEZ")
		print("  com atravessou=true, a Porta encaminha para: %s" % (
			actual.name if actual != null else "nenhuma cena"))
		return true

	if _texto == null:
		_texto = _tela.get("_texto")
		if _texto == null:
			return _relogio > 30.0
	_amostras.append([_relogio, _texto.visible_ratio])

	# O arranque fotografa-se: e a unica maneira de ver que as linhas de
	# diagnostico chegam ao ecra antes do texto.
	if not _arranque_fotografado and _relogio >= 0.75:
		_arranque_fotografado = true
		root.get_texture().get_image().save_png("res://../capturas/porta_arranque.png")

	# O par de fotografias tem de ser tirado com o tremor da corrente
	# travado, senao as duas diferem no brilho todo e a conta da franja
	# vem suja em todo o lado.
	match _passo:
		0:
			if _texto.visible_ratio >= 1.0:
				_no_vidro("tremor", 0.0)
				_passo = 1
				_espera_do_par = 3
		1:
			_espera_do_par -= 1
			if _espera_do_par <= 0:
				root.get_texture().get_image().save_png("res://../capturas/porta.png")
				_no_vidro("aberracao", 0.0)
				_passo = 2
				_espera_do_par = 3
		2:
			_espera_do_par -= 1
			if _espera_do_par <= 0:
				root.get_texture().get_image().save_png("res://../capturas/porta_sem_franja.png")
				_passo = 3

	if _passo == 3 and _relogio >= 14.0:
		_relatorio()
		# E atravessa-se UMA vez: com a Porta ja atravessada, a tela nao
		# se monta — encaminha para o `risco` e sai da frente.
		Passagem.atravessar()
		_texto = null
		_tela.queue_free()
		_tela = null
		root.add_child(load("res://scenes/porta.tscn").instantiate())
		_passo = 4
		_espera_do_par = 30
	return false


func _no_vidro(parametro: String, valor: float) -> void:
	for n in _tela.get_children():
		if n is CanvasLayer:
			for f in n.get_children():
				if f is ColorRect and f.material is ShaderMaterial:
					(f.material as ShaderMaterial).set_shader_parameter(parametro, valor)


func _relatorio() -> void:
	# A maior paragem: o intervalo mais longo em que a fraccao nao mexeu,
	# depois de ter comecado a andar e antes de chegar ao fim.
	var comeco := 0.0
	var maior := 0.0
	var maior_em := 0.0
	var parado_desde := 0.0
	var anterior := -1.0
	for a in _amostras:
		var t: float = a[0]
		var r: float = a[1]
		if r <= 0.0:
			comeco = t
			continue
		if anterior >= 0.0 and absf(r - anterior) < 0.0001 and r < 1.0:
			if t - parado_desde > maior:
				maior = t - parado_desde
				maior_em = anterior
		else:
			parado_desde = t
		anterior = r

	print("")
	print("A PAUSA")
	print("  o texto comeca a %.2f s" % comeco)
	print("  maior paragem: %.2f s, com %.1f%% do texto no ecra" % [maior, maior_em * 100.0])
	print("  a ultima linha comeca aos %.1f%%" % (_fraccao_do_corte() * 100.0))
	print("  esperado: parar em cima do corte, %.2f s" % _tela.PAUSA_ANTES_DO_FIM)

	print("")
	print("O MENU")
	_provar_o_menu()

	print("")
	print("A FRANJA DE COR (quanto o desvio dos canhoes mexeu em cada faixa)")
	var com := Image.load_from_file("res://../capturas/porta.png")
	var sem := Image.load_from_file("res://../capturas/porta_sem_franja.png")
	if com == null or sem == null:
		print("  faltou uma das fotografias")
		return
	print("  faixa      raio        maior desvio de cor")
	for faixa in [["centro", 0.0, 0.45], ["meio", 0.45, 0.74],
			["borda", 0.74, 0.90], ["extremo", 0.90, 1.0]]:
		print("  %-9s %.2f-%.2f   %.4f" % [faixa[0], faixa[1], faixa[2],
			_desvio(com, sem, faixa[1], faixa[2])])
	# O que interessa mesmo: o texto do ritual esta todo dentro de que
	# raio, e quanto e que a franja lhe mexeu.
	var ate := _raio_do_texto()
	print("")
	print("  o texto do ritual vai ate ao raio %.2f" % ate)
	print("  franja dentro dele: %.4f" % _desvio(com, sem, 0.0, ate))
	print("  o vidro so comeca a desviar a %.2f" % _bordo())


func _bordo() -> float:
	for n in _tela.get_children():
		if n is CanvasLayer:
			for f in n.get_children():
				if f is ColorRect and f.material is ShaderMaterial:
					# Quem nunca foi escrito de fora vale o que o shader
					# declara — e `get_shader_parameter` devolve nulo nesse
					# caso, nao o valor por omissao.
					var m := f.material as ShaderMaterial
					var v = m.get_shader_parameter("bordo_da_aberracao")
					if v == null:
						v = RenderingServer.shader_get_parameter_default(
							m.shader.get_rid(), "bordo_da_aberracao")
					return float(v)
	return 0.0


## O raio, em coordenadas do shader, do canto mais afastado do bloco de
## texto do ritual.
func _raio_do_texto() -> float:
	var ecra := Vector2(root.get_visible_rect().size)
	var caixa := Rect2(_texto.global_position, _texto.size)
	var maior := 0.0
	for canto in [caixa.position, caixa.position + Vector2(caixa.size.x, 0.0),
			caixa.position + Vector2(0.0, caixa.size.y), caixa.end]:
		maior = maxf(maior, ((canto / ecra) * 2.0 - Vector2.ONE).length())
	return maior


func _fraccao_do_corte() -> float:
	var total := _texto.get_total_character_count()
	var guardado: String = _texto.text
	_texto.text = guardado.substr(0, guardado.rfind("\n"))
	var f: float = float(_texto.get_total_character_count()) / float(total)
	_texto.text = guardado
	return f


## Quanto o vermelho e o azul se afastaram por causa do desvio, dentro de
## um anel de raios. Compara-se a mesma imagem com e sem: o que sobra e o
## efeito, sem a cor da tinta pelo meio.
##
## O raio e o do shader — `length` da coordenada centrada — para as
## faixas caírem onde o `bordo_da_aberracao` as poe.
func _desvio(com: Image, sem: Image, de: float, ate: float) -> float:
	var meio := Vector2(com.get_width(), com.get_height()) * 0.5
	var maximo := 0.0
	for y in range(0, com.get_height(), 2):
		for x in range(0, com.get_width(), 2):
			var r := ((Vector2(x, y) - meio) / meio).length()
			if r < de or r >= ate:
				continue
			var a := com.get_pixel(x, y)
			var b := sem.get_pixel(x, y)
			maximo = maxf(maximo, maxf(absf(a.r - b.r), absf(a.b - b.b)))
	return maximo


## As setas andam entre as duas opcoes, e o marcador acompanha. Chama-se o
## tratador com um evento a serio, para nao provar so a variavel.
func _provar_o_menu() -> void:
	print("  escolhida a abrir: %d (%s)" % [_tela._escolhida, _rotulo_marcado()])
	for accao in ["ui_right", "ui_left", "ui_down"]:
		var e := InputEventAction.new()
		e.action = accao
		e.pressed = true
		_tela._unhandled_input(e)
		print("  %-9s -> escolhida %d (%s)" % [accao, _tela._escolhida, _rotulo_marcado()])
	print("  a Porta ainda esta fechada: atravessou=%s" % Passagem.atravessou())


## Qual das duas opcoes tem o marcador neste momento, lido do proprio
## texto do botao.
func _rotulo_marcado() -> String:
	for b in _tela._opcoes:
		if b.text.begins_with(">"):
			return b.text.strip_edges()
	return "nenhuma (o marcador esta apagado neste piscar)"
