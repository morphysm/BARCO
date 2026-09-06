## Uma entidade. SPEC.md §3.1.
##
## Conteudo e dado, nao codigo: acrescentar uma entidade nunca deve exigir
## recompilar (AGENTS.md).
##
## `coroa` guarda apenas as tres coroas territoriais. `asmodeu` NAO e campo
## de entidade — e estado de hora (SPEC.md §6.2).
class_name Entidade
extends Resource

@export var slug: String = ""
@export var nome: String = ""

## lucifer | belzebu | astaroth
@export var coroa: String = ""
@export var reino: String = ""

## 1 normalmente; 2 para entidade de duas faces.
@export var faces: Array[Face] = []

## A `assinatura` desta entidade: o `ponto_riscado` inteiro, como foi
## desenhado. Nao se compoe com o de mais ninguem.
@export var ponto_riscado: PontoData
@export var ponto_cantado: AudioStream
@export var letra: String = ""
@export var cores: PackedColorArray = PackedColorArray()

## 0=domingo .. 6=sabado
@export var dias_semana: Array[int] = []

## 0-23, -1 = sem restricao
@export var hora_minima: int = -1

@export var animal_tradicional: String = ""
@export var oferendas_aceitas: Array[String] = []
@export var dominio: Array[String] = []

## Vem de CONTENT.pt.md. NAO gerar, NAO traduzir, NAO reescrever.
@export_multiline var texto_apresentacao: String = ""

func tem_duas_faces() -> bool:
	return faces.size() == 2

func face_por_slug(s: String) -> Face:
	for f in faces:
		if f != null and f.slug == s:
			return f
	return null
