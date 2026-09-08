# BARCO

Aplicativo ritual. Vende-se o ato, nunca o resultado.

Antes de mexer em qualquer coisa:

| Arquivo | O que e |
|---|---|
| `AGENTS.md` | Invariantes. Nao sao preferencias. |
| `GLOSSARY.md` | Vocabulario de dominio. Nunca traduzido. |
| `SPEC.md` | Contrato de implementacao. |
| `CONTENT_pt.md` | Texto autoral. Nao gerar, nao traduzir, nao reescrever. |
| `GDD barco.md` | Racional de design (pt). |

## Estado

Fatia vertical em andamento (SPEC.md §12): a `irmandade` da
`calunga_pequena` — `Exu Aranha`, `Rosa Negra`, `Exu Caveira`.

- [x] `ponto_riscado` — captura e `firmeza`
- [x] reconhecimento de `assinatura` dentro de uma `irmandade`
- [x] tres assinaturas fieis: `Exu Caveira` (143 tracos), `Rosa Negra`
      (58), `Exu Aranha` (72)
- [x] `abandonado` vs traco instintivo, e a inversao sob `hora_asmodeica`
- [ ] `assentamento`
- [ ] vela e `permanencia`
- [ ] `caderno`

Sem pagamento e sem servidor nesta fatia, por desenho.

Cada entidade tem a sua `assinatura`: o `ponto_riscado` inteiro dela, como
foi desenhado. **O ponto e uma copia fiel do desenho** — nada e resumido
nem reinventado. E o que se pratica, e e por isso que existe o guia.
Assinaturas nao partilham geometria e nao se compoem umas com as outras.
O app nao oferece lista: reconhece quem assinou, ou ninguem.

`Exu Caveira` e o rei do cemiterio. `Rosa Negra` esta ao lado dele.
`Exu Aranha` e a teia que tece e tem presenca nas duas.

Um ponto riscado e **abandonado** nao vale nada, a qualquer hora. Um ponto
riscado inteiro que nao pousa em assinatura nenhuma e o traco
**instintivo** — e dentro da `hora_asmodeica` vale muito. Sao estados
distintos (SPEC.md §5.3).

## Rodar

```sh
godot --path client                     # abre a PORTA, e dai o RISCO
godot --path client --script res://tools/teste_risco.gd --headless   # testes

# a tela da Porta: a pausa antes da ultima linha, o menu, a franja de cor
godot --path client --script res://tools/prova_porta_tela.gd
```

A janela abre nos 1600x1000 do proprio viewport, sem escala. Era 1280x800
por `window_*_override`, ou seja 0.8, e a 0.8 a letra da Porta — que e de
matriz de pontos — perde os cantos e ganha orla. Passar-lhe `--resolution`
volta a escalar: para conferir a tela como ela e, nao se passa.

A **Porta** e a primeira coisa que o app mostra depois de instalado
(SPEC.md §1.1). Atravessa-se uma vez: fica gravada em
`user://passagem.json`, e quem entrou nao volta a ser perguntado. Para a
ver outra vez, `Passagem.esquecer()` — que apaga o progresso todo.

`guia` liga o traçado guiado de primeiro contato (SPEC.md §4.3): gratuito,
sem nota, sem limite. Desligado, o `ponto` passa a ser avaliado.

## Do sigilo ao `ponto`

O `ponto_riscado` de `Exu Aranha` vem do sigilo autoral de A.C. O caminho
tem tres passos, e os `.tres` sao dados, nao codigo:

```sh
# 1. vetoriza o desenho -> capturas/<nome>/
python3 tools/extrair_sigilo.py "references/exuaranha-sigil-vowel-board.png" --saida capturas/aranha
python3 tools/extrair_sigilo.py "references/rosa_negra_ponto_riscado_cemitério.png" --saida capturas/rosa
python3 tools/extrair_sigilo.py "references/ponto_Exu Caveira.png" --saida capturas/caveira

# 2. importa para resources/ e monta a irmandade
godot --path client --headless --script res://tools/importar_sigilos.gd

# 3. confere na tela
godot --path client --script res://tools/capturar_risco.gd --resolution 640x1000
```

`capturas/<nome>/sobreposicao.png` mostra o que foi vetorizado, uma cor por
traco — e por ali que se ve se algum traco do desenho se perdeu.

O vetorizador mede. **A ordem dos tracos e doutrina**, e por enquanto sai
numa ordem de leitura, de cima para baixo, a corrigir a mao.

## O `assentamento`

O arranjo da nganga esta em `client/scenes/assentamento.tscn` e ajusta-se
no editor: cada peca e um no, arrasta-se e grava-se.

```sh
# acrescentar ou mudar UMA peca de sitio, sem tocar no resto
godot --headless --path client --script res://tools/por_peca.gd -- MODELO x y z tamanho giro [vela]

# ver um modelo sozinho e grande, para conferir o que a decimacao lhe fez
godot --path client --script res://tools/ver_modelo.gd --resolution 700x700 -- black_rose
```

