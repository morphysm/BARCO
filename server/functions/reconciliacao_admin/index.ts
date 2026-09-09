// Vista pequena para a fila manual do SPEC.md §10.4.
//
// Toda leitura e escrita exige uma sessao Supabase valida e uma linha em
// `administradores`. A chave de admin nunca chega ao browser.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { chaveDeAdmin, FaltaChave, url } from "../_shared/ambiente.ts";

const ORIGEM_ADMIN = "http://127.0.0.1:4173";

function json(corpo: unknown, status = 200): Response {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "access-control-allow-origin": ORIGEM_ADMIN,
      "vary": "origin",
    },
  });
}

function texto(v: unknown): string | null {
  return typeof v === "string" && v !== "" ? v : null;
}

function objecto(v: unknown): Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v)
    ? v as Record<string, unknown>
    : {};
}

function resumoDoRaw(v: unknown): Record<string, unknown> {
  const raw = objecto(v);
  return {
    type: texto(raw.type),
    email: texto(raw.email),
    message: texto(raw.message),
    shop_items: Array.isArray(raw.shop_items) ? raw.shop_items : [],
  };
}

Deno.serve(async (pedido: Request): Promise<Response> => {
  let endpoint: string;
  let admin;
  try {
    endpoint = url();
    admin = createClient(endpoint, chaveDeAdmin(), {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  } catch (e) {
    if (e instanceof FaltaChave) console.error("configuracao:", e.message);
    return new Response(null, { status: 500 });
  }

  const origem = pedido.headers.get("origin");
  if (origem !== null && origem !== ORIGEM_ADMIN) {
    return json({ erro: "origem recusada" }, 403);
  }
  if (pedido.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "access-control-allow-origin": ORIGEM_ADMIN,
        "access-control-allow-methods": "POST, OPTIONS",
        "access-control-allow-headers": "authorization, content-type",
        "access-control-max-age": "600",
        "vary": "origin",
      },
    });
  }
  if (pedido.method !== "POST") return new Response(null, { status: 405 });

  const cabecalho = pedido.headers.get("authorization") ?? "";
  const token = cabecalho.startsWith("Bearer ") ? cabecalho.slice(7) : "";
  if (token === "") return json({ erro: "sessao em falta" }, 401);

  const { data: identidade, error: erroIdentidade } = await admin.auth
    .getUser(token);
  const operador = identidade.user?.id ?? null;
  if (erroIdentidade || operador === null) {
    return json({ erro: "sessao invalida" }, 401);
  }
  const { data: permitido, error: erroPermissao } = await admin
    .from("administradores").select("user_id")
    .eq("user_id", operador).maybeSingle();
  if (erroPermissao) {
    console.error("autorizacao:", erroPermissao.message);
    return json({ erro: "nao foi possivel verificar a autorizacao" }, 500);
  }
  if (permitido === null) return json({ erro: "sem autorizacao" }, 403);

  let entrada: Record<string, unknown>;
  try {
    entrada = objecto(await pedido.json());
  } catch {
    return json({ erro: "pedido invalido" }, 400);
  }

  if (entrada.acao === "listar") {
    const { data: fila, error: erroFila } = await admin
      .from("reconciliacao")
      .select("id,kofi_message_id")
      .is("resolved_at", null)
      .limit(100);
    if (erroFila) {
      console.error("fila:", erroFila.message);
      return json({ erro: "nao foi possivel ler a fila" }, 500);
    }

    const ids = (fila ?? []).map((r) => r.kofi_message_id);
    let pagamentos: Array<Record<string, unknown>> = [];
    if (ids.length > 0) {
      const { data, error } = await admin.from("pagamentos")
        .select(
          "id,kofi_message_id,amount,currency,user_id,matched_by,creditado_em,created_at,raw",
        )
        .in("kofi_message_id", ids);
      if (error) {
        console.error("pagamentos:", error.message);
        return json({ erro: "nao foi possivel ler os pagamentos" }, 500);
      }
      pagamentos = data ?? [];
    }
    const porId = new Map(
      pagamentos.map((p) => [p.kofi_message_id, p]),
    );
    const linhas = (fila ?? []).map((r) => {
      const p = porId.get(r.kofi_message_id) ?? {};
      return {
        id: r.id,
        kofi_message_id: r.kofi_message_id,
        pagamento_id: p.id ?? null,
        amount: p.amount ?? null,
        currency: p.currency ?? null,
        created_at: p.created_at ?? null,
        user_id: p.user_id ?? null,
        matched_by: p.matched_by ?? null,
        creditado: p.creditado_em !== null &&
          p.creditado_em !== undefined,
        raw: resumoDoRaw(p.raw),
      };
    }).sort((a, b) => String(a.created_at).localeCompare(String(b.created_at)));

    const { data: atos, error: erroAtos } = await admin
      .from("atos").select("slug,cafes").order("slug");
    if (erroAtos) {
      console.error("atos:", erroAtos.message);
      return json({ erro: "nao foi possivel ler os actos" }, 500);
    }
    return json({ fila: linhas, atos: atos ?? [] });
  }

  if (entrada.acao === "procurar_pessoa") {
    const email = texto(entrada.email)?.trim().toLowerCase() ?? "";
    if (!email.includes("@")) return json({ erro: "email invalido" }, 400);
    const { data, error } = await admin.rpc("pessoa_por_email", {
      p_email: email,
    });
    if (error) {
      console.error("pessoa:", error.message);
      return json({ erro: "nao foi possivel procurar a pessoa" }, 500);
    }
    return json({ user_id: typeof data === "string" ? data : null });
  }

  if (entrada.acao === "resolver") {
    const reconciliacao = texto(entrada.reconciliacao_id);
    const pessoa = texto(entrada.user_id);
    const itens = entrada.itens;
    if (
      reconciliacao === null || pessoa === null ||
      !Array.isArray(itens)
    ) {
      return json({ erro: "faltam a fila, a pessoa ou os actos" }, 400);
    }
    const { data, error } = await admin.rpc("resolver_reconciliacao", {
      p_reconciliacao_id: reconciliacao,
      p_user_id: pessoa,
      p_itens: itens,
      p_resolved_by: operador,
    });
    if (error) return json({ erro: error.message }, 400);
    return json({ estado: data });
  }

  return json({ erro: "acao desconhecida" }, 400);
});
