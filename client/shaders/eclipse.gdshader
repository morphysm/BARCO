// O eclipse: o sol imenso que a lua cobre ate ficar sol negro.
//
// Uma so passagem, sem luz de motor nenhuma — isto e 2D, desenha-se por
// cima de tudo. `fase` vai de 0 a 1 e conta a travessia inteira:
//
//   0.00 .. 0.45   o sol aberto, a lua a entrar pela esquerda
//   0.45 .. 0.62   a mordida fecha-se
//   0.62 .. 0.82   totalidade: disco preto, anel, serpentinas
//   0.82 .. 1.00   a coroa apaga-se e fica o escuro
//
// A cor anda com ela: branco quente no principio, vermelho fundo ao
// fechar. A luz nao desaparece, arrefece.
shader_type canvas_item;
render_mode blend_mix;

uniform float fase : hint_range(0.0, 1.0) = 0.0;
uniform float proporcao = 0.5625;   // largura/altura do ecra
uniform float tamanho : hint_range(0.05, 1.2) = 0.34;
uniform vec3 cor_quente : source_color = vec3(1.0, 0.94, 0.82);
uniform vec3 cor_fria : source_color = vec3(1.0, 0.30, 0.10);
uniform vec3 cor_coroa : source_color = vec3(1.0, 0.72, 0.42);

// Ruido barato, so para a coroa nao ser um anel perfeito de compasso.
float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float suave(float a, float b, float x) {
	return smoothstep(a, b, x);
}

void fragment() {
	// Espaco quadrado a contar do centro, para o sol ser redondo em
	// qualquer ecra. So o x e corrigido: o raio conta-se em alturas de
	// ecra, entao `tamanho` quer dizer o mesmo em qualquer janela.
	vec2 p = UV - vec2(0.5);
	p.x *= proporcao;
	float r = length(p);
	float ang = atan(p.y, p.x);

	float raio = tamanho;

	// A lua entra pela esquerda e para no centro. Fica la ate ao fim: o
	// sol negro nao se abre outra vez.
	float entrada = suave(0.0, 0.62, fase);
	vec2 lua = vec2(mix(-2.2 * raio - 0.45, 0.0, entrada), mix(0.34 * raio, 0.0, entrada));
	float rl = length(p - lua);

	// Duas medidas diferentes, e confundi-las era o erro: com uma so, o
	// anel de totalidade acendia-se a meio da travessia.
	//   `cobertura`  quanto do sol esta tapado — anda devagar, e o que
	//                arrefece a cor.
	//   `totalidade` se a lua esta MESMO em cima — so no fim, e o que
	//                acende o anel e faz a coroa saltar.
	float d = length(lua) / max(raio, 0.001);
	float cobertura = 1.0 - clamp(d * 0.5, 0.0, 1.0);
	float totalidade = suave(0.30, 0.015, d);

	// --- disco ---
	// Borda curta: e uma estrela, nao um circulo desenhado.
	float disco = suave(raio, raio - 0.004, r);
	float disco_lua = suave(raio, raio - 0.0035, rl);

	// --- coroa ---
	// Serpentinas: varias ondas em angulo, com periodos primos entre si,
	// para nao se lerem como uma flor de petalas iguais.
	float serp = 0.62
		+ 0.22 * sin(ang * 7.0 + 1.3)
		+ 0.13 * sin(ang * 13.0 - 0.7)
		+ 0.08 * sin(ang * 23.0 + 2.1);
	serp *= 0.92 + 0.16 * ruido(vec2(floor(ang * 60.0), 3.0));

	// A coroa so se ve quando o disco se apaga — com o sol aberto ela la
	// esta, mas ninguem a ve, e aqui e igual.
	float forca_coroa = mix(0.07, 1.0, totalidade);
	float coroa = exp(-(r - raio) * mix(30.0, 7.0, totalidade) / max(serp, 0.05));
	coroa *= step(raio, r) * forca_coroa;

	// --- anel ---
	// O fio de luz que sobra quando a lua assenta em cima do sol.
	float anel = exp(-abs(r - raio) * 420.0) * totalidade;

	// --- juntar ---
	// A cor so vira ao vermelho no fim: elevado a potencia, a cobertura
	// quase nao conta ate o sol estar mesmo quase todo tapado.
	vec3 cor_disco = mix(cor_quente, cor_fria, pow(cobertura, 3.0));
	float brilho_disco = mix(1.0, 0.62, pow(cobertura, 2.0));

	vec3 cor = vec3(0.0);
	cor += cor_disco * disco * brilho_disco;
	cor += cor_coroa * coroa * 0.85;
	cor += cor_quente * anel * 1.6;

	// A lua e um buraco, nao um objeto: apaga o que estiver por baixo.
	cor *= 1.0 - disco_lua;

	// Depois da totalidade tudo arrefece ate ao preto.
	float saida = 1.0 - suave(0.82, 1.0, fase);
	cor *= saida;

	COLOR = vec4(cor, 1.0);
}
