// A face de uma `FormaDancante`.
//
// O desenho e tinta preta sobre branco, e e a TINTA que acende.
//
// A primeira tentativa deixou a imagem como estava: com blend_add o preto
// somado nao acende nada e o branco de fundo dissolvia-se no brilho da
// cabeca — nao se via face nenhuma. Aqui le-se o negativo: onde ha tinta
// ha luz, e o resto nao existe. Sai um desenho de face aceso, e e por
// isso que uma delas pode ser vermelha.
//
// O tratamento e o do documento do `Hall_of_Repetition` §28: deslocacao
// horizontal, quebra da textura, oscilacao da opacidade, falhas no tempo
// e um desencontro pequeno da imagem. Contido. Nao e falha de computador:
// e chapa fotografica estragada, gravura mal registada, imagem a dobrar.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform sampler2D desenho : source_color, filter_linear;
uniform vec3 cor : source_color = vec3(0.62, 0.92, 1.0);
uniform float brilho : hint_range(0.0, 4.0) = 1.35;
uniform float opacidade : hint_range(0.0, 1.0) = 1.0;
/// Quanto a chapa esta estragada.
uniform float estrago : hint_range(0.0, 1.0) = 0.35;
uniform float fase = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float t = TIME + fase * 5.1;

	// Deslocacao horizontal por bandas. Poucas bandas e devagar: muitas e
	// depressa le-se como avaria de ecra.
	float banda = floor(UV.y * 34.0);
	float desvio = (hash(vec2(banda, floor(t * 3.0))) - 0.5) * 0.016 * estrago;
	// So algumas bandas se mexem de cada vez.
	desvio *= step(0.78, hash(vec2(banda, floor(t * 3.0) + 11.0)));

	vec2 uv = UV + vec2(desvio, 0.0);

	// Desencontro da imagem: uma segunda leitura um fio ao lado, mais
	// fraca. E o que faz a face parecer impressa duas vezes.
	vec4 a = texture(desenho, uv);
	vec4 b = texture(desenho, uv + vec2(0.004, -0.003) * estrago);

	// O branco acende, a tinta fica por acender.
	// 1.0 - luminancia: a tinta e que acende.
	float luz_a = 1.0 - dot(a.rgb, vec3(0.299, 0.587, 0.114));
	float luz_b = 1.0 - dot(b.rgb, vec3(0.299, 0.587, 0.114));
	float luz = max(luz_a, luz_b * 0.45);
	float alfa = max(a.a, b.a * 0.45);

	// Oscilacao e falhas: de vez em quando a face quase desaparece.
	float oscila = 1.0 - estrago * 0.22 * (0.5 + 0.5 * sin(t * 7.3 + fase * 3.0));
	float falha = 1.0 - step(0.972, hash(vec2(floor(t * 9.0), fase))) * 0.8 * estrago;

	float forca = luz * alfa * opacidade * oscila * falha;
	ALBEDO = cor * forca * brilho;
	ALPHA = clamp(forca, 0.0, 1.0);
}
