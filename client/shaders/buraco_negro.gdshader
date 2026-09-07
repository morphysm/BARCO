// O buraco no teto, e as estrelas negras a volta.
//
// As estrelas sao pontos de luz — pontinhos, nao argolas.
//
// A primeira versao desenhava-as como FALTAS, furos escuros com um fio a
// volta. Lidas de perto no teto, o furo desaparecia contra o escuro e
// so restava o fio: viam-se bolas. Agora e o contrario — um nucleo
// pequeno e duro, um halo curto, e nada mais.
//
// O buraco roda por dentro mais depressa do que por fora, como uma coisa
// a cair. Um disco que rodasse todo ao mesmo passo leria-se como um
// autocolante a girar.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

/// Raio do horizonte, em unidades de UV (0.5 = metade do quad).
uniform float horizonte : hint_range(0.01, 0.45) = 0.085;
/// O anel de luz que fica preso a borda.
uniform float anel : hint_range(0.0, 0.2) = 0.026;
/// Prata, nao ouro: o anel e luz a ser torcida, nao lume. O amarelo
/// puxava-o para o lado da fornalha, e sao coisas diferentes.
uniform vec3 cor_do_anel : source_color = vec3(0.78, 0.82, 0.88);
/// Quao depressa tudo roda.
uniform float rotacao : hint_range(-2.0, 2.0) = 0.12;
/// Quanto o centro roda mais depressa do que a borda.
uniform float arrasto : hint_range(0.0, 4.0) = 1.6;
/// Quantas estrelas, e quao grandes.
uniform float densidade : hint_range(4.0, 160.0) = 78.0;
uniform float tamanho_da_estrela : hint_range(0.005, 0.3) = 0.045;
/// A cor dos pontos.
uniform vec3 cor_da_estrela : source_color = vec3(0.86, 0.90, 1.0);
/// Quao apertado e o nucleo. Alto = ponto mais fino.
uniform float dureza : hint_range(1.0, 12.0) = 5.0;
/// O ceu por tras de tudo. Quase preto, mas NAO preto: uma estrela negra
/// so se ve pelo que apaga, e sobre o nada nao apaga nada. Sem esta
/// nevoa as estrelas liam-se como argolinhas a flutuar.
uniform vec3 cor_do_ceu : source_color = vec3(0.030, 0.028, 0.050);
uniform vec3 cor_da_nevoa : source_color = vec3(0.16, 0.13, 0.30);
uniform float nevoa : hint_range(0.0, 1.0) = 0.72;
uniform float brilho : hint_range(0.0, 3.0) = 1.0;

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

/// Nevoa em manchas largas, para as estrelas terem o que apagar.
float bruma(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		s += a * ruido(p);
		p = p * 2.13 + vec2(4.7, 2.9);
		a *= 0.5;
	}
	return s;
}

vec2 hash2(vec2 p) {
	return vec2(hash(p), hash(p + vec2(37.2, 11.9)));
}

/// Pontos numa grelha desarrumada. Devolve o brilho acumulado.
float estrelas(vec2 p) {
	vec2 celula = floor(p);
	vec2 dentro = fract(p);
	float luz = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 v = vec2(float(x), float(y));
			vec2 c = celula + v;
			// Nem toda a celula tem estrela, senao le-se como uma grelha.
			if (hash(c + vec2(5.3, 2.1)) > 0.62) {
				continue;
			}
			vec2 onde = v + hash2(c) * 0.9 + 0.05;
			float d = length(dentro - onde);
			// Cada uma com o seu brilho: um ceu de estrelas todas iguais
			// nao e um ceu.
			float forca = 0.25 + 0.95 * hash(c + vec2(9.1, 4.4));
			float r = max(tamanho_da_estrela, 0.001);
			// Nucleo duro e halo curto. Sem o halo os pontos cintilam
			// contra a grelha de pixeis; com halo a mais viram bolas.
			float nucleo = exp(-pow(d / r, dureza));
			float halo = exp(-d / (r * 2.6)) * 0.22;
			luz += (nucleo + halo) * forca;
		}
	}
	return luz;
}


void fragment() {
	vec2 p = UV - vec2(0.5);
	float r = length(p);
	float ang = atan(p.y, p.x);

	// Rotacao diferencial: por dentro anda mais depressa.
	float giro = TIME * rotacao * (1.0 + arrasto / max(r * 6.0 + 0.35, 0.001));
	float a = ang + giro;
	vec2 rodado = vec2(cos(a), sin(a)) * r;

	// As estrelas vivem no campo rodado, entao caem para dentro com ele.
	float e = estrelas(rodado * densidade);

	// A nevoa roda com o resto — e o que da a sensacao de que tudo esta a
	// ser puxado para dentro.
	float n = bruma(rodado * 3.4);
	// Um fundo por todo o lado, e manchas por cima. So com as manchas
	// ficavam zonas de ceu preto, e as estrelas que la caem nao apagam
	// nada — leem-se como argolinhas.
	float ceu = 0.38 + 0.62 * smoothstep(0.20, 0.78, n);
	vec3 cor = cor_do_ceu + cor_da_nevoa * nevoa * ceu;
	cor += cor_da_estrela * e;

	// Perto do horizonte tudo se estica e apaga.
	float queda = smoothstep(horizonte * 3.2, horizonte * 1.05, r);
	cor *= 1.0 - queda;

	// O anel preso a borda. Fino, e mais brilhante de um lado — o lado
	// que vem na nossa direcao.
	float lado = 0.72 + 0.55 * cos(a);
	float no_anel = exp(-abs(r - (horizonte + anel * 0.5)) / max(anel * 0.42, 0.0001));
	cor += cor_do_anel * no_anel * lado * 0.85;

	// O horizonte: preto a serio, sem nada por cima.
	float dentro_do_horizonte = smoothstep(horizonte + 0.004, horizonte - 0.004, r);
	cor *= 1.0 - dentro_do_horizonte;

	// Fora do quad esbate-se, para o teto nao ter uma aresta.
	float bordo = 1.0 - smoothstep(0.42, 0.5, r);

	ALBEDO = cor * brilho;
	ALPHA = clamp(max(bordo, dentro_do_horizonte), 0.0, 1.0);
}
