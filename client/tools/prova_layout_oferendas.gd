## Cena de bancada: sem conta, rede ou deposito; usa dados isolados no comando.
extends Node

var falhas := 0

func _ready() -> void:
	var servidor := Servidor.new()
	servidor.vende = false
	Conta.set("_servidor", servidor)
	for campo in ["_id", "_token", "_renovar"]:
		Conta.set(campo, "")
	var venda := Servidor.new()
	venda.vende = true
	venda.vende_na_web = true
	Creditos.set("_servidor", venda)
	get_window().content_scale_size = Vector2i.ZERO
	var ecra: AssentamentoScreen = load("res://scenes/assentamento.tscn").instantiate()
	add_child(ecra)
	for tamanho in [Vector2i(1440, 900), Vector2i(1000, 560), Vector2i(720, 1000)]:
		get_window().size = tamanho
		for i in 8:
			await get_tree().process_frame
		ecra._ajustar_faixa()
		for i in 4:
			await get_tree().process_frame
		var vista := get_viewport().get_visible_rect()
		var conta := 0
		for rolo in ecra._laterais:
			checar("coluna dentro da viewport %s" % tamanho,
				vista.encloses(rolo.get_global_rect()))
			checar("coluna acima das accoes", rolo.get_global_rect().end.y <= ecra._faixa.position.y)
			var barra := rolo.get_v_scroll_bar()
			if tamanho.y >= 900:
				checar("cinco oferendas cabem sem scroll", barra.max_value <= barra.page)
			rolo.scroll_vertical = int(barra.max_value)
			await get_tree().process_frame
			var botoes := rolo.get_child(0).get_children()
			conta += botoes.size()
			var ultimo: Button = botoes.back()
			checar("ultima oferenda acessivel %s" % tamanho,
				ultimo.get_global_rect().end.y <= rolo.get_global_rect().end.y + 1.0)
			rolo.scroll_vertical = 0
		checar("todas as oferendas presentes", conta == ecra._oferendas_disponiveis().size())
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(
				"/tmp/barco-oferendas-%dx%d.png" % [tamanho.x, tamanho.y])
	get_window().size = Vector2i(1000, 560)
	for i in 8:
		await get_tree().process_frame
	ecra._ajustar_faixa()
	await get_tree().process_frame
	var rolo := ecra._laterais[0]
	var botao: Button = rolo.get_child(0).get_child(0)
	var oferenda: Oferenda = load(ecra._oferendas_disponiveis()[0])
	ecra._preparar_arrasto(oferenda, botao)
	ecra._inicio_arrasto = botao.get_global_rect().get_center()
	var deslizar := InputEventScreenDrag.new()
	deslizar.position = ecra._inicio_arrasto + Vector2(0, 24)
	ecra._input(deslizar)
	ecra._clicar_oferenda(oferenda)
	checar("deslizar lista nao abre balcao", ecra._balcao == null)
	checar("deslizar lista nao pega oferenda", ecra._na_mao == null)
	# A roda nao e largar o botao esquerdo: nao pode completar um gesto.
	ecra._na_mao = Node3D.new()
	var roda := InputEventMouseButton.new()
	roda.button_index = MOUSE_BUTTON_WHEEL_DOWN
	roda.pressed = false
	ecra._input(roda)
	checar("roda nao larga oferenda", ecra._na_mao != null)
	ecra._na_mao.free()
	ecra._na_mao = null
	get_window().size = Vector2i(1440, 900)
	ecra.abrir_balcao()
	for i in 8:
		await get_tree().process_frame
	var balcao := ecra._balcao
	Conta.set("_id", "layout-teste")
	Conta.set("_token", "layout-teste")
	Conta.set("_expira", Time.get_unix_time_from_system() + 3600.0)
	Conta.set("_confirmada", true)
	Conta.set("_email", "teste@example.invalid")
	Creditos.set("_servidor", null)
	balcao._consulta.stop()
	balcao._conta_compras._actualizar()
	checar("sem botao copiar separado", not tem_botao(balcao, "copiar código"))
	checar("accao copiar e abrir presente", tem_botao(balcao, "copiar código e abrir o Ko-fi"))
	balcao._caixa_do_codigo.visible = true
	balcao._rotulo_do_codigo.text = "BAR-TEST"
	for i in 8:
		await get_tree().process_frame
	balcao._rolo.scroll_vertical = 100
	await get_tree().process_frame
	var antes := balcao._rolo.scroll_vertical
	for i in 5:
		balcao._actualizar()
		await get_tree().process_frame
	checar("actualizar nao desloca lista", balcao._rolo.scroll_vertical == antes)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/barco-checkout-layout.png")
	print("Layout: %d falhas" % falhas)
	get_tree().quit(1 if falhas else 0)

func checar(texto: String, ok: bool) -> void:
	print("%s: %s" % ["ok" if ok else "FALHA", texto])
	if not ok:
		falhas += 1

func tem_botao(no: Node, texto: String) -> bool:
	if no is Button and no.text == texto:
		return true
	for filho in no.get_children():
		if tem_botao(filho, texto):
			return true
	return false
