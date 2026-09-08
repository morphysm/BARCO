#!/usr/bin/env bash
# Prova as migracoes contra um Postgres a serio, sem Supabase e sem conta
# nenhuma. Precisa de docker.
#
#     server/prova/correr.sh
#
# Levanta um Postgres descartavel, cria a meia duzia de coisas que o
# Supabase traz de fabrica (os papeis `anon` e `authenticated`, o esquema
# `auth`), aplica as migracoes por ordem, e exercita o
# `assentar_pagamento` — que e onde o dinheiro se decide.
#
# O que isto NAO prova: o RLS a valer, que precisa dos papeis do Supabase
# a serio, e o webhook contra o Ko-fi. Prova a SQL: que aplica, e que o
# reenvio nao credita duas vezes.
set -euo pipefail

CAIXA=barco_prova_pg
AQUI="$(cd "$(dirname "$0")" && pwd)"

limpar() { docker rm -f "$CAIXA" >/dev/null 2>&1 || true; }
trap limpar EXIT
limpar

docker run --rm -d --name "$CAIXA" -e POSTGRES_PASSWORD=x postgres:16-alpine >/dev/null
for _ in $(seq 1 30); do
    docker exec "$CAIXA" pg_isready -U postgres >/dev/null 2>&1 && break
    sleep 1
done

docker exec "$CAIXA" psql -U postgres -q -c "create database barco" postgres

for f in "$AQUI/00_supabase_falso.sql" "$AQUI/../migrations/"*.sql; do
    docker cp "$f" "$CAIXA:/tmp/$(basename "$f")" >/dev/null
    if docker exec "$CAIXA" psql -U postgres -d barco -v ON_ERROR_STOP=1 -q \
            -f "/tmp/$(basename "$f")"; then
        echo "  ok    $(basename "$f")"
    else
        echo "  FALHA $(basename "$f")"
        exit 1
    fi
done

echo ""
docker cp "$AQUI/assentar_pagamento.sql" "$CAIXA:/tmp/" >/dev/null
docker exec "$CAIXA" psql -U postgres -d barco -v ON_ERROR_STOP=1 \
    -f /tmp/assentar_pagamento.sql
