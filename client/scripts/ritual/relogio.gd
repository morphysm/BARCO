## O tempo do app. Nao ha servidor: manda o relogio do computador, na hora
## local de quem o usa (a zona geografica que o sistema tem configurada).
##
## Quem mudar o relogio do aparelho muda o tempo do app. E aceite: sem
## servidor nao ha outra fonte de hora.
class_name Relogio
extends RefCounted

## A `hora_asmodeica`: 00:00–04:00 na hora local (SPEC.md §6.2).
const INICIO_ASMODEICA := 0
const FIM_ASMODEICA := 4


## Segundos desde 1970. Para duracoes (a queima de um `pedido`).
static func agora() -> float:
	return Time.get_unix_time_from_system()


## A hora local, 0–23.
static func hora_local() -> int:
	return int(Time.get_datetime_dict_from_system(false)["hour"])


## Esta aberta a `hora_asmodeica`? Nunca se anuncia na UI.
static func hora_asmodeica(hora: int = -1) -> bool:
	var h := hora_local() if hora < 0 else hora
	return h >= INICIO_ASMODEICA and h < FIM_ASMODEICA
