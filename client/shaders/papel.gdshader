// Papel a arder. Sete dias, de fora para dentro.
//
// O papel nao desaparece de repente nem encolhe: come-se pelas bordas. O
// limiar corre sobre um ruido, e junto a fronteira fica uma orla de brasa
// e outra de carvao — que e como o papel arde, e nao um fade to black.
shader_type spatial;
// Iluminado como tudo o resto: um papel sem luz nenhuma brilha na
// escuridao da nganga e le-se como um cartao branco. So a brasa e que se
// acende por si.
render_mode cull_disabled;

uniform sampler2D escrito : source_color, filter_linear;
uniform float consumido : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cor_papel : source_color = vec4(0.86, 0.82, 0.72, 1.0);
uniform vec4 cor_carvao : source_color = vec4(0.08, 0.06, 0.05, 1.0);
uniform vec4 cor_brasa : source_color = vec4(1.0, 0.45, 0.12, 1.0);
uniform float orla : hint_range(0.005, 0.2) = 0.045;

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Ruido suave: o valor sorteado em cada celula, interpolado.
float macio(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = ruido(i);
	float b = ruido(i + vec2(1.0, 0.0));
	float c = ruido(i + vec2(0.0, 1.0));
	float d = ruido(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	// Come de fora para dentro: as bordas ardem primeiro.
	vec2 ao_centro = abs(UV - 0.5) * 2.0;
	float borda = max(ao_centro.x, ao_centro.y);
	float mapa = borda * 0.75 + macio(UV * 7.0) * 0.25;

	// O limiar vai de fora (1.0) para dentro (0.0) conforme consome.
	float limiar = 1.0 - consumido * 1.15;
	if (mapa > limiar + orla) {
		discard;                       // ja e cinza: nao ha nada
	}

	vec4 tinta = texture(escrito, UV);
	vec3 cor = mix(cor_papel.rgb, tinta.rgb, tinta.a);

	// Junto a fronteira: brasa e depois carvao.
	float perto = smoothstep(limiar - orla, limiar + orla, mapa);
	cor = mix(cor, cor_carvao.rgb, smoothstep(0.25, 0.85, perto));
	cor = mix(cor, cor_brasa.rgb, smoothstep(0.80, 1.0, perto) * (1.0 - smoothstep(0.97, 1.0, perto)));

	ALBEDO = cor;
	ROUGHNESS = 0.9;
	// A brasa arde: e a unica parte do papel que da luz.
	EMISSION = cor_brasa.rgb * smoothstep(0.80, 1.0, perto)
			* (1.0 - smoothstep(0.97, 1.0, perto)) * 2.0;
}
