-- FALHA DE SEGURANCA. O `revoke ... from anon, authenticated` nao fechava
-- nada.
--
-- Em Postgres, o EXECUTE de uma funcao e concedido a PUBLIC por omissao,
-- e `anon` e `authenticated` herdam-no dai. Tirar-lhes a permissao
-- directamente nao lhes tira a que vem por PUBLIC — continua la, e as
-- duas funcoes ficaram chamaveis por quem tivesse a chave anonima. Essa
-- chave e publica por desenho: vai dentro do app.
--
-- Confirmado contra o projecto a serio, com uma chamada construida para
-- abortar antes de escrever: a `assentar_pagamento` devolveu 23502, ou
-- seja EXECUTOU e so parou na restricao de NOT NULL. Qualquer pessoa
-- podia ter-se creditado a si propria. A `pessoa_por_email` respondia
-- 200, ou seja dizia, um email de cada vez, quem tem conta neste app.
--
-- Nada foi escrito e nada foi explorado — as tabelas estavam vazias e a
-- descoberta foi na verificacao, nao em producao a andar.
--
-- O fecho e tirar a PUBLIC e dar so a quem precisa.

revoke execute on function public.assentar_pagamento(
    text, numeric, text, jsonb, uuid, text, text, text) from public;
revoke execute on function public.pessoa_por_email(text) from public;

-- O webhook corre com a chave de admin, que e o `service_role`.
grant execute on function public.assentar_pagamento(
    text, numeric, text, jsonb, uuid, text, text, text) to service_role;
grant execute on function public.pessoa_por_email(text) to service_role;

-- E para as proximas: uma funcao nova neste esquema deixa de nascer
-- aberta a toda a gente. Quem a quiser dar a alguem, da-a a mao.
alter default privileges in schema public revoke execute on functions from public;
