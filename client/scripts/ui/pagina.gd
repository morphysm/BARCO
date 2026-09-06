## O registo visual da interface: pagina impressa. SPEC.md §11.
##
## Sem cards, sem sombras suaves, sem cantos arredondados. Serifa, alta,
## em branco de pemba sobre preto. Esta aqui para o `risco` e o
## `assentamento` nao irem derivando cada um para o seu lado.
class_name Pagina
extends RefCounted

const TINTA := Color(0.937, 0.925, 0.882)


static func texto(conteudo: String, tamanho: int) -> Label:
	var l := Label.new()
	l.text = conteudo
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", TINTA)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func botao(rotulo: String, tamanho := 22) -> Button:
	var b := Button.new()
	b.text = rotulo
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", tamanho)
	b.add_theme_color_override("font_color", TINTA)
	b.add_theme_color_override("font_hover_color", TINTA)
	b.add_theme_color_override("font_pressed_color", Color.BLACK)
	for estado in ["normal", "hover", "pressed", "focus"]:
		var caixa := StyleBoxFlat.new()
		caixa.bg_color = TINTA if estado == "pressed" else Color(0, 0, 0, 0)
		caixa.border_color = TINTA
		caixa.set_border_width_all(1)
		caixa.set_corner_radius_all(0)
		caixa.content_margin_left = 14
		caixa.content_margin_right = 14
		caixa.content_margin_top = 8
		caixa.content_margin_bottom = 8
		b.add_theme_stylebox_override(estado, caixa)
	return b
