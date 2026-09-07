// Texto escrito a tinta de fogo.
//
// Vai num `Label`: o que chega e a cobertura da letra no alfa. A cor da
// letra deita-se fora e pinta-se de novo por uma rampa de temperatura,
// com a brasa em baixo e o quente em cima, mais um tremor lento — como
// tinta que ainda esta a arder.
shader_type canvas_item;

uniform vec3 brasa : source_color = vec3(0.65, 0.08, 0.01);
uniform vec3 chama : source_color = vec3(1.0, 0.46, 0.06);
uniform vec3 nucleo : source_color = vec3(1.0, 0.93, 0.72);
uniform float brilho : hint_range(0.2, 4.0) = 1.5;
/// Quanto a tinta treme.
uniform float tremor : hint_range(0.0, 1.0) = 0.35;
/// Tamanho do grao do fogo, em pixeis de ecra.
uniform float grao : hint_range(4.0, 200.0) = 42.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y);
}

void fragment() {
	float letra = texture(TEXTURE, UV).a;
	if (letra < 0.01) {
		discard;
	}

	// O fogo anda em coordenadas de ECRA e nao da letra: assim atravessa
	// a frase inteira em vez de recomecar em cada glifo.
	vec2 p = SCREEN_UV * vec2(grao * 2.0, grao);
	float n = ruido(p + vec2(0.0, -TIME * 1.6));
	float n2 = ruido(p * 0.45 + vec2(TIME * 0.25, -TIME * 0.7));

	// Quente em cima, brasa em baixo, com o ruido a desmanchar a fronteira.
	float calor = clamp(1.0 - UV.y + (n - 0.5) * 0.75 + (n2 - 0.5) * 0.45, 0.0, 1.0);
	calor *= 1.0 - tremor * 0.35 * (0.5 + 0.5 * sin(TIME * 5.3 + n * 6.0));

	// O nucleo so aparece no muito quente. Antes abria a 0.62 e a frase
	// saía quase toda branca — lia-se como texto, nao como tinta a arder.
	vec3 cor = mix(brasa, chama, smoothstep(0.05, 0.48, calor));
	cor = mix(cor, nucleo, smoothstep(0.86, 1.06, calor));

	COLOR = vec4(cor * brilho, letra * COLOR.a);
}
