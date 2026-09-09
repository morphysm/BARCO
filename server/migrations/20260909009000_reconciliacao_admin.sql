-- A fila manual precisa de uma porta estreita e atomica.
--
-- A vista de administracao autentica uma pessoa normal do Barco e esta
-- tabela diz quais dessas pessoas podem ver e resolver a fila. Nao ha
-- politica: so a Edge Function, com a chave de admin, chega aqui.
create table public.administradores (
    user_id     uuid primary key references auth.users (id) on delete cascade,
    created_at  timestamptz not null default now()
);

alter table public.administradores enable row level security;

revoke all on table public.administradores from public, anon, authenticated;
grant select on table public.administradores to service_role;

-- Resolve uma linha sem adivinhar nenhuma das duas respostas que faltavam:
-- a pessoa e os actos sao argumentos explicitos. A conta do pagamento tem
-- de bater exactamente com os actos escolhidos, em USD.
create function public.resolver_reconciliacao(
    p_reconciliacao_id uuid,
    p_user_id          uuid,
    p_itens            jsonb,
    p_resolved_by      uuid
) returns text
language plpgsql
security definer
set search_path = public
as $$
declare
    v_message_id   text;
    v_resolved_at  timestamptz;
    v_pagamento    uuid;
    v_creditado_em timestamptz;
    v_valor        numeric;
    v_moeda        text;
    v_cafes        integer;
    v_item         record;
begin
    if not exists (
        select 1 from public.administradores where user_id = p_resolved_by
    ) then
        raise exception 'sem autorizacao para reconciliar';
    end if;
    if not exists (select 1 from auth.users where id = p_user_id) then
        raise exception 'a pessoa escolhida nao existe';
    end if;
    if p_itens is null or jsonb_typeof(p_itens) <> 'array'
       or jsonb_array_length(p_itens) = 0
       or jsonb_array_length(p_itens) > 20 then
        raise exception 'escolhe entre 1 e 20 actos';
    end if;
    if exists (
        select 1
          from jsonb_array_elements(p_itens) i
         where jsonb_typeof(i) <> 'object'
            or coalesce(i->>'ato_slug', '') = ''
            or coalesce(i->>'quantidade', '') !~ '^[1-9][0-9]?$'
    ) then
        raise exception 'cada acto precisa de slug e quantidade entre 1 e 99';
    end if;
    if exists (
        select 1
          from jsonb_array_elements(p_itens) i
          left join public.atos a on a.slug = i->>'ato_slug'
         where a.slug is null
    ) then
        raise exception 'ha um acto que nao existe';
    end if;

    select r.kofi_message_id, r.resolved_at, p.id, p.creditado_em,
           p.amount, p.currency
      into v_message_id, v_resolved_at, v_pagamento, v_creditado_em,
           v_valor, v_moeda
      from public.reconciliacao r
      join public.pagamentos p on p.kofi_message_id = r.kofi_message_id
     where r.id = p_reconciliacao_id
       for update of r, p;

    if not found then
        raise exception 'linha de reconciliacao inexistente';
    end if;
    if v_resolved_at is not null then
        return 'duplicado';
    end if;
    if v_creditado_em is not null then
        raise exception 'pagamento ja creditado sem a fila estar resolvida';
    end if;

    select sum(a.cafes * (i->>'quantidade')::integer)
      into v_cafes
      from jsonb_array_elements(p_itens) i
      join public.atos a on a.slug = i->>'ato_slug';

    if upper(coalesce(v_moeda, '')) <> 'USD'
       or v_valor is null
       or v_valor <> v_cafes * 2 then
        raise exception 'os actos escolhidos nao batem com o pagamento exacto em USD';
    end if;

    -- Teste e marca com a linha bloqueada: dois cliques nunca escrevem duas
    -- vezes. Os varios creditos pertencem a um unico pagamento, como no cesto.
    update public.pagamentos
       set user_id = p_user_id, matched_by = 'manual', creditado_em = now()
     where id = v_pagamento and creditado_em is null;
    if not found then
        return 'duplicado';
    end if;

    for v_item in
        select i->>'ato_slug' as ato_slug,
               sum((i->>'quantidade')::integer)::integer as quantidade
          from jsonb_array_elements(p_itens) i
         group by i->>'ato_slug'
    loop
        for _ in 1..v_item.quantidade loop
            insert into public.creditos (user_id, ato_slug, source_payment_id)
            values (p_user_id, v_item.ato_slug, v_pagamento);
        end loop;
    end loop;

    update public.reconciliacao
       set resolved_by = p_resolved_by, resolved_at = now()
     where id = p_reconciliacao_id and resolved_at is null;
    if not found then
        raise exception 'a fila mudou durante a reconciliacao';
    end if;

    return 'creditado';
end;
$$;

revoke all on function public.resolver_reconciliacao(uuid, uuid, jsonb, uuid)
    from public, anon, authenticated;
grant execute on function public.resolver_reconciliacao(uuid, uuid, jsonb, uuid)
    to service_role;
