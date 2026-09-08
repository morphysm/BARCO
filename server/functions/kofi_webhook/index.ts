// O webhook do Ko-fi. SPEC.md §10.2, §10.3; AGENTS.md, Pagamentos.
//
// A ordem importa e e esta:
//
//   1. o token, antes de se tocar em mais nada;
//   2. traduzir o payload para um `Pagamento` (§10.5), sem Ko-fi dai para
//      a frente;
//   3. a cascata decide de quem e e o que paga, sem nunca adivinhar;
//   4. uma transacao so escreve tudo, com a idempotencia agarrada ao
//      `kofi_message_id` UNIQUE;
//   5. 200 — tambem para reenvios. Um duplicado e um sucesso, nao um erro.
//
// O que NAO se faz: responder 200 a um payload que nao se conseguiu ler.
// O Ko-fi reenvia ate receber 200 e nao ha evento de reembolso nem de
// fim de subscricao (§10.3) — o reenvio e a unica rede que ha. Dizer 200
// a uma coisa que nao se percebeu era deitar o pagamento fora em
// silencio. Rebenta-se, e o Ko-fi volta a trazer.

import { createClient } from "jsr:@supabase/supabase-js@2";
import {
    chaveDeAdmin,
    FaltaChave,
    iguaisEmTempoConstante,
    tokenDoKofi,
    url,
} from "../_shared/ambiente.ts";
import { casar, podeCreditar } from "../_shared/cascata.ts";
import type { Registo } from "../_shared/pagamento.ts";
import { corpo, PayloadMau, token, traduzir } from "./kofi.ts";

Deno.serve(async (pedido: Request): Promise<Response> => {
    if (pedido.method !== "POST") {
        return new Response(null, { status: 405 });
    }

    let admin;
    let esperado: string;
    try {
        admin = createClient(url(), chaveDeAdmin());
        esperado = tokenDoKofi();
    } catch (e) {
        // Configuracao em falta. Nao se responde 200: sem chaves nao se
        // creditou nada, e o reenvio do Ko-fi e o que salva o pagamento.
        if (e instanceof FaltaChave) console.error("configuracao:", e.message);
        return new Response(null, { status: 500 });
    }

    let dados: Record<string, unknown>;
    try {
        dados = await corpo(pedido);
    } catch (e) {
        console.error("corpo:", (e as Error).message);
        return new Response(null, { status: 500 });
    }

    // 1. O token primeiro. Recusa calada: quem nao trouxe o token nao
    //    fica a saber porque e que falhou.
    const veio = token(dados);
    if (veio === null || !iguaisEmTempoConstante(veio, esperado)) {
        return new Response(null, { status: 401 });
    }

    // 2. Daqui para baixo ja nao ha Ko-fi, ha um `Pagamento`.
    let pagamento;
    try {
        pagamento = traduzir(dados);
    } catch (e) {
        if (e instanceof PayloadMau) {
            // Um nome de campo que nao bate certo aparece AQUI, alto, e
            // nao adiante em silencio. Ver o cabecalho de `kofi.ts`.
            console.error("payload:", e.message);
        }
        return new Response(null, { status: 500 });
    }

    const registo: Registo = {
        async atoPorSku(sku) {
            const { data } = await admin.from("atos")
                .select("slug").eq("kofi_sku", sku).maybeSingle();
            return data?.slug ?? null;
        },
        async codigoPorGastar(codigo) {
            const { data } = await admin.from("codigos")
                .select("user_id")
                .eq("codigo", codigo).is("usado_em", null).maybeSingle();
            return data ?? null;
        },
        async pessoaPorEmail(email) {
            // O email do pagador nao e o email da conta por definicao —
            // e uma pista, e por isso e que sozinho nao credita.
            //
            // Vai por funcao e nao por tabela: `auth.users` nao esta
            // exposto, e o que se abre e uma porta que responde a uma
            // pergunta so, fechada a anon e a authenticated.
            const { data } = await admin.rpc("pessoa_por_email", {
                p_email: email,
            });
            return typeof data === "string" ? data : null;
        },
    };

    try {
        // 3. Quem e o que. Nunca adivinha (provado em `cascata_test.ts`).
        const c = await casar(pagamento, registo);

        // 4. Tudo ou nada, numa transacao.
        const { data, error } = await admin.rpc("assentar_pagamento", {
            p_message_id: pagamento.id_externo,
            p_valor: pagamento.valor,
            p_moeda: pagamento.moeda,
            p_cru: pagamento.cru,
            p_user_id: c.user_id,
            p_ato_slug: c.ato_slug,
            p_por: c.por === "sku+email" ? "sku" : c.por,
            // O codigo vai sempre que exista: e la dentro que o cesto se
            // le, a conta se confere e o codigo se marca como gasto.
            p_codigo: c.codigo,
        });
        if (error) throw error;

        // 5. `creditado`, `fila` e `duplicado` sao todos sucesso.
        console.log(`pagamento ${pagamento.id_externo}: ${data}`);
        return new Response(null, { status: 200 });
    } catch (e) {
        console.error("assentar:", (e as Error).message);
        return new Response(null, { status: 500 });
    }
});
