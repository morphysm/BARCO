-- Só para a prova. O Supabase traz tudo isto de fábrica; um Postgres nu não.
create role anon nologin;
create role authenticated nologin;
create role service_role nologin;
create schema if not exists auth;
create table auth.users (id uuid primary key, email text);
-- Como o do Supabase: le o `sub` das claims da sessao. Devolvia sempre
-- nulo, e com isso qualquer prova de politica passava por engano.
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claims', true)::jsonb->>'sub', '')::uuid
$$;

-- O que faltava aqui e o que deixou passar a falha do `pedir_codigo` e
-- do `gastar_credito`: o Supabase da EXECUTE aos papeis publicos em
-- cada funcao nova de `public`, nominalmente. Sem isto, o arnes criava
-- as funcoes fechadas por si e a prova dizia que estava tudo bem.
alter default privileges in schema public
    grant execute on functions to anon, authenticated, service_role;
