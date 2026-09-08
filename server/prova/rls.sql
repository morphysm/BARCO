-- O RLS a serio, com papel e sessao.
--
-- POR QUE E QUE ISTO EXISTE. O `assentar_pagamento.sql` corre como
-- superutilizador, e o superutilizador passa por cima do RLS por
-- completo: nenhuma politica era consultada, e uma politica partida
-- passava despercebida. As unicas verificacoes de RLS que houve foram
-- feitas a mao contra producao, uma vez, e nao voltavam a correr.
--
-- Aqui assume-se o papel `authenticated` e finge-se o `sub` de uma
-- pessoa, como o Supabase faz. So assim as politicas sao mesmo lidas.
\set ON_ERROR_STOP on

\set UM   '11111111-1111-1111-1111-111111111111'
\set DOIS '22222222-2222-2222-2222-222222222222'

insert into auth.users (id, email) values
  (:'DOIS', 'outra@exemplo.pt') on conflict do nothing;

-- Duas pessoas, um codigo cada, e um credito da OUTRA.
insert into public.codigos (codigo, user_id, cafes_total) values
  ('BAR-DUM1', :'UM', 1), ('BAR-DOI2', :'DOIS', 1);
insert into public.codigo_itens (codigo, ato_slug, quantidade) values
  ('BAR-DUM1', 'pimenta', 1), ('BAR-DOI2', 'pimenta', 1);
insert into public.creditos (user_id, ato_slug, source_payment_id)
  select :'DOIS', 'pimenta', id from public.pagamentos limit 1;

select set_config('request.jwt.claims', '{"sub":"' || :'UM' || '"}', false);
set role authenticated;

\echo ''
\echo 'como a pessoa UM, autenticada — o que ve:'
select
  (select count(*) from public.atos)          as precos,
  (select count(*) from public.codigos)       as codigos,
  (select count(*) from public.codigos
    where user_id <> auth.uid())              as codigos_alheios,
  (select count(*) from public.creditos)      as creditos,
  (select count(*) from public.creditos
    where user_id <> auth.uid())              as creditos_alheios,
  (select count(*) from public.pagamentos)    as pagamentos,
  (select count(*) from public.reconciliacao) as fila;

do $$
declare n int; alheios int;
begin
  -- Conta-se a RELACAO e nao o total: as provas anteriores ja deixaram
  -- codigos e creditos desta mesma pessoa, e um numero fixo aqui passava
  -- a mentir na primeira vez que alguem acrescentasse um passo acima.
  select count(*) into n from public.atos;
  if n = 0 then raise exception 'FALHOU: os precos deviam ler-se'; end if;

  select count(*) into n from public.codigos;
  select count(*) into alheios from public.codigos where user_id <> auth.uid();
  if n = 0 then raise exception 'FALHOU: nao ve os proprios codigos'; end if;
  if alheios <> 0 then raise exception 'FALHOU: ve % codigos alheios', alheios; end if;

  select count(*) into alheios from public.codigo_itens ci
   where not exists (select 1 from public.codigos c
                      where c.codigo = ci.codigo and c.user_id = auth.uid());
  if alheios <> 0 then raise exception 'FALHOU: ve % cestos alheios', alheios; end if;

  select count(*) into alheios from public.creditos where user_id <> auth.uid();
  if alheios <> 0 then raise exception 'FALHOU: ve % creditos alheios', alheios; end if;

  -- O dinheiro cru nao se le, nem sendo o dono do pagamento: o `raw`
  -- traz o email do pagador e uma morada postal.
  select count(*) into n from public.pagamentos;
  if n <> 0 then raise exception 'FALHOU: ve % pagamentos', n; end if;
  select count(*) into n from public.reconciliacao;
  if n <> 0 then raise exception 'FALHOU: ve % linhas da fila', n; end if;

  raise notice 'ok: ve o que e seu, e nada do que e de outrem';
end $$;

\echo ''
\echo 'e o que NAO consegue escrever:'
--
-- Conta-se o EFEITO e nao a excepcao. Com RLS, uma escrita que nao
-- encontra linha visivel nao rebenta: afecta zero linhas, em silencio.
-- A primeira versao disto tratava "nao deu erro" como "passou" e acusou
-- cinco falhas que nao existiam.
do $$
declare
  o record;
  n int;
  falhou text := '';
begin
  for o in select * from (values
      ('criar um codigo a mao',
       $q$insert into public.codigos (codigo, user_id) values ('BAR-MAAU', auth.uid())$q$),
      ('mexer no proprio cesto',
       $q$insert into public.codigo_itens (codigo, ato_slug, quantidade) values ('BAR-DUM1', 'sangue', 1)$q$),
      ('apagar o cesto de outrem',
       $q$delete from public.codigo_itens where codigo = 'BAR-DOI2'$q$),
      ('dar-se um credito',
       $q$insert into public.creditos (user_id, ato_slug, source_payment_id) select auth.uid(), 'sangue', gen_random_uuid()$q$),
      ('converter um credito',
       $q$update public.creditos set ato_slug = 'sangue'$q$),
      ('desgastar um credito',
       $q$update public.creditos set spent_at = null$q$),
      ('escrever um pagamento',
       $q$insert into public.pagamentos (kofi_message_id, raw) values ('x', '{}'::jsonb)$q$),
      ('mudar um preco',
       $q$update public.atos set cafes = 999$q$)
  ) as t(nome, sql) loop
    begin
      execute o.sql;
      get diagnostics n = row_count;
      if n > 0 then
        falhou := falhou || ' / ' || o.nome;
        raise notice '  PASSOU (mal): % — % linhas', o.nome, n;
      else
        raise notice '  sem efeito: %', o.nome;
      end if;
    exception when others then
      raise notice '  recusado:   %', o.nome;
    end;
  end loop;
  if falhou <> '' then
    raise exception 'FALHOU, teve efeito o que nao devia:%', falhou;
  end if;
  raise notice 'ok: nao mexe em nada do que nao e dele';
end $$;

\echo ''
\echo 'e os precos ficaram como estavam:'
reset role;
select slug, cafes from public.atos where cafes = 999;
do $$
declare n int;
begin
  select count(*) into n from public.atos where cafes = 999;
  if n <> 0 then raise exception 'FALHOU: % precos foram mudados', n; end if;
  raise notice 'ok: nenhum preco foi mudado';
end $$;
