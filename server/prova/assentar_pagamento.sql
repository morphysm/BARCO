\set QUIET on
\set ON_ERROR_STOP on
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'quem@paga.pt');
insert into public.codigos (codigo, user_id, ato_slug) values
  ('BAR-7X2K', '11111111-1111-1111-1111-111111111111', 'sacrificio');
\set QUIET off

\echo '1. pagamento com codigo -> creditado'
select public.assentar_pagamento('msg-1', 14, 'USD', '{"a":1}'::jsonb,
  '11111111-1111-1111-1111-111111111111', 'sacrificio', 'codigo', 'BAR-7X2K') as resultado;
select count(*) as creditos, min(ato_slug) as acto from public.creditos;
select usado_em is not null as codigo_gasto from public.codigos where codigo = 'BAR-7X2K';

\echo ''
\echo '2. O MESMO message_id outra vez (o Ko-fi reenvia) -> duplicado'
select public.assentar_pagamento('msg-1', 14, 'USD', '{"a":1}'::jsonb,
  '11111111-1111-1111-1111-111111111111', 'sacrificio', 'codigo', 'BAR-7X2K') as resultado;
select count(*) as creditos_depois_do_reenvio from public.creditos;

\echo ''
\echo '3. entrega nova com o codigo JA GASTO -> fila, sem creditar'
select public.assentar_pagamento('msg-2', 14, 'USD', '{"a":2}'::jsonb,
  '11111111-1111-1111-1111-111111111111', 'sacrificio', 'codigo', 'BAR-7X2K') as resultado;
select count(*) as creditos_totais from public.creditos;
select count(*) as na_fila from public.reconciliacao;

\echo ''
\echo '4. so email, sem acto -> fila, com a pessoa ja identificada'
select public.assentar_pagamento('msg-3', 2, 'USD', '{"a":3}'::jsonb,
  '11111111-1111-1111-1111-111111111111', null, 'email', null) as resultado;
select kofi_message_id, user_id is not null as sabe_quem, matched_by
  from public.pagamentos where kofi_message_id = 'msg-3';

\echo ''
\echo '5. nada de nada -> fila, sem pessoa'
select public.assentar_pagamento('msg-4', 2, 'USD', '{"a":4}'::jsonb,
  null, null, null, null) as resultado;

\echo ''
\echo '6. o MESMO pagamento nao pode dar dois creditos'
\echo '   (o caminho da fila manual ainda nao existe; a restricao ja)'
do $$
declare
    v_user uuid;
    v_ato  text;
    v_pag  uuid;
begin
    select user_id, ato_slug, source_payment_id
      into v_user, v_ato, v_pag
      from public.creditos limit 1;

    insert into public.creditos (user_id, ato_slug, source_payment_id)
    values (v_user, v_ato, v_pag);

    raise exception 'FALHOU: o segundo credito do mesmo pagamento passou';
exception
    when unique_violation then
        raise notice 'ok: segundo credito do mesmo pagamento RECUSADO';
end $$;

\echo ''
\echo '7. e a fila resolvida a mao tambem nao credita duas vezes'
-- Em DOIS blocos de proposito: uma excepcao dentro de um `do` desfaz o
-- bloco inteiro, e se os dois `insert` estivessem juntos o primeiro
-- tambem era desfeito — as contas finais diriam que a fila nunca
-- creditou, o que e mentira.
do $$
declare
    v_pag uuid;
begin
    -- O `msg-3` ficou na fila com a pessoa identificada e sem acto. Uma
    -- pessoa resolve-o a mao: credita.
    select id into v_pag from public.pagamentos where kofi_message_id = 'msg-3';
    insert into public.creditos (user_id, ato_slug, source_payment_id)
    values ('11111111-1111-1111-1111-111111111111', 'vela_20min', v_pag);
    raise notice 'ok: a fila creditou o msg-3 uma vez';
end $$;

do $$
declare
    v_pag uuid;
begin
    -- E carrega outra vez no botao.
    select id into v_pag from public.pagamentos where kofi_message_id = 'msg-3';
    insert into public.creditos (user_id, ato_slug, source_payment_id)
    values ('11111111-1111-1111-1111-111111111111', 'vela_20min', v_pag);
    raise exception 'FALHOU: a fila creditou o mesmo pagamento duas vezes';
exception
    when unique_violation then
        raise notice 'ok: o segundo carregar no botao foi RECUSADO';
end $$;

\echo ''
\echo 'CONTAS FINAIS'
select
  (select count(*) from public.pagamentos)     as pagamentos,
  (select count(*) from public.creditos)       as creditos,
  (select count(*) from public.reconciliacao)  as na_fila;
