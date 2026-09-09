-- Valida antes de consumir. Valores diferentes seguem para reconciliacao.
alter table public.codigos add column pagamento_id uuid references public.pagamentos(id);

create or replace function public.assentar_pagamento(
    p_message_id  text,
    p_valor       numeric,
    p_moeda       text,
    p_cru         jsonb,
    p_user_id     uuid,
    p_ato_slug    text,
    p_por         text,
    p_codigo      text
) returns text
language plpgsql
security definer
set search_path = public
as $$
declare
    v_pagamento  uuid;
    v_user_id    uuid := p_user_id;
    v_por        text := p_por;
    v_cesto      boolean := false;
    v_valido     boolean := false;
    v_custo      integer;
    v_pagos      numeric;
    v_item       record;
begin
    insert into public.pagamentos (kofi_message_id, amount, currency, raw)
    values (p_message_id, p_valor, p_moeda, p_cru)
    on conflict (kofi_message_id) do nothing
    returning id into v_pagamento;

    if v_pagamento is null then
        return 'duplicado';
    end if;

    if p_codigo is not null then
        select user_id, cafes_total into v_user_id, v_custo
          from public.codigos
         where codigo = p_codigo and usado_em is null
           for update;

        if not found then
            v_user_id := null;
            v_por := null;
        else
            -- 1 cafe = 2 USD (SPEC.md §10.1). So se confere em USD, a
            -- moeda em que o Ko-fi cobra: noutra nao se adivinha cambio.
            v_pagos := case when upper(coalesce(p_moeda, '')) = 'USD'
                            then coalesce(p_valor, 0) else -1 end;
            if coalesce(v_custo, 0) > 0 and v_pagos = v_custo * 2 then
                v_cesto := exists (
                    select 1 from public.codigo_itens where codigo = p_codigo);
                v_valido := v_cesto;
                if v_valido then
                    update public.codigos set usado_em = now(), pagamento_id = v_pagamento
                     where codigo = p_codigo;
                end if;
            else
                v_user_id := null;
                v_por := null;
            end if;
        end if;
    elsif v_user_id is not null and p_ato_slug is not null and p_por = 'sku' then
        select cafes into v_custo from public.atos where slug = p_ato_slug;
        v_valido := coalesce(v_custo > 0 and upper(p_moeda) = 'USD'
                             and p_valor = v_custo * 2, false);
    end if;

    if v_valido then
        update public.pagamentos
           set creditado_em = now(), user_id = v_user_id, matched_by = v_por
         where id = v_pagamento
           and creditado_em is null;
        if not found then
            return 'duplicado';
        end if;

        if v_cesto then
            for v_item in
                select ato_slug, quantidade from public.codigo_itens
                 where codigo = p_codigo
            loop
                for _ in 1..v_item.quantidade loop
                    insert into public.creditos (user_id, ato_slug, source_payment_id)
                    values (v_user_id, v_item.ato_slug, v_pagamento);
                end loop;
            end loop;
        else
            insert into public.creditos (user_id, ato_slug, source_payment_id)
            values (v_user_id, p_ato_slug, v_pagamento);
        end if;
        return 'creditado';
    end if;

    update public.pagamentos
       set user_id = v_user_id, matched_by = v_por
     where id = v_pagamento;

    insert into public.reconciliacao (kofi_message_id, raw)
    values (p_message_id, p_cru);

    return 'fila';
end;
$$;

revoke execute on function public.assentar_pagamento(
    text, numeric, text, jsonb, uuid, text, text, text) from public;
grant execute on function public.assentar_pagamento(
    text, numeric, text, jsonb, uuid, text, text, text) to service_role;

-- Somente o dono ve o estado; nenhum payload nem email e exposto.
create function public.estado_codigo(p_codigo text)
returns jsonb language sql stable security definer set search_path = public
as $$
    select jsonb_build_object('codigo', c.codigo, 'total_usd', c.cafes_total * 2,
        'estado', case
          when exists (select 1 from public.pagamentos p
                       where p.id = c.pagamento_id and p.creditado_em is not null)
            then 'creditado'
          when c.usado_em is not null then 'revisao'
          else 'pendente' end)
    from public.codigos c where c.codigo = p_codigo and c.user_id = auth.uid();
$$;
revoke all on function public.estado_codigo(text) from public, anon, authenticated;
grant execute on function public.estado_codigo(text) to authenticated;
