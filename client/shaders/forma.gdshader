// O corpo de uma `FormaDancante`.
//
// Arquitectura copiada do `Hall_of_Repetition`
// (references/hall_of_repetion_procedural_architeture.md §33); o
// tratamento e outro. Aqui sao aparicoes de luz eletrica azul, nao
// silhuetas: somam luz em vez de tapar, acendem-se nas bordas, tremem
// como um contacto mal feito e esvaem-se em bruma junto ao chao.
//
// Sem luz, sem sombra, sem profundidade escrita.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec3 cor_nucleo : source_color = vec3(0.16, 0.44, 0.95);
uniform vec3 cor_borda : source_color = vec3(0.62, 0.92, 1.0);
uniform float brilho : hint_range(0.0, 3.0) = 1.0;
/// Quanto o corpo se acende so nas bordas. Alto = mais oco, mais fantasma.
uniform float contorno : hint_range(0.5, 6.0) = 1.5;
/// Quanto o corpo se acende POR DENTRO, e nao so na borda.
uniform float miolo : hint_range(0.0, 1.0) = 0.34;
/// O tremor eletrico.
uniform float faisca : hint_range(0.0, 1.0) = 0.35;
/// Onde a bruma come a figura, do chao para cima, em metros.
uniform float bruma : hint_range(0.0, 2.0) = 0.62;
uniform float fractura = 0.05;
uniform float fase = 0.0;
uniform float opacidade : hint_range(0.0, 1.0) = 1.0;

varying float altura_mundo;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	float rasgo = sin(VERTEX.y * 19.0 + TIME * 9.0 + fase * 7.0);
	VERTEX.x += rasgo * fractura * 0.018;
	VERTEX.z -= rasgo * fractura * 0.011;
	altura_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	// Nas bordas a figura acende; ao centro quase se apaga. E o que faz
	// um corpo parecer oco em vez de solido.
	float fres = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), contorno);
	// Nao so contorno: um fantasma tem massa. Com o miolo a zero as
	// primitivas ficam a vista uma a uma e le-se como caixas desenhadas.
	float acesa = mix(miolo, 1.0, fres);

	// Tremor: duas frequencias altas e desencontradas, mais um salto raro.
	float t = TIME + fase * 3.7;
	float tremor = 1.0
		+ faisca * 0.55 * sin(t * 23.0 + fase * 9.0)
		+ faisca * 0.30 * sin(t * 61.0);
	// O salto: de vez em quando a figura quase se apaga, como um contacto
	// mal feito. Sem isto o tremor le-se como pulsacao, nao como corrente.
	float quebra = step(0.985, hash(vec2(floor(t * 12.0), fase)));
	tremor *= 1.0 - quebra * 0.75;

	// Bruma: junto ao chao a figura deixa de ter pernas e passa a ter
	// fumo. So se ve de onde a bruma acaba para cima.
	float fora_da_bruma = smoothstep(0.0, max(bruma, 0.001), altura_mundo);

	vec3 cor = mix(cor_nucleo, cor_borda, fres);
	float forca = acesa * tremor * fora_da_bruma * brilho * opacidade;

	ALBEDO = cor * max(forca, 0.0);
	ALPHA = clamp(forca, 0.0, 1.0);
}
