# server

> Estado actual do checkout web, provas alojadas e passos de publicacao:
> [KO_FI_LAUNCH.md](KO_FI_LAUNCH.md). Este ficheiro descreve a arquitectura
> e as provas locais; o outro regista o estado observado em producao.

Supabase. Postgres com RLS, Edge Functions em Deno.

O projecto alojado ja esta ligado e migrado. Ver **O que falta** ao fundo
antes de publicar uma nova versao.

## Provar sem conta nenhuma

Tres degraus, do mais barato ao mais completo. Nenhum toca no projecto
alojado.

```sh
# 1. o TypeScript: cascata, traducao dos payloads, leitura das chaves
docker run --rm -v "$PWD":/w -w /w denoland/deno:latest \
    deno test --allow-read --allow-net --allow-env server/functions/

# 2. a SQL: aplica as migracoes a um Postgres descartavel, exercita o
#    `assentar_pagamento`, e prova o RLS com papel e sessao (precisa de
#    docker)
server/prova/correr.sh

# 3. o webhook a serio, contra um Supabase local inteiro
npx supabase start
server/prova/webhook.sh

# 4. a cadeia inteira: cesto -> codigo -> pagamento -> credito -> gasto
server/prova/cadeia.sh
```

A quarta e a unica que junta as duas metades. Ate ela, provava-se cada
uma de seu lado: o cliente pedia codigos, o servidor creditava
pagamentos, e ninguem tinha visto um codigo emitido pelo app ser pago e
voltar como credito gastavel.

Nao se faz um pagamento real contra producao com a conta do criador porque o
**Ko-fi nao deixa pagar a si proprio**. Na prova local, o pagamento e
simulado: um POST ao webhook com o codigo que o app emitiu. O Ko-fi tambem
permite enviar um pagamento de teste na pagina de Webhooks. Nenhuma das duas
provas substitui uma transaccao real feita por outra pessoa.

O terceiro e o que prova o que os outros nao alcancam: a Edge Function a
correr, o corpo em `form-urlencoded` a ser desembrulhado, o token a ser
verificado, e a transacao a escrever numa base com RLS ligado. Atira os
payloads oficiais e mostra o que ficou nas tabelas.

### O RLS

`server/prova/rls.sql` assume o papel `authenticated` e finge o `sub` de
uma pessoa, como o Supabase faz. E o unico sitio onde as politicas sao
mesmo lidas: o resto da prova corre como superutilizador, e esse passa
por cima do RLS por completo.

Duas coisas que so se aprendem escrevendo isto, e que ficam escritas no
ficheiro para nao se repetirem:

  - sem os GRANTs que o Supabase da de fabrica (`99_permissoes.sql`,
    aplicado DEPOIS das migracoes), a recusa vinha do privilegio em falta
    e nao da politica — a prova dizia que estava tudo bem sem a politica
    ter sido consultada;
  - com RLS, uma escrita que nao encontra linha visivel NAO rebenta:
    afecta zero linhas em silencio. Conta-se o efeito, nao a excepcao.

### O `supabase/` e o `server/`

O SPEC.md §2 poe o servidor em `server/`. O CLI do Supabase so olha para
`supabase/migrations` e `supabase/functions`. Os dois sao symlinks para
`server/`, e e o `server/` que manda.

### O codigo mal copiado

O codigo nao chega aqui copiado por uma maquina: chega escrito a mao na
caixa de mensagem do Ko-fi, por quem o leu de outro ecra. A
`_shared/cascata.ts` conta com isso — separador frouxo (`BAR 7X2K`,
`BAR_7X2K`, o travessao do corrector) e `I` lido como `1`, `O` como `0`.

A segunda metade so e segura porque o gerador nunca emite `I` nem `O`.
Sao dois ficheiros que nao se conhecem a concordar, e por isso ha uma
prova a segurar o acordo: `prova/alfabeto.sql`. Se alguem devolver o `I`
ao alfabeto, ela rebenta — em vez de os pagamentos comecarem a cair na
fila manual sem explicacao.

### A sonda

`functions/sonda/` responde com os NOMES das variaveis `SUPABASE_*` e o
feitio do que trazem, nunca os valores. Serviu para confirmar, em vez de
supor, que o runtime injecta mesmo o `SUPABASE_SECRET_KEYS` e que a
entrada e `default`. Vale a pena voltar a corre-la depois do primeiro
`functions deploy`. **Nao a deixar acessivel sem autenticacao num
projecto a serio.**

## O que ha

```
migrations/
  ..._pagamentos.sql          atos, codigos, pagamentos, creditos, reconciliacao
  ..._rls.sql                 quem ve o que. As tabelas de dinheiro nao se leem
  ..._assentar_pagamento.sql  a escrita, tudo ou nada, numa transacao
  ..._pessoa_por_email.sql    email do pagador -> pessoa, porta estreita
functions/
  _shared/pagamento.ts        o tipo `Pagamento`. Nao sabe o que e o Ko-fi (§10.5)
  _shared/cascata.ts          de quem e, e o que paga. Nunca adivinha
  _shared/ambiente.ts         as chaves, lidas com verificacao
  kofi_webhook/kofi.ts        a traducao do payload do Ko-fi
  kofi_webhook/index.ts       o handler
```

## As chaves

| Variavel | Quem a poe |
|---|---|
| `SUPABASE_URL` | o Supabase, sozinho |
| `SUPABASE_SECRET_KEYS` | o Supabase, sozinho. Dicionario JSON; usa-se a entrada `default`, que passa por cima do RLS |
| `KOFI_VERIFICATION_TOKEN` | **tu**, a mao, nas definicoes da funcao |

O token do Ko-fi esta em `ko-fi.com/manage/webhooks`. Nao entra no
repositorio, nao entra em ficheiro nenhum, nao se cola em conversa
nenhuma.

## O que falta, e nada disto e detalhe

1. **Um pagamento real de ponta a ponta.** Outra pessoa tem de pagar o valor
   exacto com um codigo desta versao na mensagem. Confirmar HTTP 200,
   creditos nomeados, estado recebido, deposito, recarregamento do browser e
   repeticao segura da entrega e da operacao de deposito.

   Uma inspeccao alojada encontrou duas linhas por resolver. A origem nao foi
   estabelecida e os payloads nao foram lidos; nao contam como prova de um
   pagamento real. Examina-las antes da publicacao sem adivinhar, creditar ou
   marcar como resolvidas.

2. **A vista de administracao da fila** (§10.4: "a first-class feature
   with a small admin view, not a TODO"). A tabela `reconciliacao` existe
   e enche-se sozinha; falta por onde a resolver.

   Quando a escreveres: creditar e um `insert` em `creditos` com o
   `source_payment_id` do pagamento da fila, e a restricao
   `creditos_um_por_pagamento` trata de impedir o segundo clique. Nao lhe
   ponhas uma verificacao a mao por cima nem a contornes.

3. **Confirmar a recuperacao de creditos comprados.** O login por codigo de
   email e a ligacao da identidade ja existem e foram provados em dois
   browsers. Ainda falta confirmar, com o pagamento de ponta a ponta, que a
   mesma pessoa recupera os creditos comprados depois de limpar a sessao.

4. **Conferir a versao candidata no iframe.** A copia do codigo ja foi
   confirmada pela operadora. A versao mais recente ainda precisa de prova de
   disposicao, scroll e gesto no desktop e num viewport estreito da pagina
   restrita do itch.io.

O caminho actual usa apoio unico com valor exacto e codigo na mensagem. Os
artigos da loja e o degrau por `kofi_sku` nao fazem parte desta publicacao.
