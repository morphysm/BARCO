// Sonda: diz QUE variaveis `SUPABASE_*` o runtime injecta, e o feitio do
// que la esta — NUNCA os valores.
//
// Existe porque a chave de admin vem de um dicionario JSON
// (`SUPABASE_SECRET_KEYS`) e a alternativa a isto era assumir que ele la
// esta e com que nome. Correu-se uma vez contra o runtime local e a
// resposta foi:
//
//     SUPABASE_SECRET_KEYS:      JSON com as chaves: default
//     SUPABASE_PUBLISHABLE_KEYS: JSON com as chaves: default
//     SUPABASE_URL, SUPABASE_DB_URL, SUPABASE_JWKS, e as chaves antigas
//
// Vale a pena voltar a corre-la depois do primeiro `functions deploy`:
// confirma que o runtime alojado injecta o mesmo, em vez de se supor.
//
// NAO A DEIXAR ACESSIVEL SEM AUTENTICACAO NUM PROJECTO A SERIO. Nao
// imprime segredos, mas os nomes das variaveis sao informacao sobre a
// casa e nao ha razao para os oferecer a quem passa.
Deno.serve(() => {
    const saida: Record<string, string> = {};
    for (const [k, v] of Object.entries(Deno.env.toObject())) {
        if (!k.startsWith("SUPABASE_")) continue;
        let feitio = `${typeof v}, ${v.length} chars`;
        try {
            const j = JSON.parse(v);
            if (typeof j === "object" && j !== null) {
                feitio = `JSON com as chaves: ${Object.keys(j).join(", ")}`;
            }
        } catch { /* nao e JSON */ }
        saida[k] = feitio;
    }
    return new Response(JSON.stringify(saida, null, 2), {
        headers: { "content-type": "application/json" },
    });
});
