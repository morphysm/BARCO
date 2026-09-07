// Texto de terminal: fosforo verde, como um monitor monocromatico velho.
//
// Vai num `Label`. A cor da letra deita-se fora e o que fica e o brilho
// do fosforo: um verde so, com o halo curto que a letra deixava no vidro,
// as linhas de varrimento por cima, e o tremor lento da corrente.
//
// Sobrio de proposito. Nao ha rampa de cores, nao ha faisca, nao ha
// nucleo branco — um monitor destes so sabia fazer uma cor.
shader_type canvas_item;

/// O verde. O IBM 5151 usava fosforo P39, mais frio do que um verde puro.
uniform vec3 fosforo : source_color = vec3(0.22, 1.0, 0.42);
uniform float brilho : hint_range(0.1, 3.0) = 0.92;
/// O halo que a letra deixa no vidro.
uniform float halo : hint_range(0.0, 1.0) = 0.30;
/// Quantas linhas de varrimento cabem no ecra.
uniform float varrimento : hint_range(0.0, 1200.0) = 420.0;
/// Quanto as linhas escurecem.
uniform float forca_do_varrimento : hint_range(0.0, 1.0) = 0.28;
/// O tremor da corrente. Muito pouco: isto e um monitor, nao uma avaria.
uniform float tremor : hint_range(0.0, 0.5) = 0.06;

void fragment() {
	float letra = texture(TEXTURE, UV).a;

	// O halo: le-se a letra tambem um pouco ao lado e acima, mais fraco.
	// E o que faz o fosforo parecer aceso e nao impresso.
	vec2 passo = TEXTURE_PIXEL_SIZE * 2.0;
	float a = texture(TEXTURE, UV + vec2(passo.x, 0.0)).a;
	a = max(a, texture(TEXTURE, UV - vec2(passo.x, 0.0)).a);
	a = max(a, texture(TEXTURE, UV + vec2(0.0, passo.y)).a);
	a = max(a, texture(TEXTURE, UV - vec2(0.0, passo.y)).a);
	float aceso = max(letra, a * halo);
	if (aceso < 0.01) {
		discard;
	}

	// Varrimento em coordenadas de ECRA: as linhas sao do monitor, nao do
	// texto, entao nao andam com a frase.
	float linha = 0.5 + 0.5 * cos(SCREEN_UV.y * varrimento * 6.2831853);
	float vidro = 1.0 - forca_do_varrimento * linha;

	// A corrente oscila devagar.
	vidro *= 1.0 - tremor * (0.5 + 0.5 * sin(TIME * 3.1));

	COLOR = vec4(fosforo * brilho * vidro, aceso * COLOR.a);
}
