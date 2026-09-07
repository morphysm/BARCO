// O corpo de uma `FormaDancante`. Copiado do `Hall_of_Repetition`
// (references/hall_of_repetion_procedural_architeture.md §33).
//
// Sem luz, sem sombra, sem profundidade escrita: sao aparicoes, nao
// gente. A fractura fica quase invisivel — a instabilidade e para se
// sentir, nao para se ver.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

uniform float fractura = 0.05;
uniform float fase = 0.0;
uniform vec4 tinta : source_color = vec4(0.16, 0.05, 0.04, 0.85);

void vertex() {
	float rasgo = sin(VERTEX.y * 19.0 + TIME * 9.0 + fase * 7.0);
	VERTEX.x += rasgo * fractura * 0.018;
	VERTEX.z -= rasgo * fractura * 0.011;
}

void fragment() {
	ALBEDO = tinta.rgb;
	ALPHA = tinta.a;
}
