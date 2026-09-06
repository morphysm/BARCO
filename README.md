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
godot --path client                     # abre a tela de RISCO
godot --path client --script res://tools/teste_risco.gd --headless   # testes
```

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

O passo 1 mede. O passo 2 reduz. Nenhum dos dois decide **a ordem dos
tracos** nem **onde o `ponto` se ramifica entre as `faces`** — isso e
doutrina, e esta escrito a mao em `tools/gerar_ponto_aranha.gd`.

---
CC BY-NC-SA — A.C., Norrland XXVI / Morphysm
