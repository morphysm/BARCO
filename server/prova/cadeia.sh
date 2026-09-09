#!/usr/bin/env bash
# A cadeia inteira, do cesto ao credito gasto, contra um Supabase LOCAL.
#
#     npx supabase start
#     server/prova/cadeia.sh
#
# E a unica prova que junta as duas metades. Ate aqui provava-se cada uma
# de seu lado: o cliente pedia codigos, o servidor creditava pagamentos, e
# ninguem tinha visto um codigo emitido pelo app ser pago e voltar como
# credito gastavel.
#
# Nao se faz contra producao porque o Ko-fi nao deixa pagar a si proprio —
# passa pelo PayPal, que o bloqueia. Aqui o pagamento e simulado: um POST
# ao webhook com o token local e o codigo verdadeiro que o app emitiu.
# O que NAO se prova assim e o transporte do Ko-fi nem o pagamento pelo
# processador. Esses ficam para uma transaccao real feita por outra pessoa.
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$RAIZ"
TOKEN="token-de-prova-nao-e-o-verdadeiro"

ESTADO="$(npx --yes supabase@latest status -o json)"
API="$(echo "$ESTADO" | python3 -c 'import json,sys; print(json.load(sys.stdin)["API_URL"])')"
CHAVE="$(echo "$ESTADO" | python3 -c 'import json,sys; print(json.load(sys.stdin)["PUBLISHABLE_KEY"])')"

echo "== base de raiz =="
npx --yes supabase@latest db reset >/dev/null 2>&1
echo "  migracoes aplicadas"

mkdir -p supabase/functions
printf 'KOFI_VERIFICATION_TOKEN=%s\n' "$TOKEN" > supabase/functions/.env
npx --yes supabase@latest functions serve kofi_webhook --no-verify-jwt \
    --env-file supabase/functions/.env >/tmp/barco_cadeia_fn.log 2>&1 &
FN=$!
trap 'kill $FN 2>/dev/null || true' EXIT
for _ in $(seq 1 40); do
    curl -s -o /dev/null "$API/functions/v1/kofi_webhook" 2>/dev/null && break
    sleep 1
done

echo ""
echo "== 1. o app pede um cesto: 2 pimentas + 1 sangue =="
SAIDA="$(godot --path client --headless res://tools/prova_cadeia.tscn \
    -- "$API" "$CHAVE" codigo 2>/dev/null | grep -E '^(ID|CODIGO)=')"
ID="$(echo "$SAIDA" | grep '^ID=' | cut -d= -f2)"
COD="$(echo "$SAIDA" | grep '^CODIGO=' | cut -d= -f2)"
echo "  pessoa: ${ID:0:8}"
echo "  codigo: $COD"
[ -n "$COD" ] || { echo "  sem codigo, nao da para seguir"; exit 1; }

echo ""
echo "  o que ficou selado nesse codigo:"
docker exec -i supabase_db_BARCO psql -U postgres -d postgres -tA -c \
  "select cafes_total from public.codigos where codigo='$COD'" \
  | sed 's/^/    total em cafes: /'
docker exec -i supabase_db_BARCO psql -U postgres -d postgres -tA -F' x' -c \
  "select ato_slug, quantidade from public.codigo_itens where codigo='$COD' order by ato_slug" \
  | sed 's/^/    /'

echo ""
echo "== 2. o Ko-fi entrega o pagamento, com o codigo na mensagem =="
CORPO="$(COD="$COD" TOKEN="$TOKEN" python3 -c "
import json, os
p = json.load(open('server/functions/kofi_webhook/payloads/tip.json'))
p['verification_token'] = os.environ['TOKEN']
p['message_id'] = 'cadeia-' + os.environ['COD']
p['message'] = 'axe! ' + os.environ['COD']
p['amount'] = '18.00'   # 2 pimentas (2 cafes) + 1 sangue (7) = 9 cafes = 18 USD
print(json.dumps(p))
")"
curl -s -o /dev/null -w "  o webhook respondeu HTTP %{http_code}\n" -X POST \
    "$API/functions/v1/kofi_webhook" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "data=$CORPO"

echo ""
echo "  o que o servidor escreveu:"
docker exec -i supabase_db_BARCO psql -U postgres -d postgres -c \
  "select ato_slug, count(*) as quantos from public.creditos
    where user_id = '$ID' and spent_at is null group by ato_slug order by ato_slug;"

echo "== 3. o app ve os creditos e gasta um =="
godot --path client --headless res://tools/prova_cadeia.tscn \
    -- "$API" "$CHAVE" verificar 2>/dev/null | grep -E '^(CREDITOS|GASTOU)' | sed 's/^/  /'

echo ""
echo "== 4. e o codigo nao se gasta duas vezes =="
CORPO2="$(echo "$CORPO" | python3 -c "
import json,sys
p=json.load(sys.stdin); p['message_id']='cadeia-repetido'; print(json.dumps(p))
")"
curl -s -o /dev/null -w "  segunda entrega com o mesmo codigo: HTTP %{http_code}\n" -X POST \
    "$API/functions/v1/kofi_webhook" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "data=$CORPO2"
docker exec -i supabase_db_BARCO psql -U postgres -d postgres -c \
  "select
     (select count(*) from public.creditos where user_id='$ID') as creditos_ao_todo,
     (select count(*) from public.reconciliacao) as na_fila;"
