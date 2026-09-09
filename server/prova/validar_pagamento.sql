-- Falha com EXCEPTION se uma regressao puder consumir ou creditar mal.
begin;
do $$
declare
  u uuid := '11111111-1111-1111-1111-111111111111';
  c text;
  r text;
  v numeric;
  moeda text;
  i int := 0;
begin
  perform set_config('request.jwt.claims', jsonb_build_object('sub', u)::text, true);
  c := public.pedir_codigo('[{"ato_slug":"pimenta","quantidade":2}]');
  for v, moeda in select * from (values
      (2::numeric, 'USD'), (6::numeric, 'USD'), (4::numeric, 'EUR'),
      (null::numeric, 'USD'), (4::numeric, null::text)) t(a,b)
  loop
    i := i + 1;
    r := public.assentar_pagamento('regressao-' || i, v, moeda, '{}', null, null, 'codigo', c);
    if r <> 'fila' then raise exception 'valor invalido creditado'; end if;
    if (select usado_em is not null from public.codigos where codigo = c) then
      raise exception 'codigo consumido sem pagamento valido';
    end if;
    r := public.assentar_pagamento('regressao-sku-' || i, v, moeda, '{}', u, 'pimenta', 'sku', null);
    if r is distinct from (case when v = 2 and moeda = 'USD' then 'creditado' else 'fila' end) then
      raise exception 'validacao SKU errada';
    end if;
  end loop;
  r := public.assentar_pagamento('regressao-sku-zero', 0, 'USD', '{}', u, 'pimenta', 'sku', null);
  if r <> 'fila' then raise exception 'SKU gratuito'; end if;
  r := public.assentar_pagamento('regressao-valido', 4, 'USD', '{}', u, null, 'codigo', c);
  if r <> 'creditado' then raise exception 'cesto valido recusado'; end if;
  r := public.assentar_pagamento('regressao-valido', 4, 'USD', '{}', u, null, 'codigo', c);
  if r <> 'duplicado' then raise exception 'reenvio nao idempotente'; end if;
  if (select count(*) from public.creditos cr join public.pagamentos p
      on p.id = cr.source_payment_id where p.kofi_message_id = 'regressao-valido') <> 2 then
    raise exception 'quantidade errada';
  end if;
  if public.estado_codigo(c)->>'estado' <> 'creditado' then raise exception 'estado errado'; end if;
  perform set_config('request.jwt.claims', '{"sub":"22222222-2222-2222-2222-222222222222"}', true);
  if public.estado_codigo(c) is not null then raise exception 'estado exposto a outrem'; end if;
end $$;
rollback;
