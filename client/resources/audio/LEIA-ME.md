# audio

`passagem_provisorio.ogg` e um zumbido gerado, **provisorio**. Serve para
se sentir o compasso dos 16 segundos do eclipse: cresce ate a totalidade
e cai depois. Nao e som de autor e nao e para ficar.

Para o substituir: poe o teu ficheiro aqui, importa, e troca o `som` no
inspetor de `scenes/eclipse.tscn`. Se a duracao mudar, muda tambem
`duracao` no mesmo sitio — as duas andam juntas.

Sem `som` nenhum a passagem corre em silencio. Melhor calada do que com
o som errado.

## fornalha

`fornalha_provisorio.ogg` — o mesmo caso: gerado, provisorio, so para se
sentir o compasso. A musica da fornalha e de A.C. e entra em
`scenes/fornalha.tscn`, no campo `musica`.

A cena espera pelo FIM da musica para abrir a iris. Trocar o ficheiro
chega; nao ha duracao escrita a mao em lado nenhum.

## sangue

`banho_de_sangue.ogg` — o balde a cair no chao do `assentamento`. Este e
de autor, nao e provisorio.

Toca UMA vez, no momento em que se depoe. Ao recarregar o
`assentamento`, o sangue reaparece no chao em silencio: o balde foi
atirado uma vez e ja foi, e um deposito e um registo, nao um gesto.

Para o trocar: poe o teu ficheiro aqui com o mesmo nome, ou muda
`som_do_sangue` no `assentamento_screen.gd`. Nao esta na cena de
proposito — `scenes/assentamento.tscn` e o fundamento travado
(`tools/verificar_fundamento.py`) e nao se mexe por causa de um som.

## porta

`INTRO_Solo de Atabaque.ogg` — o solo por baixo da Porta, a primeira tela
que o app mostra. De autor.

Toca UMA vez, do principio, e acaba: sao 50 segundos com um fim a serio
(o som cai aos 47 e o resto e silencio), nao material de ciclo. Quem
demorar mais do que isso a decidir fica em silencio com a pergunta a
frente, e isso e justo.

Entra a `-6 dB` de propósito — a gravacao vem a nivel normal e sem
atenuacao ficava a frente do texto em vez de por baixo dele. O valor esta
em `volume_do_atabaque`, no inspetor da tela, e muda-se sem tocar em
codigo.

Quem ja atravessou a Porta nao ve esta tela e nao ouve isto.
