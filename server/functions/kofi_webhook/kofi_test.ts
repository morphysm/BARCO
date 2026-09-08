// Prova da traducao do payload do Ko-fi.
//
// LE O `payload_exemplo.json` DE PROPOSITO. Esse ficheiro e o que se
// substitui pelo payload a serio da pagina de webhooks — e quando isso
// acontecer, sao estas provas que dizem se os nomes em `CAMPOS` ainda
// batem certo. Um teste com o payload escrito a mao dentro dele nao
// provava nada: provava que eu concordo comigo proprio.
//
//   docker run --rm -v "$PWD":/w -w /w denoland/deno:latest \
//       deno test --allow-read server/functions/

import { assert, assertEquals, assertThrows } from "jsr:@std/assert@1";
import { CAMPOS, PayloadMau, token, traduzir } from "./kofi.ts";

const AQUI = new URL(".", import.meta.url).pathname;
const EXEMPLO = JSON.parse(
    await Deno.readTextFile(AQUI + "payload_exemplo.json"),
) as Record<string, unknown>;

Deno.test("o exemplo nao traz um token a serio", () => {
    // Se isto falhar, alguem colou o payload com o token verdadeiro e o
    // segredo esta no repositorio.
    assertEquals(
        EXEMPLO[CAMPOS.token],
        "XXX",
        "o token do exemplo tem de estar trocado por XXX",
    );
});

Deno.test("le-se o token antes de tudo o resto", () => {
    assertEquals(token(EXEMPLO), "XXX");
    assertEquals(token({}), null);
});

Deno.test("traduz o exemplo para um Pagamento", () => {
    const p = traduzir(EXEMPLO);
    assertEquals(p.origem, "kofi");
    assert(p.id_externo.length > 0, "sem id nao ha idempotencia");
    assertEquals(p.moeda, "USD");
    assertEquals(p.valor, 14);
    assertEquals(p.email, "quem@paga.pt");
    assert(p.mensagem?.includes("BAR-7X2K"));
    assertEquals(p.cru, EXEMPLO);
});

Deno.test("sem id nao passa — parte a idempotencia", () => {
    const sem = { ...EXEMPLO };
    delete sem[CAMPOS.id];
    assertThrows(() => traduzir(sem), PayloadMau, CAMPOS.id);
});

Deno.test("o valor vem como TEXTO e le-se com tolerancia", () => {
    assertEquals(traduzir({ ...EXEMPLO, [CAMPOS.valor]: "3.00" }).valor, 3);
    // Virgula decimal e simbolo de moeda: nao se confirmou que o Ko-fi os
    // mande, mas se mandar nao pode ser isso a bloquear um pagamento.
    assertEquals(traduzir({ ...EXEMPLO, [CAMPOS.valor]: "3,50" }).valor, 3.5);
    assertEquals(traduzir({ ...EXEMPLO, [CAMPOS.valor]: "$14.00" }).valor, 14);
});

Deno.test("um valor que nao se percebe NAO bloqueia o pagamento", () => {
    // Isto rebentava. Estava errado: o valor nao decide nada, e um 500
    // aqui punha o Ko-fi a reenviar para sempre um pagamento que dava
    // para creditar bem — o codigo nem olha para o valor.
    const p = traduzir({ ...EXEMPLO, [CAMPOS.valor]: "catorze" });
    assertEquals(p.valor, null, "desconhecido le-se null, NUNCA zero");
    // Um pagamento registado com 0.00 e uma mentira que ninguem detecta
    // depois. Estes tres davam zero antes de se confirmar o feitio.
    for (const mau of ["", ".", "-", "1.2.3"]) {
        assertEquals(traduzir({ ...EXEMPLO, [CAMPOS.valor]: mau }).valor, null, mau);
    }
    assert(p.id_externo.length > 0, "o resto do pagamento sobrevive");
    assert(p.mensagem?.includes("BAR-7X2K"), "e o codigo continua la");
});

Deno.test("sem moeda tambem nao bloqueia", () => {
    const sem = { ...EXEMPLO };
    delete sem[CAMPOS.moeda];
    assertEquals(traduzir(sem).moeda, null);
});

Deno.test("os nulos que a documentacao preve", () => {
    // `shop_items` e `tier_name` sao "array ou null" e "string ou null";
    // uma doacao sem texto traz `message` a null.
    const p = traduzir({
        ...EXEMPLO,
        [CAMPOS.artigos]: null,
        [CAMPOS.mensagem]: null,
        tier_name: null,
    });
    assertEquals(p.sku, null);
    assertEquals(p.mensagem, null);
});

Deno.test("pagamento de subscricao: entra, e sem codigo vai para a fila", () => {
    // O app nao tem subscricoes (AGENTS.md), mas nada impede alguem de
    // subscrever a PAGINA do Ko-fi. Cada renovacao dispara o webhook.
    const p = traduzir({
        ...EXEMPLO,
        type: "Subscription",
        is_subscription_payment: true,
        is_first_subscription_payment: false,
        tier_name: "Bronze",
        [CAMPOS.mensagem]: null,
    });
    assertEquals(p.mensagem, null, "sem mensagem nao ha codigo");
    assertEquals(p.sku, null, "e sem SKU nao ha acto");
    // Sem acto nao credita: cai na fila. Provado em `cascata_test.ts`.
});

Deno.test("renovacao que repete a mensagem original nao credita outra vez", () => {
    // Se o Ko-fi repetir o texto da primeira subscricao nas renovacoes, o
    // BAR-XXXX vem outra vez. Nao credita: o codigo e de uso unico, e a
    // segunda vinda encontra-o gasto (prova 3 do `assentar_pagamento.sql`).
    const p = traduzir({ ...EXEMPLO, [CAMPOS.id]: "msg-renovacao" });
    assertEquals(p.id_externo, "msg-renovacao", "id novo: nao e duplicado");
    assert(p.mensagem?.includes("BAR-7X2K"), "e traz o mesmo codigo");
});

Deno.test("compra de loja a serio: varios artigos", () => {
    // A documentacao mostra `shop_items` como lista e nao garante um so.
    const p = traduzir({
        ...EXEMPLO,
        type: "Shop Order",
        [CAMPOS.artigos]: [
            { [CAMPOS.artigo_sku]: "1a2b3c4d5e" },
            { [CAMPOS.artigo_sku]: "5e4d3c2b1a" },
        ],
    });
    assertEquals(p.sku, null, "dois artigos nao se repartem: fila manual");
});

Deno.test("compra de loja: le o SKU de um artigo so", () => {
    const p = traduzir({
        ...EXEMPLO,
        [CAMPOS.artigos]: [{ [CAMPOS.artigo_sku]: "SKU-SACRIFICIO" }],
    });
    assertEquals(p.sku, "SKU-SACRIFICIO");
});

Deno.test("varios artigos nao se repartem: vai para a fila", () => {
    const p = traduzir({
        ...EXEMPLO,
        [CAMPOS.artigos]: [
            { [CAMPOS.artigo_sku]: "SKU-A" },
            { [CAMPOS.artigo_sku]: "SKU-B" },
        ],
    });
    assertEquals(p.sku, null, "dois artigos num pagamento nao se adivinham");
});
