// A cascata do SPEC.md §10.4, com uma correccao que a leitura do §10.4
// obriga e que vale a pena escrever aqui.
//
// O §10.4 desenha-a em fila:
//
//     codigo na mensagem -> email do pagador -> fila manual
//
// Mas os degraus nao respondem a mesma pergunta. Creditar precisa de
// DUAS: de quem e o pagamento, e que acto e que ele paga.
//
//   - o codigo responde as duas. Foi o app que o emitiu, e sabe para quem
//     e para que;
//   - o SKU da loja responde so ao QUE. Um artigo nao sabe quem o comprou;
//   - o email responde so ao QUEM. Dois actos custam 1 cafe, dois custam
//     3 e dois custam 7 — o valor pago nao chega para escolher entre
//     `vela_20min` e `oferenda_simples`.
//
// Entao nao se percorre uma fila: recolhe-se o que cada degrau souber e
// credita-se so quando as duas respostas existem. Um email sozinho da uma
// pessoa e nenhum acto, e isso NAO e um credito — e uma entrada na fila
// manual com a pessoa ja identificada, que e meio caminho andado para
// quem a for resolver.
//
// "Never auto-credit on a guess" (§10.4, AGENTS.md). Adivinhar o acto a
// partir do valor era exactamente isso.

import type { Casamento, Pagamento, Registo } from "./pagamento.ts";

/// O feitio do codigo que o app emite: BAR-7X2K.
///
/// Procura-se dentro da mensagem e nao no principio dela, porque a pessoa
/// escreve o que quiser a volta. Sem sensibilidade a maiusculas, que e o
/// telemovel a corrigir sozinho.
///
/// O SEPARADOR e frouxo de proposito. Isto nao chega aqui copiado por uma
/// maquina: chega escrito a mao na caixa de mensagem do Ko-fi, por quem
/// esta a ler o codigo de outro ecra. O travessao do corrector
/// automatico, o sublinhado, o ponto e o espaco sao todos a mesma coisa
/// que o hifen.
///
/// O que NAO se aceita e a ausencia de separador. `BAR-` colado a quatro
/// letras faz de "barcode" um codigo — e, depois da normalizacao la em
/// baixo, "CODE" vira "C0DE", que e um codigo que pode existir mesmo. Um
/// separador obrigatorio custa nada a quem escreve e fecha essa porta.
const CODIGO = /\bBAR(?:\s*[-_.‐-―]\s*|\s+)([0-9A-Z]{4})\b/i;

/// Os pares que se leem mal, e que sao seguros de desfazer.
///
/// O gerador (`pedir_codigo`) escolhe de 34 letras: os digitos todos e o
/// alfabeto sem `I` e sem `O`. E POR ISSO que isto e seguro e nao um
/// palpite: um `I` num codigo escrito nunca pode ter sido um `I` emitido,
/// porque nunca se emite nenhum — so pode ter sido o `1` que estava no
/// ecra. O mesmo para `O` e `0`.
///
/// Nao se toca no `L`: esse ESTA no alfabeto, e trocar `L` por `1` seria
/// estragar codigos verdadeiros para salvar os de quem se enganou.
const CONFUSOES: Record<string, string> = { I: "1", O: "0" };

export function codigoNaMensagem(mensagem: string | null): string | null {
    if (!mensagem) return null;
    const achado = mensagem.match(CODIGO);
    if (!achado) return null;
    const letras = achado[1]
        .toUpperCase()
        .replace(/[IO]/g, (c) => CONFUSOES[c]);
    return `BAR-${letras}`;
}

export async function casar(p: Pagamento, r: Registo): Promise<Casamento> {
    // 1. O codigo, se la estiver. Responde as duas perguntas de uma vez,
    //    portanto quando existe nao se pergunta mais nada.
    const codigo = codigoNaMensagem(p.mensagem);
    if (codigo) {
        const emitido = await r.codigoPorGastar(codigo);
        if (emitido) {
            // O acto fica nulo de proposito: um codigo nomeia um CESTO, e
            // o cesto le-se dentro da transacao que credita. Aqui so se
            // responde a primeira pergunta — de quem e.
            return {
                user_id: emitido.user_id,
                ato_slug: null,
                por: "codigo",
                codigo,
            };
        }
        // Codigo escrito mas desconhecido ou ja gasto: nao se inventa
        // nada a partir dele. Cai para os degraus seguintes.
    }

    // 2. O que sobra, cada um a responder a sua metade.
    const ato = p.sku ? await r.atoPorSku(p.sku) : null;
    const pessoa = p.email ? await r.pessoaPorEmail(p.email) : null;

    if (ato && pessoa) {
        return { user_id: pessoa, ato_slug: ato, por: "sku+email", codigo: null };
    }

    // 3. Meia resposta nao credita. Vai para a fila com o que se sabe, que
    //    e mais do que nada para quem a for resolver a mao.
    return {
        user_id: pessoa,
        ato_slug: ato,
        por: pessoa ? "email" : (ato ? "sku" : null),
        codigo: null,
    };
}

/// Credita-se ou vai para a fila?
///
/// Com codigo basta o codigo: ele diz de quem e, e o cesto diz o que
/// compra. Sem codigo continuam a ser precisas as duas respostas — um SKU
/// sozinho nao diz de quem e, um email sozinho nao diz o que paga.
export function podeCreditar(c: Casamento): boolean {
    if (c.codigo !== null) return c.user_id !== null;
    return c.user_id !== null && c.ato_slug !== null;
}
