-- FALHA DE SEGURANCA, a irma da que o `fechar_as_funcoes` apanhou.
--
-- Ali, o `revoke ... from anon, authenticated` nao chegava porque o
-- EXECUTE vinha tambem de PUBLIC. Aqui e ao contrario: o `revoke ...
-- from public` nao chega porque o Supabase, de fabrica, tem
--
--     alter default privileges for role postgres in schema public
--         grant all on functions to anon, authenticated, service_role;
--
-- Ou seja: cada funcao nova em `public` nasce com o EXECUTE dado
-- NOMINALMENTE a `anon`. Tirar o de PUBLIC deixa esse de pe.
--
-- Foi visto contra producao com a chave anonima a serio, sem sessao:
--
--     assentar_pagamento  ->  42501   (recusada, tem `from anon, authenticated`)
--     pessoa_por_email    ->  42501   (idem)
--     pedir_codigo        ->  P0001   (EXECUTOU: o erro veio de dentro dela)
--     gastar_credito      ->  200 false (EXECUTOU: false so porque auth.uid() e nulo)
--
-- Um P0001 nao e uma recusa. E a funcao a correr.
--
-- O que se perdia com isto: `pedir_codigo` sem sessao nao emite codigo
-- nenhum, e `gastar_credito` sem sessao nao gasta credito nenhum — as
-- duas leem `auth.uid()` a primeira coisa. Nao houve dinheiro em risco.
-- O que havia era uma porta que devia estar fechada e nao estava, e a
-- garantia de que o cesto so se pede com identidade a assentar num
-- `if` la dentro em vez de assentar no privilegio.
--
-- Estas duas, ao contrario das outras, TEM de ficar abertas a
-- `authenticated`: e o proprio jogador que as chama.
revoke execute on function public.pedir_codigo(jsonb)   from public, anon;
revoke execute on function public.gastar_credito(text)  from public, anon;

grant execute on function public.pedir_codigo(jsonb)   to authenticated;
grant execute on function public.gastar_credito(text)  to authenticated;

-- E que a proxima funcao nao repita isto. O `fechar_as_funcoes` ja
-- tinha tirado a omissao a PUBLIC; falta tirar a nominal, que e a que
-- deixou passar estas duas.
alter default privileges in schema public
    revoke execute on functions from anon, authenticated;
