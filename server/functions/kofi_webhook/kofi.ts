// A traducao do que o Ko-fi manda para o `Pagamento` do §10.5.
//
// ======================================================================
//  OS NOMES DOS CAMPOS AQUI EM BAIXO NAO ESTAO CONFIRMADOS.
//
//  SPEC.md §10.3, em maiusculas: "Confirm the exact field names against a
//  live test payload from the Ko-fi webhooks page before writing the
//  parser. Do not assume the schema."
//
//  Nao houve acesso a conta do Ko-fi para o fazer. O que esta aqui e o
//  melhor conhecido, escrito NUM SITIO SO para se corrigir num sitio so.
//
//  Como confirmar, e e cinco minutos:
//    1. ko-fi.com/manage/webhooks, botao de enviar um teste;
//    2. copiar o JSON que a pagina mostra;
//    3. gravar em `payload_exemplo.json`, TROCANDO o token por "XXX";
//    4. corrigir `CAMPOS` para os nomes que la estiverem;
//    5. correr as provas. Elas leem esse ficheiro.
//
//  Enquanto isto nao for feito, o webhook nao deve estar ligado a uma
//  conta a serio: um nome errado aqui nao credita mal — rebenta, que e o
//  que se quer — mas rebentar em producao sao pagamentos a entrar sem
//  ninguem creditado.
// ======================================================================

import type { Pagamento } from "../_shared/pagamento.ts";

/// Os nomes dos campos no payload do Ko-fi. E este o unico sitio onde
/// eles aparecem.
export const CAMPOS = {
    /// O token que prova que o POST vem do Ko-fi.
    token: "verification_token",
    /// O identificador unico da entrega. A idempotencia inteira assenta
    /// neste campo: o Ko-fi reenvia com o mesmo ate receber 200.
    id: "message_id",
    valor: "amount",
    moeda: "currency",
    email: "email",
    /// O que a pessoa escreveu ao pagar. E aqui que o BAR-XXXX vem.
    mensagem: "message",
    /// Compras de loja. Uma lista, cada item com o seu SKU.
    artigos: "shop_items",
    artigo_sku: "direct_link_code",
} as const;

/// O Ko-fi POSTa `application/x-www-form-urlencoded` com UM campo, `data`,
/// que traz o JSON la dentro. Tambem por confirmar.
export const CAMPO_DO_CORPO = "data";

export class PayloadMau extends Error {}

/// Tira o JSON do corpo do pedido.
export async function corpo(pedido: Request): Promise<Record<string, unknown>> {
    const tipo = pedido.headers.get("content-type") ?? "";
    let texto: string | null = null;

    if (tipo.includes("application/x-www-form-urlencoded")) {
        const form = await pedido.formData();
        const d = form.get(CAMPO_DO_CORPO);
        texto = typeof d === "string" ? d : null;
        if (texto === null) {
            throw new PayloadMau(
                `corpo em formulario sem o campo "${CAMPO_DO_CORPO}"`,
            );
        }
    } else {
        texto = await pedido.text();
    }

    try {
        const j = JSON.parse(texto);
        if (typeof j !== "object" || j === null) throw new Error();
        return j as Record<string, unknown>;
    } catch {
        throw new PayloadMau("o corpo nao e JSON");
    }
}

/// O token, para se verificar ANTES de se tocar em mais alguma coisa.
export function token(p: Record<string, unknown>): string | null {
    const t = p[CAMPOS.token];
    return typeof t === "string" ? t : null;
}

/// Traduz.
///
/// SO UM CAMPO REBENTA: o `message_id`. E o unico que carrega alguma
/// coisa — a idempotencia inteira assenta nele, e segui-lo em falta era
/// deixar o mesmo pagamento creditar vezes sem conta.
///
/// Todos os outros degradam para nulo, e e de proposito. A primeira
/// versao disto rebentava tambem no `amount` e no `currency`, e estava
/// errada: nenhum dos dois decide nada — o acto vem do codigo ou do SKU,
/// e ja esta provado que o valor NAO desempata (`cascata_test.ts`). O que
/// aquilo fazia era trocar uma situacao recuperavel por uma perda
/// definitiva: um `amount` escrito de maneira inesperada respondia 500,
/// o Ko-fi reenviava para sempre, e um pagamento que dava para creditar
/// bem nunca era creditado — em silencio. Um campo que nao manda em nada
/// nao pode ter o poder de bloquear um pagamento.
export function traduzir(p: Record<string, unknown>): Pagamento {
    const id = p[CAMPOS.id];
    if (typeof id !== "string" || id === "") {
        throw new PayloadMau(
            `sem "${CAMPOS.id}": e nele que assenta a idempotencia`,
        );
    }

    return {
        origem: "kofi",
        id_externo: id,
        valor: numero(p[CAMPOS.valor]),
        moeda: texto(p[CAMPOS.moeda]),
        email: texto(p[CAMPOS.email]),
        mensagem: texto(p[CAMPOS.mensagem]),
        sku: sku(p[CAMPOS.artigos]),
        cru: p,
    };
}

/// O valor vem como TEXTO ("3.00"), nao como numero. Le-se com tolerancia
/// — virgula decimal, simbolo de moeda, espacos — e o que nao se
/// perceber fica nulo. O payload inteiro fica guardado em `raw` de
/// qualquer maneira, portanto nada se perde por aqui.
function numero(v: unknown): number | null {
    if (typeof v === "number") return Number.isFinite(v) ? v : null;
    if (typeof v !== "string") return null;
    const limpo = v.replace(/[^0-9,.\-]/g, "").replace(",", ".");
    // Confirma-se o FEITIO antes de converter. Sem isto, "catorze" limpava
    // para "" e `Number("")` e zero — o pagamento ficava registado como
    // 0.00, que e uma mentira, em vez de nulo, que e a verdade. Um valor
    // desconhecido tem de se ler como desconhecido.
    if (!/^-?\d+(\.\d+)?$/.test(limpo)) return null;
    return Number(limpo);
}

function texto(v: unknown): string | null {
    return typeof v === "string" && v !== "" ? v : null;
}

/// O SKU do primeiro artigo, quando a compra foi da loja.
///
/// So se le UM: um acto por pagamento. Uma compra com varios artigos nao
/// se reparte por adivinhacao — vai inteira para a fila manual.
function sku(v: unknown): string | null {
    if (!Array.isArray(v) || v.length !== 1) return null;
    const item = v[0];
    if (typeof item !== "object" || item === null) return null;
    return texto((item as Record<string, unknown>)[CAMPOS.artigo_sku]);
}
