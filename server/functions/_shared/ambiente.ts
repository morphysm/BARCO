// As chaves, lidas com verificacao a serio.
//
// O exemplo da documentacao do Supabase escreve-se assim:
//
//     JSON.parse(Deno.env.get('SUPABASE_SECRET_KEYS')!)
//
// e o `!` e uma mentira ao compilador: se a variavel nao existir, aquilo
// e `JSON.parse(null)` e rebenta com um `TypeError` que nao diz o que
// falta. Num webhook de pagamento isso significa o Ko-fi a reenviar
// contra uma funcao que rebenta sempre, pagamentos a entrar, ninguem
// creditado, e nada no ecra a dizer porque. Por isso e lido a mao, uma
// vez, com o nome da variavel na mensagem.

export class FaltaChave extends Error {}

function exigir(nome: string): string {
    const v = Deno.env.get(nome);
    if (!v) throw new FaltaChave(`falta a variavel de ambiente ${nome}`);
    return v;
}

/// A chave de admin, do dicionario novo. Passa por cima do RLS: e a unica
/// que pode escrever em `pagamentos` e `creditos`, e nunca sai daqui.
///
/// `SUPABASE_SECRET_KEYS` e injectada em todas as Edge Functions e e um
/// dicionario JSON. A entrada `default` e a que existe sempre; outras so
/// aparecem se forem criadas com nome proprio no painel.
export function chaveDeAdmin(entrada = "default"): string {
    const cru = exigir("SUPABASE_SECRET_KEYS");
    let dic: unknown;
    try {
        dic = JSON.parse(cru);
    } catch {
        throw new FaltaChave("SUPABASE_SECRET_KEYS nao e JSON valido");
    }
    if (typeof dic !== "object" || dic === null) {
        throw new FaltaChave("SUPABASE_SECRET_KEYS nao e um dicionario");
    }
    const chave = (dic as Record<string, unknown>)[entrada];
    if (typeof chave !== "string" || chave === "") {
        const tem = Object.keys(dic as Record<string, unknown>).join(", ");
        // Os NOMES das entradas, nunca os valores.
        throw new FaltaChave(
            `SUPABASE_SECRET_KEYS nao tem "${entrada}". Tem: ${tem || "nada"}`,
        );
    }
    return chave;
}

export function url(): string {
    return exigir("SUPABASE_URL");
}

/// O token do Ko-fi. Este NAO e injectado por ninguem: e um segredo da
/// conta do Ko-fi e poe-se a mao nas definicoes da funcao.
export function tokenDoKofi(): string {
    return exigir("KOFI_VERIFICATION_TOKEN");
}

/// Comparacao de segredos em tempo constante.
///
/// Um `===` sai no primeiro caractere diferente, e o tempo que demora diz
/// quantos acertaram. Com reenvios a vontade da-se um token ao contrario,
/// letra a letra.
export function iguaisEmTempoConstante(a: string, b: string): boolean {
    const x = new TextEncoder().encode(a);
    const y = new TextEncoder().encode(b);
    const n = Math.max(x.length, y.length);
    // O comprimento entra na conta, e o indice fora do fim vale zero:
    // percorre-se sempre `n` posicoes, aconteca o que acontecer.
    let dif = x.length ^ y.length;
    for (let i = 0; i < n; i++) dif |= (x[i] ?? 0) ^ (y[i] ?? 0);
    return dif === 0;
}
