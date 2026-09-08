-- Só para a prova. O Supabase traz tudo isto de fábrica; um Postgres nu não.
create role anon nologin;
create role authenticated nologin;
create role service_role nologin;
create schema if not exists auth;
create table auth.users (id uuid primary key, email text);
create function auth.uid() returns uuid language sql stable as $$ select null::uuid $$;
