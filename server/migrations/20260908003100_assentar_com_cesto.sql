-- `assentar_pagamento`, agora com cesto.
--
-- Muda em tres coisas em relacao a anterior:
--
--   1. o codigo traz um CESTO (`codigo_itens`) e nao um acto so, portanto
--      escrevem-se tantos creditos quantos o cesto disser;
--
--   2. a garantia de nao creditar duas vezes passa a ser o
--      `pagamentos.creditado_em`, com o mesmo teste-e-marca atomico do
--      `codigos.usado_em` — o UNIQUE que havia em `source_payment_id`
--      deixou de poder existir com varios creditos por pagamento;
--
--   3. CONFERE-SE O VALOR. Um codigo que nomeia um cesto e uma conta a
--      pagar; sem esta verificacao seria um cheque em branco, e quem
--      pagasse 2 USD levava o cesto todo. Se o que entrou nao chegar
--      para o que o cesto custa, NAO se credita — vai para a fila
--      manual, com o codigo intacto para alguem resolver a mao.
--
--      So se confere em USD, que e a moeda em que o Ko-fi cobra
--      (§10.1). Noutra moeda nao se adivinha uma conversao: vai para a
--      fila, que e o que o §10.4 manda fazer quando nao se sabe.
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

    -- O codigo, reconfirmado aqui dentro, e com ele o cesto.
    if p_codigo is not null then
        update public.codigos
           set usado_em = now()
         where codigo = p_codigo
           and usado_em is null
        returning user_id into v_user_id;

        if not found then
            v_user_id := null;
            v_por := null;
        else
            select coalesce(sum(a.cafes * i.quantidade), 0)
              into v_custo
              from public.codigo_itens i
              join public.atos a on a.slug = i.ato_slug
             where i.codigo = p_codigo;

            -- 1 cafe = 2 USD (§10.1). A conta e do servidor: o cliente
            -- mostra o numero, nao o decide.
            v_pagos := case when upper(coalesce(p_moeda, '')) = 'USD'
                            then coalesce(p_valor, 0) else -1 end;
            if v_custo > 0 and v_pagos >= v_custo * 2 then
                v_cesto := true;
            else
                -- Pagou-se menos do que o cesto custa, ou noutra moeda.
                -- Nao se credita nada e nao se adivinha metade do cesto.
                v_user_id := null;
                v_por := null;
            end if;
        end if;
    end if;

    -- Um pagamento credita-se UMA vez. Teste e marca numa operacao so.
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
