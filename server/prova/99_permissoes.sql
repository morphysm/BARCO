-- Os privilegios que o Supabase da de fabrica, aplicados DEPOIS das
-- migracoes.
--
-- Tem de ser depois: `alter default privileges` so alcanca tabelas
-- criadas a seguir, e a ordem no arnes nao garante isso. Sem estes
-- grants, uma recusa numa prova de RLS vinha do privilegio em falta e
-- nao da politica — e uma prova assim diz que esta tudo bem sem a
-- politica ter sido sequer consultada.
grant usage on schema public to anon, authenticated, service_role;
grant all on all tables in schema public to anon, authenticated, service_role;
grant all on all sequences in schema public to anon, authenticated, service_role;

-- E o `auth.uid()` tem de ser chamavel por quem esta autenticado: no
-- Supabase e, e sem isto a prova rebentava com "permission denied for
-- schema auth" em vez de dizer o que a politica faz.
grant usage on schema auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
