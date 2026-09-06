## Um traco de `pemba` na tela. SPEC.md §4.1.
##
## O caminho do `ponto` nao e mostrado — so o que o dedo ja depositou.
class_name PembaTraco
extends Line2D

const LARGURA := 9.0

## Branco de pemba. Vermelho fica reservado ao `ponto` firmado com
## `sacrificio` (SPEC.md §8.2) — nao usar aqui.
const BRANCO := Color(0.937, 0.925, 0.882)

static func textura_pincel() -> ImageTexture:
	# Queda suave atravessando a largura do traco, para o grao ter borda.
	var img := Image.create(4, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var t := float(y) / 63.0
		var a := 1.0 - pow(absf(t * 2.0 - 1.0), 1.6)
		for x in 4:
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

func _init() -> void:
	width = LARGURA
	default_color = Color.WHITE
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND
	antialiased = false
	texture = textura_pincel()
	texture_mode = Line2D.LINE_TEXTURE_STRETCH
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/pemba.gdshader")
	mat.set_shader_parameter("cor", BRANCO)
	material = mat