### O fundamento esta travado

A nganga esta montada. `client/scenes/assentamento.tscn` e autoral: e o
vaso que faz este `assentamento` ser o daquela entidade, e nao se mexe por
engano.

```sh
python3 tools/verificar_fundamento.py             # confere que nao mudou
python3 tools/verificar_fundamento.py --regravar  # aceitar um estado novo
```

As tres ferramentas que escrevem na cena recusam-se a correr:
`por_peca.gd` e `marcar_grupo.gd` pedem `-- --destravar`,
`gerar_cena_assentamento.gd` pede `-- --refazer` e reescreve tudo de raiz.

### Levar o `assentamento` para outro sitio

`client/scenes/assentamento_cenario.tscn` e a mesma nganga sem ritual
nenhum: as 52 pecas onde estao, as velas a dar luz, o chao e o ambiente
escuro. Nao tem `depor`, nem `pedidos` a arder, nem menu, nem registo em
disco — e cenario, para instanciar noutra cena ou noutro jogo.

So depende de `client/resources/modelos/` e, se a gravura for ligada, de
`client/shaders/gravura.gdshader`. A camara vem com a mesma pose e com
`current` ligado: instanciando-o dentro de outra cena, desliga-se.

Ha tambem um executavel so do cenario, em `build/assentamento/` (fora do
git, que sao 165 MB): binario, atalho `.desktop`, `.mp4` e `.gif`. O
preset chama-se `Assentamento (Linux)` e liga a funcionalidade `cenario`,
que em `project.godot` troca a cena de arranque e o tamanho da janela.
`export_presets.cfg` esta no `.gitignore`, entao o preset e local.

```sh
# refaz os quatro: quadros, mp4, gif e executavel (precisa de display)
# grava a cena no editor ANTES — isto le o disco, nao o editor
tools/refazer_cenario.sh

# so o executavel
godot --headless --path client --export-release "Assentamento (Linux)"
```

`filmar_assentamento.gd` sozinho **nao refaz o video**: o Godot nao
escreve video, so grava PNG em `capturas/filme/`. Quem junta e o ffmpeg,
e o executavel e outra exportacao — por isso e que o script existe.

O arranjo mora na cena oficial e desce para a copia, nunca ao contrario:

```sh
godot --headless --path client --script res://tools/gerar_cenario.gd
```

A copia nao guarda nada de seu — o que se acrescentar so a ela perde-se
na proxima passagem. Acrescentar uma peca faz-se no editor, ou por
`por_peca.gd`, que escolhe a cena:

```sh
# uma peca nova so no cenario — nao pede --destravar, nao e fundamento
godot --headless --path client --script res://tools/por_peca.gd -- \
      --cena cenario MODELO x y z tamanho giro [vela]

# uma SEGUNDA copia de um modelo que ja la esta precisa de nome proprio
godot --headless --path client --script res://tools/por_peca.gd -- \
      --cena cenario --nome black_rose8 black_rose -0.13 0 0.24 0.11 40
```

Uma imagem PNG entra pelo `por_imagem.gd`, e sao dois passos: o Godot so
ve o que importou.

```sh
cp a_minha.png client/resources/imagens/
godot --headless --path client --import

godot --headless --path client --script res://tools/por_imagem.gd -- \
      --cena cenario resources/imagens/a_minha.png 0.12 0 -0.16 0.20 90
#                                                   x   y   z  altura giro
```

A largura sai da propria imagem, para nao a esticar. `--deitada` pousa-a
no chao, `--inclinar G` tomba-a para tras, `--acesa` faz com que nao
dependa da luz das velas, `--tirar` tira-a. O alfa e respeitado: um PNG
com fundo branco fica um retangulo branco no escuro.

O que se acrescenta por cima do fundamento sao `depositos` — `depor()` no
script do `assentamento` — e esses nunca tocam nesta cena. Sao de quem os
depoe, ficam onde foram postos, e nao se tiram (GDD §2).

O passo 1 mede. O passo 2 reduz. Nenhum dos dois decide **a ordem dos
tracos** nem **onde o `ponto` se ramifica entre as `faces`** — isso e
doutrina, e esta escrito a mao em `tools/gerar_ponto_aranha.gd`.

## Creditos

O tipo de letra da **Porta** e `PxPlus IBM VGA8`, do *Ultimate Oldschool
PC Font Pack* de VileR (int10h.org), sob CC BY-SA 4.0. A licenca esta em
`client/resources/fonts/PxPlus_IBM_VGA8-LICENCA.txt` e a atribuicao esta
**dentro do app**, ao fundo da propria tela da Porta:

> IBM PC font courtesy of int10h.org / VileR, CC BY-SA 4.0

Nao e um agradecimento, e uma condicao da licenca: sai do ecra so quando
a letra sair com ela.

Corpo do texto do `assentamento`: `DejaVu Sans Mono`, licenca em
`client/resources/fonts/DejaVu-LICENCA.txt`.

---
CC BY-NC-SA — A.C., Norrland XXVI / Morphysm
