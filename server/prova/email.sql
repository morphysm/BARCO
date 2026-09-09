-- O degrau do email da cascata (§10.4), provado ponta a ponta na SQL.
--
-- O `pessoa_por_email` sempre esteve escrito e sempre esteve certo. O que
-- nunca esteve la foi o EMAIL: a identidade e anonima, nunca se pediu
-- endereco a ninguem, e portanto `auth.users.email` estava nulo para toda
-- a gente e a funcao nunca encontrava nada. O degrau existia e estava
-- vazio.
--
-- Agora o balcao pede o email ao pedir o codigo, e liga-o a identidade
-- que ja existe (`Conta.ligar_email`, um PUT /auth/v1/user com o token de
-- quem ja esta dentro — upgrade, nao conta nova). Isto prova o que a SQL
-- faz com o resultado disso.
--
-- O QUE ISTO NAO PROVA, e importa: que o GoTrue escreve mesmo o email em
-- `auth.users.email`. Ele so o faz depois de a pessoa CONFIRMAR o
-- endereco; ate la o campo fica por preencher e a funcao — de propria
-- razao — nao encontra ninguem. Isso prova-se contra um Supabase a
-- serio, nao aqui.
\set ON_ERROR_STOP on

\set ANON  '00000000-0000-0000-0000-0000000000e1'
\set OUTRO '00000000-0000-0000-0000-0000000000e2'

\echo ''
\echo '== o degrau do email =='

-- Uma identidade anonima: existe, e nao tem email. Como todas tinham.
insert into auth.users (id, email) values (:'ANON', null)
  on conflict (id) do update set email = null;

\echo ''
\echo '-- antes de ligar o email (era isto para toda a gente):'
select public.pessoa_por_email('quem@exemplo.pt') as encontrou;

-- O que o `PUT /auth/v1/user` acaba por deixar na tabela, depois de
-- confirmado. A MESMA linha: o `id` nao muda, e e esse o ponto.
--
-- Em minusculas e sem espacos porque e assim que o GoTrue guarda. Nao e
-- indiferente: o `pessoa_por_email` faz `lower(trim(...))` ao ARGUMENTO e
-- compara com a COLUNA como ela esta. Ou seja, aguenta o que a pessoa
-- escreveu na caixa, e conta com a coluna ja normalizada por quem a
-- escreveu. Vale enquanto for o GoTrue a escrever ali — se algum dia
-- alguem meter emails em `auth.users` a mao, isto passa a importar.
update auth.users set email = 'quem@exemplo.pt' where id = :'ANON';

\echo ''
\echo '-- depois de ligar o email a MESMA identidade:'
select public.pessoa_por_email('quem@exemplo.pt') as encontrou;

\echo ''
\echo '-- e o id e o mesmo de antes (upgrade, nao conta nova):'
select public.pessoa_por_email('quem@exemplo.pt') = :'ANON'::uuid as mesma_pessoa;

\echo ''
\echo '-- e o que a pessoa escreveu na caixa, com maiusculas e espacos:'
select public.pessoa_por_email('  QUEM@EXEMPLO.PT  ') as encontrou;

\echo ''
\echo '-- um email que nao e de ninguem continua a nao ser de ninguem:'
select public.pessoa_por_email('ninguem@exemplo.pt') as encontrou;

do $$
declare
    v uuid;
begin
    select public.pessoa_por_email('quem@exemplo.pt') into v;
    if v is distinct from '00000000-0000-0000-0000-0000000000e1'::uuid then
        raise exception 'FALHOU: devia achar a identidade anonima, achou %', v;
    end if;
    select public.pessoa_por_email('ninguem@exemplo.pt') into v;
    if v is not null then
        raise exception 'FALHOU: inventou uma pessoa para um email sem dono: %', v;
    end if;
    raise notice 'ok: o email encontra a identidade, e so a dela';
end $$;
