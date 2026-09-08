// Prova da cascata. Corre sem base de dados e sem rede:
//
//   docker run --rm -v "$PWD":/w -w /w denoland/deno:latest \
//       deno test server/functions/
//
// O que interessa provar nao e o caminho feliz — e que nada credita por
// adivinhacao.

import { assertEquals } from "jsr:@std/assert@1";
import { casar, codigoNaMensagem, podeCreditar } from "./cascata.ts";
import type { Pagamento, Registo } from "./pagamento.ts";

const PESSOA = "11111111-1111-1111-1111-111111111111";

function pagamento(p: Partial<Pagamento> = {}): Pagamento {
    return {
        origem: "kofi",
        id_externo: "msg-1",
        valor: 14,
        moeda: "USD",
        email: null,
        mensagem: null,
        sku: null,
        cru: {},
        ...p,
    };
}

const REGISTO: Registo = {
    atoPorSku: (sku) =>
        Promise.resolve(sku === "SKU-SACRIFICIO" ? "sacrificio" : null),
    codigoPorGastar: (c) =>
        Promise.resolve(
            c === "BAR-7X2K"
                ? { user_id: PESSOA, ato_slug: "vela_20min" }
                : null,
        ),
    pessoaPorEmail: (e) =>
        Promise.resolve(e === "quem@paga.pt" ? PESSOA : null),
};

Deno.test("o codigo aparece no meio do que a pessoa escreveu", () => {
    assertEquals(codigoNaMensagem("obrigado! BAR-7X2K axe"), "BAR-7X2K");
    assertEquals(codigoNaMensagem("bar-7x2k"), "BAR-7X2K");
    assertEquals(codigoNaMensagem("sem codigo nenhum"), null);
    assertEquals(codigoNaMensagem(null), null);
    // Nao e um codigo: e curto de mais.
    assertEquals(codigoNaMensagem("BAR-7X2"), null);
});

Deno.test("codigo: responde as duas perguntas e credita", async () => {
    const c = await casar(pagamento({ mensagem: "BAR-7X2K" }), REGISTO);
    assertEquals(c.por, "codigo");
    assertEquals(c.user_id, PESSOA);
    assertEquals(c.ato_slug, "vela_20min");
    assertEquals(podeCreditar(c), true);
});

Deno.test("SKU mais email: as duas metades, credita", async () => {
    const c = await casar(
        pagamento({ sku: "SKU-SACRIFICIO", email: "quem@paga.pt" }),
        REGISTO,
    );
    assertEquals(c.por, "sku+email");
    assertEquals(c.ato_slug, "sacrificio");
    assertEquals(podeCreditar(c), true);
});

Deno.test("so email: sabe-se quem, NAO se sabe o que — nao credita", async () => {
    const c = await casar(pagamento({ email: "quem@paga.pt" }), REGISTO);
    assertEquals(c.user_id, PESSOA);
    assertEquals(c.ato_slug, null);
    assertEquals(c.por, "email");
    assertEquals(podeCreditar(c), false);
});

Deno.test("so SKU: sabe-se o que, NAO se sabe de quem — nao credita", async () => {
    const c = await casar(pagamento({ sku: "SKU-SACRIFICIO" }), REGISTO);
    assertEquals(c.ato_slug, "sacrificio");
    assertEquals(c.user_id, null);
    assertEquals(podeCreditar(c), false);
});

Deno.test("o valor pago NAO decide o acto", async () => {
    // 14 USD sao 7 cafes, e 7 cafes sao dois actos diferentes:
    // `assentamento_firmeza` e `sacrificio`. Sem codigo e sem SKU nao ha
    // como escolher, e escolher era adivinhar.
    const c = await casar(pagamento({ valor: 14, email: "quem@paga.pt" }), REGISTO);
    assertEquals(c.ato_slug, null);
    assertEquals(podeCreditar(c), false);
});

Deno.test("codigo ja gasto nao credita nem estraga o resto", async () => {
    const c = await casar(
        pagamento({ mensagem: "BAR-0000", email: "quem@paga.pt" }),
        REGISTO,
    );
    // Cai para os degraus seguintes: o email da a pessoa, e mais nada.
    assertEquals(c.por, "email");
    assertEquals(podeCreditar(c), false);
});

Deno.test("nada de nada: fila manual, sem pessoa e sem acto", async () => {
    const c = await casar(pagamento(), REGISTO);
    assertEquals(c.por, null);
    assertEquals(podeCreditar(c), false);
});
