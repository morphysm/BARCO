## Captura a tela de RISCO com cada `assinatura` da `irmandade` ja
## riscada, sem aparelho e sem dedo. Serve para iterar a geometria dos
## `pontos` e o grao da `pemba` olhando o resultado, nao imaginando.
##
## Rodar (precisa de display, nao roda em --headless):
##   godot --path client --script res://tools/capturar_risco.gd --resolution 640x1000
##
## Sai em capturas/, fora do controle de versao.
extends SceneTree

var no: Node2D
var quadro := 0
var indice := 0

func _initialize() -> void:
	no = load("res://scenes/risco.tscn").instantiate()
	root.add_child(no)

func _process(_d: float) -> bool:
	quadro += 1
	if quadro < 15:
		return false
	if (quadro - 15) % 25 != 0:
		return false
	var irm: Irmandade = no.irmandade
	if indice > 0:
		_salvar(irm.entidades[indice - 1].slug)
		no.call("_limpar")
	if indice >= irm.entidades.size():
		return true
	no.set("_guiado", indice)
	no.call("_atualizar_rotulo_guia")
	no.get("_guia").queue_redraw()
	no.get("_marcas").queue_redraw()
	_riscar(irm.entidades[indice])
	indice += 1
	return false

func _riscar(e: Entidade) -> void:
	for c in e.ponto_riscado.segmentos:
		var pts := Polilinha.da_curva(c, 160)
		no.call("_comecar_traco", pts[0])
		for i in range(1, pts.size()):
			no.call("_continuar_traco", pts[i])
		no.call("_terminar_traco")

func _salvar(nome: String) -> void:
	DirAccess.make_dir_recursive_absolute("res://../capturas")
	root.get_texture().get_image().save_png("res://../capturas/assinatura_%s.png" % nome)
	print("salvo: ", nome)
