import { assert, assertEquals, assertThrows } from "jsr:@std/assert@1";
import { chaveDeAdmin, FaltaChave, iguaisEmTempoConstante } from "./ambiente.ts";

Deno.test("a chave de admin sai da entrada default", () => {
    Deno.env.set("SUPABASE_SECRET_KEYS", '{"default":"sb_secret_abc"}');
    assertEquals(chaveDeAdmin(), "sb_secret_abc");
});

Deno.test("uma chave com nome proprio tambem se le", () => {
    Deno.env.set(
        "SUPABASE_SECRET_KEYS",
        '{"default":"sb_secret_abc","webhooks":"sb_secret_xyz"}',
    );
    assertEquals(chaveDeAdmin("webhooks"), "sb_secret_xyz");
});

Deno.test("sem a variavel: diz o NOME que falta, nao um TypeError", () => {
    Deno.env.delete("SUPABASE_SECRET_KEYS");
    assertThrows(() => chaveDeAdmin(), FaltaChave, "SUPABASE_SECRET_KEYS");
});

Deno.test("entrada que nao existe: lista as que ha, sem os valores", () => {
    Deno.env.set("SUPABASE_SECRET_KEYS", '{"default":"sb_secret_abc"}');
    try {
        chaveDeAdmin("nao_existe");
        assert(false, "devia ter rebentado");
    } catch (e) {
        const m = (e as Error).message;
        assert(m.includes("default"), "diz os nomes que ha");
        assert(!m.includes("sb_secret_abc"), "NAO diz o valor de nenhuma");
    }
});

Deno.test("JSON estragado nao passa por dicionario vazio", () => {
    Deno.env.set("SUPABASE_SECRET_KEYS", "isto nao e json");
    assertThrows(() => chaveDeAdmin(), FaltaChave, "JSON");
});

Deno.test("comparacao em tempo constante", () => {
    assert(iguaisEmTempoConstante("abc", "abc"));
    assert(!iguaisEmTempoConstante("abc", "abd"));
    assert(!iguaisEmTempoConstante("abc", "abcd"));
    assert(!iguaisEmTempoConstante("", "a"));
    assert(iguaisEmTempoConstante("", ""));
});
