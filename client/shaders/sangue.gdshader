// O banho de sangue no chao do `assentamento`.
//
// Nao e uma mancha desenhada: e um liquido. O que o faz ler como
// liquido nao e a cor — e a luz das velas a andar por cima dele. A
// superficie tem uma pele que se move devagar, e dessa pele sai a
// normal; as velas do `assentamento` sao luzes a serio, entao os
// brilhos escorregam pela poca e nada disto precisa de ser animado a
// mao.
//
// A forma vem de um balde atirado, nao de um copo entornado: ha uma
// direccao, a lingua avanca mais para esse lado, e os pingos que se
// soltaram a frente caem depois da onda passar por eles.
//
// A geometria e um plano rente ao chao. Sobe-se `altura` no VERTEX e nao
// na posicao do no: quem assenta as oferendas mede a caixa da malha e
// poe a base a zero, portanto levantar o no nao servia de nada — voltava
// a ser empurrado para baixo. Assim a malha continua a zero para quem a
// mede, e so o que se desenha e que fica um milimetro e meio acima do
// chao, longe da briga de profundidade.
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back;

/// Quanto do balde ja se espalhou. 0 = ainda nada, 1 = a poca inteira.
uniform float espalhamento : hint_range(0.0, 1.0) = 1.0;
/// Cada poca e a sua: muda a borda, os pingos e a pele.
uniform float semente = 0.0;
/// Para que lado foi atirado, em radianos.
uniform float direccao = 0.0;
/// Quanto a poca se estica nessa direccao. 1 = redonda.
uniform float alongamento : hint_range(1.0, 2.5) = 1.35;
/// Quanto se levanta do chao, em metros.
uniform float altura = 0.0016;

uniform vec4 cor_funda : source_color = vec4(0.085, 0.006, 0.006, 0.96);
uniform vec4 cor_fina : source_color = vec4(0.38, 0.055, 0.032, 0.80);
uniform vec4 cor_do_lustro : source_color = vec4(0.52, 0.13, 0.10, 1.0);

/// A pele: quanto se move e quanto enruga.
uniform float velocidade : hint_range(0.0, 2.0) = 0.22;
uniform float ondulacao : hint_range(0.0, 3.0) = 1.1;


float baralhar(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}


float ruido(vec2 p) {
	vec2 cela = floor(p);
	vec2 t = fract(p);
	t = t * t * (3.0 - 2.0 * t);
	float a = baralhar(cela);
	float b = baralhar(cela + vec2(1.0, 0.0));
	float c = baralhar(cela + vec2(0.0, 1.0));
	float d = baralhar(cela + vec2(1.0, 1.0));
	return mix(mix(a, b, t.x), mix(c, d, t.x), t.y);
}


/// Duas camadas de ruido a andar em sentidos diferentes. E o que faz a
/// pele nao parecer uma textura a deslizar.
float pele(vec2 p, float tempo) {
	float a = ruido(p + vec2(tempo * 0.12, tempo * -0.08));
	float b = ruido(p * 2.13 + vec2(17.0, 5.0) + vec2(tempo * -0.07, tempo * 0.05));
	return a * 0.62 + b * 0.38;
}


void vertex() {
	VERTEX.y += altura;
}


void fragment() {
	// O plano, centrado e virado para o lado em que o balde foi.
	vec2 p = (UV - 0.5) * 2.0;
	float cs = cos(direccao);
	float sn = sin(direccao);
	p = mat2(vec2(cs, -sn), vec2(sn, cs)) * p;
	p.x /= alongamento;

	// O espalhar segue o som: um balde nao bate, despeja. O `.ogg`
	// comeca ja alto, engrossa ate ao pico e so depois esvazia — medido
	// por `tools/afinar_sangue.py`. Uma curva travada no fim punha a
	// poca quieta enquanto o ouvido ainda ouvia despejar.
	//
	// Daqui sai um S: devagar a abrir, mais rapido a meio, a assentar no
	// fim. O expoente poe o momento de maior crescimento em cima do pico
	// do som.
	float x = pow(clamp(espalhamento, 0.0, 1.0), 1.2);
	float ee = x * x * (3.0 - 2.0 * x);

	float ang = atan(p.y, p.x);
	float d = length(p);

	// A borda nao e um circulo: e ruido em volta do angulo, e a lingua
	// puxa para a frente.
	float borda = ruido(vec2(ang * 2.7 + semente * 13.0, 3.1));
	float raio = 0.44 + borda * 0.19 + 0.06 * sin(ang * 7.0 + semente * 4.0);
	raio *= 1.0 + 0.30 * pow(max(0.0, cos(ang)), 2.0);
	raio *= max(ee, 0.001);
	float nucleo = 1.0 - smoothstep(raio - 0.075, raio, d);

	// Os pingos ficam onde caem. Aparecem quando a onda chega ao sitio
	// deles, nao todos ao mesmo tempo.
	float pingos = 0.0;
	for (int i = 0; i < 7; i++) {
		float f = float(i);
		float a = ruido(vec2(f * 7.7 + semente, 1.3)) * 6.2831853;
		float r = 0.58 + ruido(vec2(f * 3.1 + semente, 5.5)) * 0.40;
		float tam = 0.018 + ruido(vec2(f * 2.2 + semente, 9.1)) * 0.042;
		vec2 centro = vec2(cos(a) * 1.25, sin(a)) * r;
		float chegou = smoothstep(r * 0.62, r * 0.92, ee);
		pingos = max(pingos, chegou
			* (1.0 - smoothstep(tam * 0.55, tam, distance(p, centro))));
	}

	float mascara = max(nucleo, pingos);
	if (mascara < 0.004) {
		discard;
	}

	// Grossura: fina na borda, funda no meio. E ela que manda na cor, na
	// rugosidade e no quanto se ve o chao por baixo.
	float grossura = smoothstep(raio, raio * 0.40, d);
	grossura = max(grossura, pingos * 0.35);

	vec2 uvp = UV * vec2(13.0, 10.0) + vec2(semente * 31.0);
	float sup = pele(uvp, TIME * velocidade);

	vec3 cor = mix(cor_fina.rgb, cor_funda.rgb, grossura);
	cor = mix(cor, cor_fina.rgb, sup * 0.22);

	// O menisco: a beira junta liquido e brilha mais que o resto.
	float beira = smoothstep(raio * 0.82, raio * 0.99, d) * nucleo;
	cor = mix(cor, cor_do_lustro.rgb, beira * 0.28);

	float lustro = pow(max(0.0, sup - 0.55) * 2.2, 4.0);
	cor = mix(cor, cor_do_lustro.rgb, lustro * 0.42);

	// A normal sai da propria pele: e daqui que vem o liquido. Sem isto
	// a poca e uma mancha vermelha, por muito bem desenhada que esteja.
	float e = 0.035;
	float gx = pele(uvp + vec2(e, 0.0), TIME * velocidade)
		- pele(uvp - vec2(e, 0.0), TIME * velocidade);
	float gy = pele(uvp + vec2(0.0, e), TIME * velocidade)
		- pele(uvp - vec2(0.0, e), TIME * velocidade);
	float forca = ondulacao * mix(0.35, 1.0, grossura);
	NORMAL_MAP = normalize(vec3(-gx * forca, -gy * forca, 0.12)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;

	ALBEDO = cor;
	ROUGHNESS = mix(0.42, 0.19, grossura) - beira * 0.03;
	METALLIC = 0.0;
	SPECULAR = 0.62;
	ALPHA = mascara * mix(cor_fina.a, cor_funda.a, grossura);
}
