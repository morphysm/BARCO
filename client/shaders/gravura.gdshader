// gravura — hachura sobre preto. SPEC.md §11.
//
// O `assentamento` nao e um quarto iluminado: e uma chapa. Nada aqui usa
// a iluminacao do motor. A luz e uma so, dada por uniform — a vela que o
// praticante acendeu — e o sombreado nao e um degrade, e uma trama de
// linhas que adensa onde a luz bate. Preto onde nao bate.
//
// Paleta: vermelho, dourado, branco de pemba. Nada mais (SPEC.md §11).
shader_type spatial;
render_mode unshaded, cull_disabled, diffuse_burley;

// Cada vela acesa e uma luz. Acender e o que revela o `assentamento`:
// com uma vela ve-se um palmo, com tres ve-se a nganga.
const int MAX_LUZES = 6;
uniform vec3 luz_pos[MAX_LUZES];
uniform float luz_energia[MAX_LUZES];
uniform int luzes = 1;
// Uma vela alcanca um palmo, nao um quarto inteiro. Com um alcance
// grande demais a queda deixa de existir e o chao todo fica aceso — o
// oposto do que se quer.
uniform float alcance = 0.30;
uniform vec4 cor_tinta : source_color = vec4(0.937, 0.925, 0.882, 1.0);
uniform float passo = 0.15;       // espacamento da hachura, em pixeis
uniform float grao : hint_range(0.0, 1.0) = 0.12;

// Quanto a superficie responde a luz. O chao leva menos que os objetos:
// e uma extensao grande e de frente para as chamas, e com a mesma
// resposta ofusca a nganga que devia estar a mostrar.
uniform float resposta = 1.0;

varying vec3 mundo;
varying vec3 normal_mundo;

float ruido(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// Quanto mais luz, mais tinta. Quatro camadas de linhas cruzadas, na
// ordem em que um gravador as abriria.
float trama(vec2 s, float luz) {
	float t = 0.0;
	if (luz > 0.050) t = max(t, step(0.72, fract((s.x + s.y) * passo)));
	if (luz > 0.110) t = max(t, step(0.72, fract((s.x - s.y) * passo)));
	if (luz > 0.200) t = max(t, step(0.66, fract(s.x * passo * 1.3)));
	if (luz > 0.330) t = max(t, step(0.66, fract(s.y * passo * 1.3)));
	if (luz > 0.520) t = 1.0;
	return t;
}

void vertex() {
	mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(normal_mundo);
	float luz = 0.0;
	for (int i = 0; i < MAX_LUZES; i++) {
		if (i >= luzes) break;
		vec3 para_luz = luz_pos[i] - mundo;
		float distancia = length(para_luz);
		// Meio-lambert: uma superficie de esguelha a chama nao fica preta
		// de todo. Com o lambert cru quase tudo o que esta na nganga cai
		// para silhueta e perde-se o que la esta dentro.
		float bruto = dot(n, normalize(para_luz));
		float lambert = pow(max(bruto * 0.5 + 0.5, 0.0), 2.2);
		luz += lambert * luz_energia[i] / (1.0 + (distancia * distancia) / (alcance * alcance));
	}
	luz = clamp(luz * resposta, 0.0, 1.0);

	float t = trama(FRAGCOORD.xy, luz);
	float g = 1.0 - grao * ruido(floor(FRAGCOORD.xy * 0.5));
	// Opaco de proposito: onde nao ha tinta fica preto, que e o fundo.
	// Assim nao ha transparencia para ordenar.
	ALBEDO = cor_tinta.rgb * clamp(t * g, 0.0, 1.0);
}
