# SESSION_NOTES

## 2026-09-22 — Barco sem servidor (Supabase desactivado)

Decisoes do dono:
- Sem pagamentos. Todas as `oferendas` gratis, guardadas no aparelho.
- O tempo e o relogio do computador, na hora local (zona geografica do PC).
  Mudar o relogio muda o tempo do app — aceite.

### Feito
- `oferendas/*.tres`: `cafes = 0` (era 1; `sangue` 7).
- `assentamento_screen.gd`: sem botao `comprar`, sem precos, sem balcao,
  sem verificacao de credito, sem sincronizar com servidor. Os `depositos`
  gravam-se so em `user://depositos.json`. Botao "escrever um pedido" sem
  "· grátis" (pedido do dono).
- Apagado (fica no historico git ate `9eeaa6c`): `conta.gd`, `creditos.gd`,
  `comprar.gd`, `conta_compras.gd`, `codigo_clipboard.gd`, `servidor.gd`,
  `resources/servidor/supabase.tres`, provas de pagamento em
  `client/tools/`, `server/`, `supabase/`, `tools/verificar_precos.py`,
  `tools/prova_clipboard.cjs`, `tools/prova_reconciliacao_admin.cjs`.
- `project.godot`: sem autoloads `Conta`/`Creditos`.
- `tools/prova_layout_oferendas.gd`: sem as verificacoes do balcao.
- Novo `client/scripts/ritual/relogio.gd` (`Relogio`): hora local e
  `hora_asmodeica` (00:00–04:00 local). `risco_screen.gd` le-a ao abrir.
- `passagem.gd`: o caminho (Porta, `pontos`, eclipse, `fornalha`) repete-se
  a cada abertura — progresso so na memoria (`REGISTO = ""`). Pedido do
  dono. O `user://passagem.json` antigo fica no disco, ignorado.
- `fornalha_screen.gd`: NAO fecha o jogo (ja fechava no desktop); na web,
  onde `quit()` nao funciona, ecra preto, sem som, pausa e `window.close()`.
- Builds para itch.io: `build/itch-20260922/barco-{linux,windows}.zip`
  (release, Godot 4.7.2). Linux arrancou sem erros; Windows nao testado.
- `AGENTS.md` (Money/Time/Payments), `SPEC.md` §6.2, `README.md`
  actualizados.

### Versao inglesa (2026-09-22, depois do commit 95aeeb0)
- `client/resources/traducao/textos.csv` (keys = texto pt, colunas pt/en):
  39 linhas. Idioma pelo sistema: pt -> portugues, resto -> ingles
  (`locale/fallback="en"`). Nomes de entidades e "Calunga Pequena" ficam
  em portugues. Os `.translation` geram-se ao importar (ignorados no git).
- `tr()` explicito onde o texto e composto ou animado: `porta_screen.gd`
  (RITUAL, opcoes, arranque), `fornalha_screen.gd` (boas-vindas),
  `risco_screen.gd` (formatos). O resto traduz-se sozinho (Controls).
- Pergunta da fornalha em ingles: "Do you renounce your past / and every
  lie you have served?" (escolha do dono).
- Builds: `build/itch-20260922-en/barco-{linux,windows}.zip`.
- `CONTENT.pt.md` nao traduzido (nao aparece no app).

### Verificado
- Headless: todas as cenas carregam sem erro de script; `teste_risco.gd`
  passa; `prova_layout_oferendas.tscn` 0 falhas; prova ad hoc: 10
  `oferendas`, sem preco, largar grava no ficheiro local; `Relogio` certo
  nas 24 horas.
- O app abre numa janela sem erros (fora do sandbox — dentro dele nao ha
  acesso ao ecra nem a `user://`).

### Falhas / notas
- Dentro do sandbox do Claude Code o Godot nao abre janela (X11 bloqueado)
  e nao grava em `user://`. Correr fora do sandbox.
- `pkill -f` com o comando do godot matou a propria shell; nao usar.

### Por resolver
- `_hora_asmodeica` em `risco_screen.gd` e lida mas ninguem a usa: o risco
  nao passa por `RiscoScoring.avaliar`. Ja era assim antes.
- `SPEC.md` ainda descreve servidor/Ko-fi noutras seccoes (§3, §7, §10).
- `project.godot` `config/description` diz "Vende-se o ato..." — texto
  autoral, nao mexido.
- Campo `cafes` em `oferenda.gd` fica, sem uso.
- `AGENTS.md` ainda fala de apagar a conta (GDPR); ja nao ha contas.
- Ficheiros NAO seguidos pelo git que ficaram no disco:
  `server/functions/.env` (segredos), `supabase/.temp/` (inclui
  `start-secrets`, `pooler-url`), pasta vazia `server/functions/timers`.
  Nao apagados. O dono decide; se tinham chaves, revogar no Supabase.
- Ficheiros de shell (`.bashrc`, `.profile`, ...) apareceram na raiz, nao
  seguidos; provavelmente do sandbox. Nao commitar.
- Nao testado: export web.
- Commitado sem `client/scenes/fornalha.tscn` (mudanca do editor Godot,
  inclui `visible = false` no remate da Bandeira3 — o dono decide) e sem
  `.serena/project.yml`. Os zips foram feitos COM a mudanca da fornalha.

### Proximo passo
Dono decide sobre `fornalha.tscn`. Testar o zip de Windows numa maquina
Windows. Limpar os segredos antigos do Supabase no disco.
