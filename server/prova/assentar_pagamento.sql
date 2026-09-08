\set QUIET on
\set ON_ERROR_STOP on
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'quem@paga.pt');
insert into public.codigos (codigo, user_id, cafes_total) values
  ('BAR-7X2K', '11111111-1111-1111-1111-111111111111', 7);
insert into public.codigo_itens (codigo, ato_slug, quantidade) values
  ('BAR-7X2K', 'sacrificio', 1);
-- Um cesto a serio: tres pimentas e um marafo, 4 cafes = 8 USD.
insert into public.codigos (codigo, user_id, cafes_total) values
  ('BAR-CEST', '11111111-1111-1111-1111-111111111111', 4);
insert into public.codigo_itens (codigo, ato_slug, quantidade) values
  ('BAR-CEST', 'pimenta', 3), ('BAR-CEST', 'marafo', 1);
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
\echo '6. um CESTO: tres pimentas e um marafo, pagos 8 USD -> creditado'
select public.assentar_pagamento('msg-cesto', 8.00, 'USD', '{"c":1}'::jsonb,
  null, null, 'codigo', 'BAR-CEST') as resultado;
select ato_slug, count(*) as quantos from public.creditos
 where source_payment_id = (select id from public.pagamentos where kofi_message_id='msg-cesto')
 group by ato_slug order by ato_slug;

\echo ''
\echo '7. o MESMO pagamento nao credita duas vezes (creditado_em)'
do $$
declare v_pag uuid; r text;
begin
  -- Simula a vista da fila a chamar outra vez sobre o mesmo pagamento.
  update public.pagamentos set creditado_em = null
   where kofi_message_id = 'msg-cesto';
  select id into v_pag from public.pagamentos where kofi_message_id='msg-cesto';
  update public.pagamentos set creditado_em = now()
   where id = v_pag and creditado_em is null;
  if not found then raise exception 'FALHOU: a marca nao pegou'; end if;
  update public.pagamentos set creditado_em = now()
   where id = v_pag and creditado_em is null;
  if found then raise exception 'FALHOU: creditou-se duas vezes'; end if;
  raise notice 'ok: a segunda tentativa de creditar foi RECUSADA';
end $$;

\echo ''
\echo '7b. cesto pago A MENOS (4 USD para um cesto de 8) -> fila, zero creditos'
insert into public.codigos (codigo, user_id, cafes_total) values
  ('BAR-POUC', '11111111-1111-1111-1111-111111111111', 4);
insert into public.codigo_itens (codigo, ato_slug, quantidade) values
  ('BAR-POUC', 'pimenta', 3), ('BAR-POUC', 'marafo', 1);
select public.assentar_pagamento('msg-pouco', 4.00, 'USD', '{"p":1}'::jsonb,
  null, null, 'codigo', 'BAR-POUC') as resultado;
select count(*) as creditos_do_pouco from public.creditos
 where source_payment_id = (select id from public.pagamentos where kofi_message_id='msg-pouco');

\echo ''
\echo '7c. o cesto SELA-SE: `pedir_codigo` cria codigo, itens e total juntos'
-- Finge-se a sessao de uma pessoa autenticada. `false` e nao `true`:
-- `set_config` local exige uma transacao, e cada linha do psql e a sua.
select set_config('request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111"}', false);
do $$
declare v_cod text; v_tot int; v_itens int;
begin
  v_cod := public.pedir_codigo('[{"ato_slug":"pimenta","quantidade":3},
                                 {"ato_slug":"marafo","quantidade":1}]'::jsonb);
  select cafes_total into v_tot from public.codigos where codigo = v_cod;
  select count(*) into v_itens from public.codigo_itens where codigo = v_cod;
  if v_tot <> 4 then raise exception 'FALHOU: total selado errado (%)', v_tot; end if;
  if v_itens <> 2 then raise exception 'FALHOU: itens a mais ou a menos'; end if;
  raise notice 'ok: codigo % com total selado de % cafes e % itens', v_cod, v_tot, v_itens;
end $$;

\echo ''
\echo '7d. o cliente NAO escreve no cesto nem cria codigos a mao'
select
    has_table_privilege('authenticated', 'public.codigo_itens', 'INSERT') as insere_itens,
    has_table_privilege('authenticated', 'public.codigo_itens', 'UPDATE') as altera_itens,
    has_table_privilege('authenticated', 'public.codigo_itens', 'DELETE') as apaga_itens,
    (select count(*) from pg_policies
      where tablename = 'codigo_itens' and cmd <> 'SELECT') as politicas_de_escrita,
    (select count(*) from pg_policies
      where tablename = 'codigos' and cmd = 'INSERT') as pode_criar_codigo;

\echo ''
\echo '7e. e os creditos nao se convertem: nao ha politica que os mexa'
select cmd, count(*) from pg_policies
 where tablename = 'creditos' group by cmd order by cmd;

\echo ''
\echo '8. as funcoes NAO se chamam com a chave publica'
\echo '   (as duas do webhook fechadas a toda a gente; as duas do jogador'
\echo '    abertas SO a quem tem sessao — anon executar era a falha)'
select
    p.proname as funcao,
    has_function_privilege('anon', p.oid, 'execute')           as anon_pode,
    has_function_privilege('authenticated', p.oid, 'execute')  as autenticado_pode,
    has_function_privilege('service_role', p.oid, 'execute')   as admin_pode
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname in ('assentar_pagamento', 'pessoa_por_email',
                     'pedir_codigo', 'gastar_credito')
 order by p.proname;

-- Uma tabela de expectativas, funcao a funcao. Um `not anon and not
-- authenticated` para todas estaria errado: as duas do jogador tem de
-- responder a quem tem sessao, senao o cesto nao se pede.
do $$
declare
    r record;
    esperado record;
begin
    for esperado in
        select * from (values
            ('assentar_pagamento', false, false, true),
            ('pessoa_por_email',   false, false, true),
            ('pedir_codigo',       false, true,  true),
            ('gastar_credito',     false, true,  true)
        ) as t(nome, anon, autenticado, admin)
    loop
        select p.oid into r from pg_proc p
          join pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'public' and p.proname = esperado.nome;
        if not found then
            raise exception 'FALHOU: nao ha funcao %', esperado.nome;
        end if;
        if has_function_privilege('anon', r.oid, 'execute') <> esperado.anon then
            raise exception 'FALHOU: %, anon devia poder=% e pode=%',
                esperado.nome, esperado.anon,
                has_function_privilege('anon', r.oid, 'execute');
        end if;
        if has_function_privilege('authenticated', r.oid, 'execute')
                <> esperado.autenticado then
            raise exception 'FALHOU: %, authenticated devia poder=% e pode=%',
                esperado.nome, esperado.autenticado,
                has_function_privilege('authenticated', r.oid, 'execute');
        end if;
        if has_function_privilege('service_role', r.oid, 'execute') <> esperado.admin then
            raise exception 'FALHOU: %, service_role devia poder=%',
                esperado.nome, esperado.admin;
        end if;
    end loop;
    raise notice 'ok: as quatro funcoes com o privilegio que lhes cabe';
end $$;

\echo ''
\echo 'CONTAS FINAIS'
select
  (select count(*) from public.pagamentos)     as pagamentos,
  (select count(*) from public.creditos)       as creditos,
  (select count(*) from public.reconciliacao)  as na_fila;
