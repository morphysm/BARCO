// O fumo de onde as formas saem.
//
// Um quad virado a camara. `abrir` (0..1) leva-o do nada ao seu tamanho e
// depois esvai-o: cresce, engrossa e desfaz-se, e a figura fica.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform float abrir : hint_range(0.0, 1.0) = 0.0;
uniform float fase = 0.0;
uniform vec3 cor : source_color = vec3(0.30, 0.42, 0.72);
uniform float brilho : hint_range(0.0, 3.0) = 0.85;
uniform float detalhe : hint_range(0.5, 10.0) = 3.4;

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

float turbulencia(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += a * ruido(p);
		p = p * 2.09 + vec2(2.7, 5.3);
		a *= 0.5;
	}
	return s;
}

void vertex() {
	vec3 cima = normalize(MODEL_MATRIX[1].xyz);
	vec3 para_camara = INV_VIEW_MATRIX[2].xyz;
	vec3 lado = normalize(cross(cima, para_camara));
	vec3 frente = cross(lado, cima);
	float sx = length(MODEL_MATRIX[0].xyz);
	float sz = length(MODEL_MATRIX[2].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(lado * sx, 0.0), MODEL_MATRIX[1], vec4(frente * sz, 0.0), MODEL_MATRIX[3]);
}

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float t = TIME * 0.55 + fase * 3.3;

	// O fumo sobe enquanto se desfaz.
	vec2 q = vec2(p.x * detalhe, p.y * detalhe * 0.7 - t);
	float n = turbulencia(q);

	// Uma bola larga em baixo que se abre para cima.
	float alto = clamp(UV.y, 0.0, 1.0);
	float largura = 0.55 + 0.75 * (1.0 - alto);
	float d = length(vec2(p.x / max(largura, 0.001), p.y * 0.85)) + (n - 0.5) * 1.1;
	float corpo = 1.0 - smoothstep(0.35, 1.0, d);

	// Cresce depressa e esvai-se: mais forte a meio da abertura.
	float vida = sin(clamp(abrir, 0.0, 1.0) * PI);
	float forca = corpo * (0.4 + 0.9 * n) * vida;

	ALBEDO = cor * forca * brilho;
	ALPHA = clamp(forca, 0.0, 1.0);
}
