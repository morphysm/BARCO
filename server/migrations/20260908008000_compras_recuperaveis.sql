-- Checkout web: a identidade tem de poder voltar a entrar por email.
create function public.pedir_codigo_recuperavel(p_itens jsonb)
returns text language plpgsql security definer set search_path = public
as $$
begin
  if not exists (select 1 from auth.users where id = auth.uid()
      and email_confirmed_at is not null and coalesce(is_anonymous, true) = false) then
    raise exception 'confirma o email antes de comprar';
  end if;
  return public.pedir_codigo(p_itens);
end;
$$;
revoke all on function public.pedir_codigo_recuperavel(jsonb) from public, anon, authenticated;
grant execute on function public.pedir_codigo_recuperavel(jsonb) to authenticated;

-- A sala actual e uma irmandade. Cada deposito fica ligado a um credito.
create table public.depositos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  operacao uuid not null,
  credito_id uuid not null unique references public.creditos(id) on delete cascade,
  irmandade_slug text not null default 'calunga_pequena',
  oferenda_slug text not null references public.atos(slug),
  position_x double precision not null,
  position_y double precision not null,
  created_at timestamptz not null default now(),
  unique(user_id, operacao),
  check(position_x between -0.62 and 0.62 and position_y between -0.62 and 0.62
        and position_x * position_x + position_y * position_y <= 0.384401)
);
alter table public.depositos enable row level security;
create policy "depositos do dono" on public.depositos for select to authenticated
  using(user_id = auth.uid());
grant select on public.depositos to authenticated;

create function public.depor_oferenda(p_operacao uuid, p_ato_slug text,
  p_x double precision, p_y double precision)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  u uuid := auth.uid();
  c uuid;
  d public.depositos;
begin
  if u is null or p_operacao is null then raise exception 'sem sessao ou operacao'; end if;
  -- Serializa reenvios da mesma operacao; nunca cobra outro credito no retry.
  perform pg_advisory_xact_lock(hashtextextended(u::text || p_operacao::text, 0));
  select * into d from public.depositos where user_id = u and operacao = p_operacao;
  if found then
    if d.oferenda_slug is distinct from p_ato_slug
       or d.position_x is distinct from p_x or d.position_y is distinct from p_y then
      raise exception 'operacao reutilizada com outro gesto';
    end if;
    return to_jsonb(d);
  end if;
  select id into c from public.creditos
   where user_id = u and ato_slug = p_ato_slug and spent_at is null
   order by created_at, id limit 1 for update skip locked;
  if c is null then raise exception 'sem credito'; end if;
  insert into public.depositos(user_id, operacao, credito_id, oferenda_slug, position_x, position_y)
    values(u, p_operacao, c, p_ato_slug, p_x, p_y) returning * into d;
  update public.creditos set spent_at = now() where id = c;
  return to_jsonb(d);
end;
$$;
revoke all on function public.depor_oferenda(uuid,text,double precision,double precision)
  from public, anon, authenticated;
grant execute on function public.depor_oferenda(uuid,text,double precision,double precision) to authenticated;
