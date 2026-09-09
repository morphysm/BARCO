begin;
do $$
declare
  u uuid := '11111111-1111-1111-1111-111111111111';
  op uuid := gen_random_uuid();
  c text;
  d jsonb;
  n int;
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub', u)::text, true);
  begin
    perform public.pedir_codigo_recuperavel('[{"ato_slug":"pimenta","quantidade":2}]');
    raise exception 'TESTE: permitiu conta anonima';
  exception when raise_exception then
    if sqlerrm like 'TESTE:%' then raise; end if;
  end;
  update auth.users set email_confirmed_at = now(), is_anonymous = false where id = u;
  c := public.pedir_codigo_recuperavel('[{"ato_slug":"pimenta","quantidade":2}]');
  perform public.assentar_pagamento('deposito-teste', 4, 'USD', '{}', u, null, 'codigo', c);
  select count(*) into n from public.creditos where user_id = u and spent_at is null;
  d := public.depor_oferenda(op, 'pimenta', 0.1, 0.2);
  if d->>'id' is null then raise exception 'sem deposito'; end if;
  if public.depor_oferenda(op, 'pimenta', 0.1, 0.2) <> d then
    raise exception 'retry criou outro deposito';
  end if;
  if (select count(*) from public.creditos where user_id = u and spent_at is null) <> n - 1 then
    raise exception 'retry gastou outro credito';
  end if;
  begin
    perform public.depor_oferenda(gen_random_uuid(), 'pimenta', 10, 10);
    raise exception 'TESTE: aceitou fora do chao';
  exception when check_violation then null;
  end;
  if (select count(*) from public.creditos where user_id = u and spent_at is null) <> n - 1 then
    raise exception 'gesto recusado gastou credito';
  end if;
  if has_function_privilege('anon', 'public.depor_oferenda(uuid,text,double precision,double precision)', 'execute') then
    raise exception 'anon pode depor';
  end if;
end $$;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"22222222-2222-2222-2222-222222222222"}', true);
do $$ begin
  if exists(select 1 from public.depositos) then raise exception 'RLS expos depositos'; end if;
end $$;
rollback;
