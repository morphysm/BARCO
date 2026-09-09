#!/usr/bin/env bash
# Prova o webhook a serio: a funcao a correr, o corpo em form-urlencoded,
# o token verificado, o RLS ligado, e a transacao a escrever.
#
#     server/prova/webhook.sh
#
# Corre contra um Supabase LOCAL, em docker. Nao toca no projecto ligado.
#
# Precisa de `npx supabase start` ja a correr.
set -euo pipefail

AQUI="$(cd "$(dirname "$0")" && pwd)"
RAIZ="$(cd "$AQUI/../.." && pwd)"
PAYLOADS="$RAIZ/server/functions/kofi_webhook/payloads"
TOKEN="token-de-prova-nao-e-o-verdadeiro"
PESSOA="11111111-1111-1111-1111-111111111111"

cd "$RAIZ"

# O ambiente da funcao.
#
# O `SUPABASE_SECRET_KEYS` NAO se poe aqui, e nao e por escolha: o CLI
# recusa qualquer variavel comecada por `SUPABASE_` vinda de um
# `--env-file` ("Env name cannot start with SUPABASE_, skipping"). E nao
# e preciso — o proprio runtime injecta-a, tambem localmente, e a sonda
# confirmou-o:
#
#     SUPABASE_SECRET_KEYS: JSON com as chaves: default
#
# So o token do Ko-fi e que e nosso e tem de vir daqui.
ESTADO="$(npx --yes supabase@latest status -o json)"
API="$(echo "$ESTADO" | python3 -c 'import json,sys; print(json.load(sys.stdin)["API_URL"])')"

AMBIENTE_TESTE="$(mktemp /tmp/barco-webhook.XXXXXX)"
cat > "$AMBIENTE_TESTE" <<ENV
KOFI_VERIFICATION_TOKEN=$TOKEN
ENV

echo "== migracoes =="
npx --yes supabase@latest db reset >/dev/null 2>&1
echo "  aplicadas"

echo ""
echo "== semear: uma pessoa, um SKU, um codigo =="
# `docker exec` SEM `-i` nao passa o stdin: o heredoc ia para o vazio e o
# psql saía com 0 sem ter feito nada. Com `set -e` isso nao se notava —
# a prova corria inteira contra uma base vazia e dava tudo "fila", que
# ate parecia certo.
docker exec -i supabase_db_BARCO psql -U postgres -d postgres -q -v ON_ERROR_STOP=1 <<SQL
insert into auth.users (instance_id, id, aud, role, email)
values ('00000000-0000-0000-0000-000000000000', '$PESSOA',
        'authenticated', 'authenticated', 'jo.example@example.com');
update public.atos set kofi_sku = '1a2b3c4d5e' where slug = 'sacrificio';
insert into public.codigos (codigo, user_id, cafes_total)
values ('BAR-7X2K', '$PESSOA', 1);
insert into public.codigo_itens (codigo, ato_slug, quantidade)
values ('BAR-7X2K', 'vela_20min', 1);
SQL
echo "  pessoa jo.example@example.com, SKU 1a2b3c4d5e -> sacrificio, codigo BAR-7X2K"

echo ""
echo "== a servir a funcao =="
npx --yes supabase@latest functions serve kofi_webhook --no-verify-jwt \
    --env-file "$AMBIENTE_TESTE" >/tmp/barco_fn.log 2>&1 &
FN=$!
trap 'kill $FN 2>/dev/null || true' EXIT
for _ in $(seq 1 40); do
    curl -s -o /dev/null "$API/functions/v1/kofi_webhook" 2>/dev/null && break
    sleep 1
done

# `atirar NOME TOKEN DESCRICAO [REMENDO]`
#
# O REMENDO e python que altera o payload antes de o mandar, e cada uso
# esta marcado na descricao. Os payloads em `payloads/` sao os oficiais e
# nao se tocam: por exemplo, a gorjeta oficial traz "Good luck with the
# integration!" na mensagem e nao um codigo — para provar o caminho do
# codigo e preciso la po-lo, e isso tem de se ver.
atirar() {
    local nome="$1" tok="$2" desc="$3" remendo="${4:-}"
    local corpo
    corpo="$(REMENDO="$remendo" python3 -c "
import json, os
p = json.load(open('$PAYLOADS/$nome.json'))
p['verification_token'] = '$tok'
exec(os.environ['REMENDO'])
print(json.dumps(p))
")"
    local codigo
    codigo="$(curl -s -o /dev/null -w '%{http_code}' -X POST \
        "$API/functions/v1/kofi_webhook" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "data=$corpo")"
    printf "  %-46s HTTP %s\n" "$desc" "$codigo"
}

echo ""
echo "== a atirar =="
atirar tip "token-errado" "token errado -> 401"
atirar tip "$TOKEN" "gorjeta oficial, so email -> fila"
atirar tip "$TOKEN" "a MESMA outra vez -> duplicado"
atirar tip "$TOKEN" "gorjeta + codigo na mensagem -> credita" \
    "p['message'] += ' BAR-7X2K'; p['message_id'] = 'com-codigo'; p['amount'] = '2.00'; p['currency'] = 'USD'"
atirar compra "$TOKEN" "compra oficial, 2 artigos -> fila"
atirar compra "$TOKEN" "compra de 1 artigo x1 -> credita" \
    "p['shop_items'] = [p['shop_items'][0]]; p['shop_items'][0]['quantity'] = 1; p['message_id'] = 'um-artigo'; p['amount'] = '14.00'; p['currency'] = 'USD'"
atirar compra "$TOKEN" "o mesmo artigo x5 -> fila" \
    "i = dict(p['shop_items'][0]); i['quantity'] = 5; p['shop_items'] = [i]; p['message_id'] = 'cinco'"
atirar subscricao_tier "$TOKEN" "renovacao sem mensagem -> fila"

echo ""
echo "== o que ficou nas tabelas =="
docker exec supabase_db_BARCO psql -U postgres -d postgres -x -c "
select
  (select count(*) from public.pagamentos)    as pagamentos,
  (select count(*) from public.creditos)      as creditos,
  (select count(*) from public.reconciliacao) as na_fila,
  (select count(*) from public.codigos where usado_em is not null) as codigos_gastos;
"
docker exec supabase_db_BARCO psql -U postgres -d postgres -c "
select left(kofi_message_id, 8) as msg, amount, matched_by,
       user_id is not null as tem_dono
  from public.pagamentos order by created_at;
"
