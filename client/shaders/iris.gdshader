// A iris: um circulo que abre a partir do centro e mostra o que esta por
// baixo. Desenha-se por cima de tudo, e o que esta fora do circulo e
// preto opaco.
//
// `abertura` 0 = tudo preto; 1 = tudo aberto.
shader_type canvas_item;

uniform float abertura : hint_range(0.0, 1.0) = 0.0;
uniform float proporcao = 0.5625;
// Quao esbatida e a borda. Uma iris de aresta viva le-se como um buraco
// recortado; esbatida le-se como luz a chegar.
uniform float margem : hint_range(0.001, 0.4) = 0.12;

void fragment() {
	vec2 p = UV - vec2(0.5);
	p.x *= proporcao;
	float r = length(p) / 0.72;   // 0.72 = o canto, para abrir ate ao fim
	// Cresce mais do que 1 para a borda sair mesmo do ecra no fim.
	float raio = abertura * (1.0 + margem);
	float dentro = smoothstep(raio, raio - margem, r);
	COLOR = vec4(0.0, 0.0, 0.0, 1.0 - dentro);
}
