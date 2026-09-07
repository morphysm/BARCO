## Um `pedido`: papel escrito, posto no caldeirao, a arder durante sete
## dias.
##
## Sete dias reais, 168 horas, como a vela de sete dias (SPEC.md §8.1,
## GDD §5.3). Nao acelera, nao pausa, nao se reacende, e corre com o app
## fechado.
##
## AS PALAVRAS NUNCA SAEM DAQUI. Ficam em `user://`, no aparelho de quem
## as escreveu, e desaparecem quando o papel acaba de arder. Nao vao para
## servidor nenhum e NAO vao para o `caderno`: o `caderno` regista que
## houve um `pedido` e a que horas, nunca o que dizia. Guardar copia do
## que se queimou contradiz o gesto — e o que se guarda tambem se pede em
## tribunal (SPEC.md §2: o operador esta na Suecia, GDPR aplica-se).
class_name Pedido
extends RefCounted

## 168 horas.
const DURACAO := 7 * 24 * 60 * 60.0

## Onde os `pedidos` ficam. As palavras nunca saem do aparelho.
##
## Nao e `const` para as provas poderem apontar para outro sitio. Uma
## prova que escreva aqui deixa `pedidos` falsos no tridente de quem esta
## a usar o app — e a arder sete dias reais. Ja aconteceu.
static var REGISTO := "user://pedidos.json"

var texto: String = ""
## Unix time em que foi posto no caldeirao.
var aceso_em: float = 0.0
## Encurta a queima. So para banca — o valor de verdade e DURACAO.
var duracao: float = DURACAO


## Quanto ja ardeu, de 0.0 (inteiro) a 1.0 (cinza).
func consumido(agora := 0.0) -> float:
	if duracao <= 0.0:
		return 1.0
	var t: float = (agora if agora > 0.0 else Time.get_unix_time_from_system())
	return clampf((t - aceso_em) / duracao, 0.0, 1.0)


func acabou(agora := 0.0) -> bool:
	return consumido(agora) >= 1.0


func para_dicionario() -> Dictionary:
	return {"texto": texto, "aceso_em": aceso_em, "duracao": duracao}


static func de_dicionario(d: Dictionary) -> Pedido:
	var p := Pedido.new()
	p.texto = str(d.get("texto", ""))
	p.aceso_em = float(d.get("aceso_em", 0.0))
	p.duracao = float(d.get("duracao", DURACAO))
	return p


## Le os pedidos do aparelho, deitando fora os que ja acabaram de arder.
static func ler() -> Array[Pedido]:
	var saida: Array[Pedido] = []
	if not FileAccess.file_exists(REGISTO):
		return saida
	var f := FileAccess.open(REGISTO, FileAccess.READ)
	var dados = JSON.parse_string(f.get_as_text())
	f.close()
	if not dados is Array:
		return saida
	for d in dados:
		var p := Pedido.de_dicionario(d)
		if not p.acabou():
			saida.append(p)
	return saida


static func guardar(pedidos: Array[Pedido]) -> void:
	var lista: Array = []
	for p in pedidos:
		if not p.acabou():
			lista.append(p.para_dicionario())
	var f := FileAccess.open(REGISTO, FileAccess.WRITE)
	f.store_string(JSON.stringify(lista))
	f.close()
