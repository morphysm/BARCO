// Ferro bruto, enferrujado. Manchas de ferrugem sobre metal escuro, sem
// textura nenhuma: o desenho sai de ruido no espaco do MODELO, para as
// manchas ficarem agarradas a peca e nao ao mundo.
//
// Nao e um metal limpo com um mapa de sujidade por cima — e ferro que
// esteve muito tempo ao lume: rugoso em todo o lado, com a ferrugem a
// pegar mais nas arestas e nas partes de cima, que e onde a agua para.
shader_type spatial;

// O ferro por baixo.
uniform vec3 cor_ferro : source_color = vec3(0.085, 0.078, 0.075);
// A ferrugem. Duas, para nao ser uma mancha de uma cor so.
uniform vec3 cor_ferrugem : source_color = vec3(0.34, 0.13, 0.055);
uniform vec3 cor_ferrugem_clara : source_color = vec3(0.52, 0.24, 0.09);
// Quanta ferrugem ha, de 0 (ferro limpo) a 1 (comido).
uniform float ferrugem : hint_range(0.0, 1.0) = 0.62;
// Tamanho das manchas, em metros.
uniform float escala : hint_range(0.2, 40.0) = 7.0;
// Quanto a ferrugem prefere as faces viradas para cima.
uniform float assentar : hint_range(0.0, 1.0) = 0.45;

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float ruido(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x),
			mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
			mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y),
		f.z);
}

float turbulencia(vec3 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += a * ruido(p);
		p = p * 2.11 + vec3(5.2, 1.3, 9.7);
		a *= 0.5;
	}
	return s;
}

varying vec3 pos_modelo;
varying vec3 nor_modelo;

void vertex() {
	pos_modelo = VERTEX;
	nor_modelo = NORMAL;
}

void fragment() {
	float n = turbulencia(pos_modelo * escala);
	float fino = ruido(pos_modelo * escala * 6.0);

	// A agua para nas faces viradas para cima, e e ai que o ferro come.
	float para_cima = clamp(nor_modelo.y * 0.5 + 0.5, 0.0, 1.0);
	float onde = n + assentar * (para_cima - 0.5);

	// Limiar em vez de mistura suave: ferrugem tem borda, nao degrade.
	float manchas = smoothstep(0.48 - ferrugem * 0.30, 0.62 - ferrugem * 0.22, onde);
	float miolo = smoothstep(0.55, 0.78, onde);

	vec3 cor = mix(cor_ferro, cor_ferrugem, manchas);
	cor = mix(cor, cor_ferrugem_clara, miolo * 0.55);
	// Grao fino por cima, para nao haver zonas chapadas.
	cor *= 0.86 + 0.28 * fino;

	ALBEDO = cor;
	// O ferro limpo ainda reflete alguma coisa; a ferrugem nao reflete
	// nada. E a diferenca que faz ler como duas materias e nao como uma
	// pintada de duas cores.
	METALLIC = (1.0 - manchas) * 0.55;
	ROUGHNESS = mix(0.62, 0.98, manchas) - 0.06 * fino;
}
