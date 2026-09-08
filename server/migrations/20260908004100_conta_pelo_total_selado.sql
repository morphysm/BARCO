-- A conta e a que foi selada, nao a de agora.
--
-- O `assentar_pagamento` somava `atos.cafes` na hora de creditar. Entre
-- emitir o codigo e o pagamento chegar podem passar dias, e um preco pode
-- mudar nesse intervalo: a pessoa via 8 USD no ecra, pagava 8, e a
-- conferencia comparava com um cesto que entretanto custava 10.
--
-- Passa a usar o `codigos.cafes_total`, congelado quando o codigo nasceu.
-- Uma encomenda guarda o seu preco.
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
        -- Teste e marca numa operacao so, e traz consigo o dono e o total
        -- que ficaram selados na emissao.
        update public.codigos
           set usado_em = now()
         where codigo = p_codigo
           and usado_em is null
        returning user_id, cafes_total into v_user_id, v_custo;

        if not found then
            v_user_id := null;
            v_por := null;
        else
            -- 1 cafe = 2 USD (SPEC.md §10.1). So se confere em USD, a
            -- moeda em que o Ko-fi cobra: noutra nao se adivinha cambio.
            v_pagos := case when upper(coalesce(p_moeda, '')) = 'USD'
                            then coalesce(p_valor, 0) else -1 end;
            if coalesce(v_custo, 0) > 0 and v_pagos >= v_custo * 2 then
                v_cesto := true;
            else
                v_user_id := null;
                v_por := null;
            end if;
        end if;
    end if;

    if v_cesto or (v_user_id is not null and p_ato_slug is not null) then
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
