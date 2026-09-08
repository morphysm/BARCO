## Uma poca de sangue no chao do `assentamento`.
##
## O `sangue` e a oferenda mais cara da lista — 7 cafes contra 1 de todas
## as outras — e nao se depoe como as outras: nao e um objeto pousado, e
## um balde atirado ao chao. Por isso nao tem modelo; tem um plano rente
## ao chao com `shaders/sangue.gdshader` por cima.
##
## Cada poca e sua. A `semente` muda a borda, os pingos e a pele, e a
## `direccao` muda o lado para onde o balde foi — duas pocas lado a lado
## nao sao a mesma imagem repetida.
class_name PocaDeSangue
extends MeshInstance3D

const SHADER := "res://shaders/sangue.gdshader"

## Quanto tempo o balde leva a assentar.
##
## E a duracao do SOM, nao um numero escolhido: o `banho_de_sangue.ogg`
## tem 1.515 s de ficheiro mas so 1.03 s de som — o resto e silencio no
## fim. A poca cresce enquanto se ouve despejar e para quando o despejo
## para. `tools/afinar_sangue.py` mede isto e diz se ainda bate certo
## depois de o som ser reeditado.
const DEMORA := 1.03

## O som do balde a cair. Vem de fora — quem o poe e o `assentamento`,
## para o ficheiro poder ser trocado num sitio so.
var som: AudioStream

var _material: ShaderMaterial


## `largura` e o lado do quadrado onde a poca cabe, em metros. A poca
## propria nao o enche todo: a borda dela anda pelos 0.45 do raio, e os
## pingos e que chegam a beira.
func _init(largura := 0.5, semente := -1.0) -> void:
	var plano := PlaneMesh.new()
	plano.size = Vector2(largura, largura)
	# Um plano de dois triangulos chega: a superficie e plana e o relevo
	# todo vem da normal do shader, nao da malha.
	plano.subdivide_width = 0
	plano.subdivide_depth = 0
	mesh = plano

	_material = ShaderMaterial.new()
	_material.shader = load(SHADER)
	_material.set_shader_parameter("semente",
		randf() * 100.0 if semente < 0.0 else semente)
	_material.set_shader_parameter("direccao", randf() * TAU)
	_material.set_shader_parameter("espalhamento", 0.0)
	material_override = _material

	# O que se depoe nunca se tira (GDD §2), e uma poca no chao nao tapa
	# a luz de ninguem.
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## O balde a ser atirado. So no momento em que se depoe.
func atirar() -> void:
	_material.set_shader_parameter("espalhamento", 0.0)
	var t := create_tween()
	t.tween_method(_espalhar, 0.0, 1.0, DEMORA)
	_soar()


## O som cai com o balde, nao com a poca: quem recarrega o
## `assentamento` ve o sangue no chao e nao ouve nada, porque o balde foi
## atirado uma vez e ja foi. O tocador sai da arvore quando acaba — a
## poca fica para sempre, o som nao.
func _soar() -> void:
	if som == null:
		return
	var tocador := AudioStreamPlayer.new()
	tocador.stream = som
	add_child(tocador)
	tocador.finished.connect(tocador.queue_free)
	tocador.play()


## Ja esta no chao ha muito: aparece espalhada, sem repetir o gesto. E o
## que acontece quando o `assentamento` recarrega o que ja foi deposto —
## um deposito e um registo, nao volta a ser feito.
func assentada() -> void:
	_espalhar(1.0)


func _espalhar(v: float) -> void:
	_material.set_shader_parameter("espalhamento", v)
