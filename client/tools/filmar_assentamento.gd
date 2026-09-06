## Filma o `assentamento_cenario` para um vídeo. Precisa de display.
##
## Grava PNG quadro a quadro em `capturas/filme/` — o Godot não escreve
## vídeo, quem junta é o ffmpeg.
##
##   godot --path client --script res://tools/filmar_assentamento.gd \
##         --resolution 720x900 --fixed-fps 30
##
##   ffmpeg -y -framerate 30 -i capturas/filme/%04d.png \
##          -c:v libx264 -pix_fmt yuv420p -crf 18 build/assentamento/assentamento.mp4
##
## `--fixed-fps 30` não é decorativo: sem isso o delta é o do relógio e o
## bruxuleio das velas sai a velocidade errada no ficheiro.
extends SceneTree

## Quadros deitados fora no início, enquanto as texturas ainda entram.
const AQUECER := 20
## 12 segundos a 30.
const QUADROS := 360

var q := 0

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://../capturas/filme")
	root.add_child(load("res://scenes/assentamento_cenario.tscn").instantiate())

func _process(_d: float) -> bool:
	q += 1
	if q <= AQUECER:
		return false
	var i := q - AQUECER
	root.get_texture().get_image().save_png("res://../capturas/filme/%04d.png" % i)
	if i >= QUADROS:
		print("filmados %d quadros em capturas/filme/" % QUADROS)
		return true
	return false
