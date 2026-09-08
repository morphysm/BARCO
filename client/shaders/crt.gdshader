// O vidro do monitor. Vai num `ColorRect` que tapa o ecra inteiro, por
// cima de tudo o resto, e le o que ja foi desenhado.
//
// Nao inventa cor nenhuma: a tela por baixo e branca sobre preto, e isto
// so lhe faz o que um tubo de raios catodicos fazia — arredonda o vidro,
// risca-o de varrimento, deixa o fosforo acender um pouco ao lado da
// letra, e escurece os cantos.
//
// A franja de cor e SO NO EXTREMO DA BORDA. Um monitor destes
// desalinhava os canhoes de cor nas margens, onde o feixe chega mais
// torto; ao centro ficava alinhado. Ao centro a letra tem de continuar
// legivel, entao o desvio comeca em `bordo_da_aberracao` e cresce dai
// para fora — no meio do ecra e exatamente zero.
shader_type canvas_item;

uniform sampler2D ecra : hint_screen_texture, repeat_disable, filter_linear;

/// Quanto o vidro embarriga. E o que curva as linhas de varrimento.
uniform float curvatura : hint_range(0.0, 0.5) = 0.085;
/// Quantas linhas de varrimento cabem na altura do ecra.
uniform float linhas : hint_range(0.0, 1200.0) = 500.0;
uniform float forca_das_linhas : hint_range(0.0, 1.0) = 0.20;
/// O halo do fosforo: a letra acende um pouco ao lado de si propria.
uniform float halo : hint_range(0.0, 2.0) = 0.55;
uniform float raio_do_halo : hint_range(0.0, 8.0) = 2.4;
/// O desvio dos canhoes de cor, em pixeis, ja no extremo da borda.
uniform float aberracao : hint_range(0.0, 8.0) = 2.8;
/// Onde a franja comeca. 0 = centro, 1 = borda. Abaixo disto: nada.
uniform float bordo_da_aberracao : hint_range(0.0, 1.0) = 0.74;
uniform float vinheta : hint_range(0.0, 1.0) = 0.42;
/// A corrente a oscilar. Muito pouco: isto e um monitor, nao uma avaria.
uniform float tremor : hint_range(0.0, 0.2) = 0.022;


/// O halo, num anel de amostras a volta do ponto.
float acender(vec2 uv, vec2 passo) {
	float m = 0.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.7853982;
		vec2 d = vec2(cos(a), sin(a)) * passo;
		vec3 c = texture(ecra, clamp(uv + d, vec2(0.0), vec2(1.0))).rgb;
		m = max(m, max(c.r, max(c.g, c.b)));
	}
	return m;
}


void fragment() {
	// O vidro: leva-se a coordenada ao centro, embarriga-se, e volta.
	vec2 meio = SCREEN_UV * 2.0 - 1.0;
	float r2 = dot(meio, meio);
	vec2 curvo = meio * (1.0 + curvatura * r2);
	vec2 uv = curvo * 0.5 + 0.5;

	// Fora do tubo nao ha imagem, ha caixa.
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		// A franja de cor: zero ate `bordo_da_aberracao`, e dai para fora
		// cresce com a distancia ao centro. `length(meio)` e o raio antes
		// da curvatura, que e o que se quer — a franja e do canhao, nao
		// do vidro.
		float borda = smoothstep(bordo_da_aberracao, 1.20, length(meio));
		vec2 fora = normalize(meio + vec2(1e-6)) * aberracao * borda * SCREEN_PIXEL_SIZE;

		float vermelho = texture(ecra, clamp(uv + fora, vec2(0.0), vec2(1.0))).r;
		float verde = texture(ecra, uv).g;
		float azul = texture(ecra, clamp(uv - fora, vec2(0.0), vec2(1.0))).b;
		vec3 cor = vec3(vermelho, verde, azul);

		// O fosforo acende a volta da letra.
		cor += acender(uv, SCREEN_PIXEL_SIZE * raio_do_halo) * halo * 0.5;

		// Varrimento, em coordenadas de ECRA: as linhas sao do monitor.
		float linha = 0.5 + 0.5 * cos(uv.y * linhas * 6.2831853);
		cor *= 1.0 - forca_das_linhas * linha;

		// Os cantos apagam-se, e a corrente oscila.
		cor *= 1.0 - vinheta * r2 * 0.5;
		cor *= 1.0 - tremor * (0.5 + 0.5 * sin(TIME * 3.1));

		COLOR = vec4(cor, 1.0);
	}
}
