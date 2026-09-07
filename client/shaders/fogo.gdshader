// Fogo, num QUAD virado a camara — nao numa esfera.
//
// Uma `SphereMesh` e uma casca: todos os fragmentos estao a distancia 1
// do centro, entao uma queda radial calculada sobre ela nao corta nada e
// o fogo sai um ovo aceso. Num quad o espaco e o do plano e a silhueta e
// nossa.
//
// UV: x atravessa, y sobe (0 em baixo). `crescimento` (0..1) abre a
// chama; `fase` desencontra duas chamas postas lado a lado.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform float crescimento : hint_range(0.0, 1.0) = 1.0;
uniform float fase = 0.0;
uniform float subida : hint_range(0.1, 4.0) = 1.5;
uniform float detalhe : hint_range(0.5, 12.0) = 4.2;
uniform float brilho : hint_range(0.05, 3.0) = 1.25;
uniform vec3 nucleo : source_color = vec3(1.0, 0.97, 0.86);
uniform vec3 chama : source_color = vec3(1.0, 0.60, 0.14);
uniform vec3 borda : source_color = vec3(0.70, 0.09, 0.02);

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

// Quatro oitavas. A chama precisa de franja fina e de massa larga ao
// mesmo tempo, e uma so oitava nao da as duas.
float turbulencia(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += a * ruido(p);
		p = p * 2.07 + vec2(3.1, 1.7);
		a *= 0.5;
	}
	return s;
}

void vertex() {
	// Virado a camara mas SEMPRE DE PE: roda so em torno do proprio eixo
	// vertical. Uma chama deitada de lado nao existe.
	//
	// A escala e reposta a mao — o `billboard` de fabrica deita-a fora, e
	// entao a bola de fogo nao podia crescer.
	vec3 cima = normalize(MODEL_MATRIX[1].xyz);
	vec3 para_camara = INV_VIEW_MATRIX[2].xyz;
	vec3 lado = normalize(cross(cima, para_camara));
	vec3 frente = cross(lado, cima);
	float sx = length(MODEL_MATRIX[0].xyz);
	float sz = length(MODEL_MATRIX[2].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(lado * sx, 0.0),
		MODEL_MATRIX[1],
		vec4(frente * sz, 0.0),
		MODEL_MATRIX[3]);
}

void fragment() {
	vec2 uv = UV;
	uv.y = 1.0 - uv.y;             // y a subir
	float x = (uv.x - 0.5) * 2.0;  // -1 .. 1
	float y = uv.y;                // 0 em baixo, 1 em cima

	float t = TIME * subida + fase;

	// O ruido sobe e estica-se: dividir o y antes de amostrar faz as
	// manchas sairem altas e estreitas, que e a forma de uma lingua.
	vec2 q = vec2(x * detalhe, y * detalhe * 0.55 - t);
	float n = turbulencia(q);
	float n2 = turbulencia(vec2(x * detalhe * 0.5, y * detalhe * 0.28 - t * 0.55));

	// A forma: larga em baixo, a fechar em cima. E o que faz uma chama e
	// nao uma nuvem.
	float largura = (1.0 - y) * 0.85 + 0.15;
	// O ruido come o contorno — a chama nunca tem borda lisa.
	float d = abs(x) / max(largura, 0.001) + (n - 0.5) * 1.35 * (0.35 + y);
	float corpo = 1.0 - smoothstep(0.35, 1.0, d);
	// Em baixo assenta na boca; em cima esvai-se.
	corpo *= smoothstep(0.0, 0.10, y) * (1.0 - smoothstep(0.55, 1.05, y - (n2 - 0.5) * 0.35));

	float calor = corpo * (0.40 + 1.15 * n) * (0.55 + 0.8 * n2);
	calor *= smoothstep(0.0, 0.30, crescimento);
	calor = clamp(calor, 0.0, 1.5);

	vec3 cor = mix(borda, chama, smoothstep(0.10, 0.48, calor));
	cor = mix(cor, nucleo, smoothstep(0.60, 1.05, calor));

	ALBEDO = cor * calor * brilho;
	ALPHA = smoothstep(0.05, 0.24, calor);
}
