// A mesma queima do papel, em duas dimensoes, para o menu.
//
// Repete a logica de `papel.gdshader` porque um shader de canvas_item nao
// pode ser o mesmo de um spatial. Se um mudar, o outro tem de mudar: e a
// mesma folha vista de dois sitios.
shader_type canvas_item;

uniform float consumido : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cor_papel : source_color = vec4(0.86, 0.82, 0.72, 1.0);
uniform vec4 cor_carvao : source_color = vec4(0.08, 0.06, 0.05, 1.0);
uniform vec4 cor_brasa : source_color = vec4(1.0, 0.45, 0.12, 1.0);
uniform float orla : hint_range(0.005, 0.2) = 0.045;

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float macio(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(ruido(i), ruido(i + vec2(1.0, 0.0)), f.x),
			mix(ruido(i + vec2(0.0, 1.0)), ruido(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 ao_centro = abs(UV - 0.5) * 2.0;
	float mapa = max(ao_centro.x, ao_centro.y) * 0.75 + macio(UV * 7.0) * 0.25;
	float limiar = 1.0 - consumido * 1.15;
	if (mapa > limiar + orla) {
		discard;
	}
	vec4 tinta = texture(TEXTURE, UV);
	vec3 cor = mix(cor_papel.rgb, tinta.rgb, tinta.a);
	float perto = smoothstep(limiar - orla, limiar + orla, mapa);
	cor = mix(cor, cor_carvao.rgb, smoothstep(0.25, 0.85, perto));
	cor = mix(cor, cor_brasa.rgb, smoothstep(0.80, 1.0, perto) * (1.0 - smoothstep(0.97, 1.0, perto)));
	COLOR = vec4(cor, 1.0);
}
