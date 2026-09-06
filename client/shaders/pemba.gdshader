// pemba — giz sobre pedra. SPEC.md §4.1, §11.
//
// Aplicado ao Line2D do traco. Rasga o alfa com grao para que o traco
// nunca seja uma linha limpa de vetor: pemba e po, deposita irregular e
// falha onde a pedra e lisa.
//
// Paleta: vermelho, dourado, branco de pemba. Nada mais (SPEC.md §11).
shader_type canvas_item;

uniform vec4 cor : source_color = vec4(0.937, 0.925, 0.882, 1.0);
uniform float densidade : hint_range(40.0, 400.0) = 190.0;
uniform float grao : hint_range(0.0, 1.0) = 0.65;
uniform float corte : hint_range(0.0, 0.9) = 0.30;

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	// UV.y atravessa a largura do Line2D; a textura do pincel da a queda
	// nas bordas.
	float borda = texture(TEXTURE, UV).a;

	vec2 cel = floor(FRAGCOORD.xy * (densidade / 300.0));
	float n = ruido(cel) * 0.55 + ruido(cel * 2.13 + 7.0) * 0.45;
	float po = mix(1.0, n * 1.6, grao);

	float a = smoothstep(corte, corte + 0.28, borda * po);
	COLOR = vec4(cor.rgb, a * cor.a * COLOR.a);
}
