# server

Supabase. Postgres com RLS, Edge Functions em Deno.

Nada disto esta ligado a uma conta ainda. Ver **O que falta** ao fundo.

## Provar sem conta nenhuma

Tres degraus, do mais barato ao mais completo. Nenhum toca no projecto
alojado.

```sh
# 1. o TypeScript: cascata, traducao dos payloads, leitura das chaves
docker run --rm -v "$PWD":/w -w /w denoland/deno:latest \
    deno test --allow-read --allow-net --allow-env server/functions/

# 2. a SQL: aplica as migracoes a um Postgres descartavel e exercita
#    o `assentar_pagamento` (precisa de docker)
server/prova/correr.sh

# 3. o webhook a serio, contra um Supabase local inteiro
npx supabase start
server/prova/webhook.sh
```

O terceiro e o que prova o que os outros nao alcancam: a Edge Function a
correr, o corpo em `form-urlencoded` a ser desembrulhado, o token a ser
verificado, e a transacao a escrever numa base com RLS ligado. Atira os
payloads oficiais e mostra o que ficou nas tabelas.

### O `supabase/` e o `server/`

O SPEC.md §2 poe o servidor em `server/`. O CLI do Supabase so olha para
`supabase/migrations` e `supabase/functions`. Os dois sao symlinks para
`server/`, e e o `server/` que manda.

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
  kofi_webhook/kofi.ts        a traducao do payload. NOMES POR CONFIRMAR
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

1. **Um payload de um pagamento a serio.** Os quatro exemplos que a
   documentacao do Ko-fi publica estao em
   `kofi_webhook/payloads/` e as provas correm contra eles: os nomes, os
   tipos e a forma do `shop_items` batem todos certo. O que falta e ver
   um payload da conta a serio — exemplos de documentacao nao sao
   producao, e ha registo de que o proprio botao de teste do Ko-fi manda
   payloads errados nalguns casos.

   Quando aparecer: substituir o ficheiro em `payloads/`, **com o token
   trocado por xxx**, e correr as provas. Sao elas que dizem se os nomes
   ainda batem certo.

2. **Criar os artigos na loja do Ko-fi** e escrever o `kofi_sku` de cada
   um na tabela `atos`. Sem isso o degrau do SKU nao existe e tudo
   depende do codigo colado na mensagem.

3. **A vista de administracao da fila** (§10.4: "a first-class feature
   with a small admin view, not a TODO"). A tabela `reconciliacao` existe
   e enche-se sozinha; falta por onde a resolver.

   Quando a escreveres: creditar e um `insert` em `creditos` com o
   `source_payment_id` do pagamento da fila, e a restricao
   `creditos_um_por_pagamento` trata de impedir o segundo clique. Nao lhe
   ponhas uma verificacao a mao por cima nem a contornes.

4. **O lado do cliente**: pedir um codigo, mostra-lo, abrir o link do
   Ko-fi, e esperar pelo credito.
