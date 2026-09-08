-- Assentar um pagamento, tudo ou nada.
--
-- Porque e que isto e SQL e nao TypeScript: sao quatro escritas que tem
-- de acontecer juntas — o pagamento, o codigo a ser marcado como gasto, o
-- credito, ou a entrada na fila. Feitas uma a uma da Edge Function, uma
-- falha a meio deixa um pagamento registado sem credito e sem fila: o
-- dinheiro entrou, a pessoa nao recebeu, e nada ficou a apontar que
-- faltava fazer. Numa transacao, ou acontece tudo ou nao acontece nada e
-- o Ko-fi reenvia.
--
-- A decisao de QUEM e O QUE vem de fora, ja tomada pela cascata
-- (`_shared/cascata.ts`, provada la). O que esta funcao faz de seu e uma
-- unica coisa: reconfirmar o codigo DENTRO da transacao. Entre a cascata
-- ter lido o codigo e esta escrita, o mesmo codigo pode ter sido gasto
-- por outra entrega — e dois pagamentos com o mesmo codigo nao creditam
-- dois actos.
create function public.assentar_pagamento(
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
    v_ato_slug   text := p_ato_slug;
    v_por        text := p_por;
begin
    -- A idempotencia. `kofi_message_id` e UNIQUE e e nele que ela
    -- assenta: se ja ca estava, este e um reenvio e nao se faz mais nada.
    insert into public.pagamentos (kofi_message_id, amount, currency, raw)
    values (p_message_id, p_valor, p_moeda, p_cru)
    on conflict (kofi_message_id) do nothing
    returning id into v_pagamento;

    if v_pagamento is null then
        return 'duplicado';
    end if;

    -- O codigo, reconfirmado aqui dentro. `usado_em is null` na condicao
    -- e o que impede dois pagamentos de gastarem o mesmo.
    if p_codigo is not null then
        update public.codigos
           set usado_em = now()
         where codigo = p_codigo
           and usado_em is null;
        if not found then
            -- Alguem chegou primeiro. Isto deixa de ser um casamento por
            -- codigo e passa a ser um caso para a fila.
            v_user_id := null;
            v_ato_slug := null;
            v_por := null;
        end if;
    end if;

    if v_user_id is not null and v_ato_slug is not null then
        update public.pagamentos
           set user_id = v_user_id, matched_by = v_por
         where id = v_pagamento;

        insert into public.creditos (user_id, ato_slug, source_payment_id)
        values (v_user_id, v_ato_slug, v_pagamento);

        return 'creditado';
    end if;

    -- Meia resposta ou nenhuma: fila manual. O que se souber fica
    -- escrito no pagamento, para quem a resolver nao comecar do zero.
    update public.pagamentos
       set user_id = v_user_id, matched_by = v_por
     where id = v_pagamento;

    insert into public.reconciliacao (kofi_message_id, raw)
    values (p_message_id, p_cru);

    return 'fila';
end;
$$;

-- So a chave de admin chama isto. O cliente nao credita a si proprio.
revoke execute on function public.assentar_pagamento from anon, authenticated;
