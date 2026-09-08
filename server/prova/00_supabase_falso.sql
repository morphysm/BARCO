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
