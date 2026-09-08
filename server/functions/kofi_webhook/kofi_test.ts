// Prova da traducao, contra os payloads de exemplo DA DOCUMENTACAO do
// Ko-fi — os quatro que a pagina publica como referencia das formas
// reais, nao o disparo do botao de teste (que ha registo de mandar
// payloads errados nalguns casos).
//
// Estao em `payloads/`, com o token ja redigido na origem. Sao ficheiros
// e nao literais dentro do teste de proposito: quando um payload a serio
// aparecer, substitui-se o ficheiro e sao estas provas que dizem se os
// nomes ainda batem certo.
//
//   docker run --rm -v "$PWD":/w -w /w denoland/deno:latest \
//       deno test --allow-read server/functions/

import { assert, assertEquals, assertThrows } from "jsr:@std/assert@1";
import { CAMPOS, PayloadMau, token, traduzir } from "./kofi.ts";

const AQUI = new URL("./payloads/", import.meta.url).pathname;

async function payload(nome: string): Promise<Record<string, unknown>> {
    return JSON.parse(await Deno.readTextFile(AQUI + nome + ".json"));
}

const TIP = await payload("tip");
const SUB_PRIMEIRA = await payload("subscricao_primeira");
const SUB_TIER = await payload("subscricao_tier");
const COMPRA = await payload("compra");
const TODOS = { TIP, SUB_PRIMEIRA, SUB_TIER, COMPRA };

Deno.test("nenhum exemplo traz um token a serio", () => {
    for (const [nome, p] of Object.entries(TODOS)) {
        const t = p[CAMPOS.token];
        assert(
            typeof t === "string" && /^x+$/i.test(t),
            `${nome}: o token tem de estar redigido`,
        );
    }
});

Deno.test("os quatro traduzem-se, e o id existe em todos", () => {
    for (const [nome, p] of Object.entries(TODOS)) {
        const t = traduzir(p);
        assert(t.id_externo.length > 0, `${nome}: sem id nao ha idempotencia`);
        assertEquals(t.origem, "kofi");
        assertEquals(t.cru, p, `${nome}: o payload inteiro fica guardado`);
    }
});

Deno.test("o token le-se antes de tudo o resto", async () => {
    assertEquals(token(TIP), TIP[CAMPOS.token]);
    assertEquals(token({}), null);
});

Deno.test("tip: valor em texto, email, e o codigo viria na mensagem", () => {
    const p = traduzir(TIP);
    assertEquals(p.valor, 3, '"3.00" e texto e le-se como 3');
    assertEquals(p.moeda, "USD");
    assertEquals(p.email, "jo.example@example.com");
    assertEquals(p.mensagem, "Good luck with the integration!");
    assertEquals(p.sku, null, "uma gorjeta nao traz artigos");
});

Deno.test("subscricao: entra como qualquer outro pagamento", () => {
    const primeira = traduzir(SUB_PRIMEIRA);
    assert(primeira.mensagem !== null, "a primeira traz mensagem");
    assertEquals(primeira.sku, null);

    // A renovacao de tier vem SEM mensagem: nao ha codigo, nao ha acto,
    // vai para a fila. O app nao vende subscricoes (AGENTS.md), mas nada
    // impede alguem de subscrever a pagina do Ko-fi.
    const tier = traduzir(SUB_TIER);
    assertEquals(tier.mensagem, null);
    assertEquals(tier.sku, null);
    assertEquals(tier.valor, 5);
});

Deno.test("COMPRA: a mensagem vem NULA — o canal do codigo nao existe", () => {
    // E o achado que manda no desenho da cascata. Numa compra de loja nao
    // ha onde escrever o BAR-XXXX, portanto o unico caminho e SKU + email.
    const p = traduzir(COMPRA);
    assertEquals(p.mensagem, null);
    assertEquals(p.email, "jo.example@example.com");
});

Deno.test("COMPRA: dois artigos nao se repartem — fila manual", () => {
    const p = traduzir(COMPRA);
    assertEquals(p.sku, null, "27.95 por dois artigos nao da um acto so");
});

Deno.test("um artigo, um exemplar: e o caso que credita", () => {
    const p = traduzir({
        ...COMPRA,
        [CAMPOS.artigos]: [{
            [CAMPOS.artigo_sku]: "1a2b3c4d5e",
            variation_name: "Blue",
            [CAMPOS.artigo_quantidade]: 1,
        }],
    });
    assertEquals(p.sku, "1a2b3c4d5e");
});

Deno.test("um artigo, CINCO exemplares: nao credita um — vai para a fila", () => {
    // Sao cinco actos comprados. Creditar um era dar menos do que a
    // pessoa pagou, e em silencio. A restricao `creditos_um_por_pagamento`
    // so deixa um credito por pagamento, entao quem decide e uma pessoa.
    const p = traduzir({
        ...COMPRA,
        [CAMPOS.artigos]: [{
            [CAMPOS.artigo_sku]: "a1b2c3d4e5",
            variation_name: "Large",
            [CAMPOS.artigo_quantidade]: 5,
        }],
    });
    assertEquals(p.sku, null);
});

Deno.test("sem quantidade conta como um", () => {
    const p = traduzir({
        ...COMPRA,
        [CAMPOS.artigos]: [{ [CAMPOS.artigo_sku]: "1a2b3c4d5e" }],
    });
    assertEquals(p.sku, "1a2b3c4d5e");
});

Deno.test("sem message_id nao passa — parte a idempotencia", () => {
    const sem = { ...TIP };
    delete sem[CAMPOS.id];
    assertThrows(() => traduzir(sem), PayloadMau, CAMPOS.id);
});

Deno.test("o valor le-se com tolerancia, e o que nao se percebe fica nulo", () => {
    assertEquals(traduzir({ ...TIP, [CAMPOS.valor]: "27.95" }).valor, 27.95);
    assertEquals(traduzir({ ...TIP, [CAMPOS.valor]: "3,50" }).valor, 3.5);
    assertEquals(traduzir({ ...TIP, [CAMPOS.valor]: "$14.00" }).valor, 14);
    // Desconhecido le-se null, NUNCA zero: 0.00 e uma mentira que ninguem
    // detecta depois.
    for (const mau of ["catorze", "", ".", "-", "1.2.3"]) {
        assertEquals(traduzir({ ...TIP, [CAMPOS.valor]: mau }).valor, null, mau);
    }
});

Deno.test("um campo que nao manda em nada nao bloqueia o pagamento", () => {
    const sem = { ...TIP };
    delete sem[CAMPOS.moeda];
    delete sem[CAMPOS.valor];
    const p = traduzir(sem);
    assertEquals(p.moeda, null);
    assertEquals(p.valor, null);
    assert(p.mensagem !== null, "e o resto do pagamento sobrevive");
});
