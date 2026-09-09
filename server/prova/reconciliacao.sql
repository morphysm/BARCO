-- A resolucao manual escolhe pessoa e actos, confere o total e e idempotente.
\set ON_ERROR_STOP on

begin;
do $$
declare
    v_admin uuid := '00000000-0000-0000-0000-0000000000c1';
    v_pessoa uuid := '00000000-0000-0000-0000-0000000000d1';
    v_fila uuid;
    v_resultado text;
    v_pagamento uuid;
begin
    insert into auth.users (id, email) values
        (v_admin, 'admin@exemplo.pt'),
        (v_pessoa, 'pessoa@exemplo.pt');
    insert into public.administradores (user_id) values (v_admin);

    perform public.assentar_pagamento(
        'manual-exacto', 6, 'USD', '{"type":"Donation"}',
        null, null, null, null);
    select id into v_fila from public.reconciliacao
     where kofi_message_id = 'manual-exacto';

    v_resultado := public.resolver_reconciliacao(
        v_fila, v_pessoa,
        '[{"ato_slug":"pimenta","quantidade":2},{"ato_slug":"marafo","quantidade":1}]',
        v_admin);
    if v_resultado <> 'creditado' then
        raise exception 'pagamento exacto nao foi creditado: %', v_resultado;
    end if;
    select id into v_pagamento from public.pagamentos
     where kofi_message_id = 'manual-exacto';
    if (select count(*) from public.creditos where source_payment_id = v_pagamento) <> 3 then
        raise exception 'a reconciliacao nao escreveu os tres creditos nomeados';
    end if;
    if not exists (
        select 1 from public.pagamentos
         where id = v_pagamento and user_id = v_pessoa
           and matched_by = 'manual' and creditado_em is not null
    ) then
        raise exception 'o pagamento nao ficou marcado como manual e creditado';
    end if;
    if not exists (
        select 1 from public.reconciliacao
         where id = v_fila and resolved_by = v_admin and resolved_at is not null
    ) then
        raise exception 'a fila nao ficou resolvida pelo administrador';
    end if;

    v_resultado := public.resolver_reconciliacao(
        v_fila, v_pessoa,
        '[{"ato_slug":"pimenta","quantidade":3}]', v_admin);
    if v_resultado <> 'duplicado' then
        raise exception 'o segundo clique nao foi tratado como duplicado';
    end if;
    if (select count(*) from public.creditos where source_payment_id = v_pagamento) <> 3 then
        raise exception 'o segundo clique creditou outra vez';
    end if;

    perform public.assentar_pagamento(
        'manual-valor-errado', 3, 'USD', '{}', null, null, null, null);
    select id into v_fila from public.reconciliacao
     where kofi_message_id = 'manual-valor-errado';
    begin
        perform public.resolver_reconciliacao(
            v_fila, v_pessoa, '[{"ato_slug":"pimenta","quantidade":1}]', v_admin);
        raise exception 'TESTE: creditou um valor que nao bate';
    exception when raise_exception then
        if sqlerrm like 'TESTE:%' then raise; end if;
    end;
    if exists (
        select 1 from public.reconciliacao where id = v_fila and resolved_at is not null
    ) then
        raise exception 'um valor errado saiu da fila';
    end if;

    begin
        perform public.resolver_reconciliacao(
            v_fila, v_pessoa, '[{"ato_slug":"pimenta","quantidade":1}]',
            '00000000-0000-0000-0000-0000000000ff');
        raise exception 'TESTE: uma pessoa nao autorizada reconciliou';
    exception when raise_exception then
        if sqlerrm like 'TESTE:%' then raise; end if;
    end;

    if has_function_privilege(
        'authenticated',
        'public.resolver_reconciliacao(uuid,uuid,jsonb,uuid)', 'execute') then
        raise exception 'authenticated chama a resolucao directamente';
    end if;
end $$;
rollback;
