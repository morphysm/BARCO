-- O email do pagador -> a pessoa. Degrau do meio da cascata (§10.4).
--
-- O email vive em `auth.users`, que nao esta exposto pela API. Nao se
-- expoe: abre-se uma porta estreita, que responde a uma pergunta so.
--
-- E `security definer` para poder ler `auth.users`, e e retirada a anon e
-- a authenticated de proposito — quem a pudesse chamar descobria, um
-- email de cada vez, quem e que tem conta neste app. Num app de ritual
-- isso nao e um detalhe de privacidade, e o proprio segredo da pessoa.
--
-- Sozinha nunca credita: diz QUEM, nao diz O QUE (ver `cascata.ts`).
create function public.pessoa_por_email(p_email text)
returns uuid
language sql
security definer
set search_path = auth, public
stable
as $$
    select id
      from auth.users
     where lower(email) = lower(trim(p_email))
     limit 1;
$$;

revoke execute on function public.pessoa_por_email(text) from anon, authenticated;
